# Spectra — Comprehensive LLM Context Document

_Last updated: 2026-03-18. Agents A-E deployed._

This document is written for LLMs reading the codebase cold. After reading this file you should understand the full architecture, every file, all 29 chart types, the API contract, the stats engine, how to add a new chart type, and how to run tests. This file is the authoritative reference; docs/PLAN.md contains architectural decisions and rationale.

---

## Section 1: Product Overview

**Spectra** is a GraphPad Prism-style scientific plotting desktop application for macOS. Target users are researchers and scientists who need publication-quality charts with real statistics, without writing code.

### How it runs

From the user's perspective: double-click `Spectra.app`, a native window opens. No terminal, no visible server, no browser tabs.

Under the hood:
- `plotter_webview.py` (the entry point) starts a FastAPI server on a background thread at `127.0.0.1:7331`, then opens a pywebview window (WKWebView on macOS)
- The pywebview window loads the React SPA served by FastAPI at `/`
- The React SPA calls FastAPI endpoints to render charts and load data
- All computation runs in Python; JavaScript only renders

### What it is NOT

- Not a web app. Web deployment is not a goal and must not influence architecture.
- Not a Tkinter app going forward. `plotter_barplot_app.py` is a 6,688-line spec document for the React UI — it is not maintained.

---

## Section 2: Architecture

### Full system diagram

```
User double-clicks Spectra.app
        │
        ▼
plotter_webview.py                     ← desktop entry point
  ├── starts FastAPI server             (background thread, 127.0.0.1:7331)
  │     plotter_server.py              ← FastAPI app factory
  │       ├── POST /render             → plotter_spec_*.py  → Plotly JSON
  │       ├── POST /render-png         → plotter_functions.py → base64 PNG
  │       ├── GET  /chart-types        → returns metadata for all 29 types
  │       ├── POST /event              → sync on-chart edits back to state
  │       └── GET  /health             → {"status": "ok"}
  └── opens pywebview window           (WKWebView, full-screen native)
        │
        ▼
React SPA  (plotter_web/src/)
  ├── sidebar:         29 chart types, 7 groups
  ├── chart area:      Plotly.js (interactive) or <img> (PNG fallback)
  ├── right panel:     Data | Axes | Style | Stats tabs
  ├── help panel:      slide-in wiki (plotter_wiki_content.py sections)
  └── results strip:   collapsible stats output
        │
        │  POST /render { chart_type, kw }    → Plotly JSON spec
        │  POST /render-png { chart_type, kw } → base64 PNG
        ▼
plotter_server.py  (FastAPI)
  ├── Plotly path:  plotter_spec_bar/grouped_bar/line/scatter.py
  └── PNG path:     plotter_functions.py  (29 matplotlib chart functions)
```

### Rendering pipeline — two paths

**Plotly path** (4 priority chart types: bar, grouped_bar, line, scatter):
```
React → POST /render { chart_type, kw }
  → plotter_server._build_spec(chart_type, kw)
  → plotter_spec_*.build_*_spec(kw)
  → reads Excel/CSV with pandas
  → builds plotly.graph_objects.Figure
  → returns JSON string
  → server wraps in { ok: true, spec: <parsed JSON> }
  → React renders with Plotly.js (interactive, editable: true)
```

**PNG fallback path** (remaining 25 chart types):
```
React → POST /render-png { chart_type, kw }
  → plotter_server routes to correct plotter_functions.py function
  → matplotlib renders fig
  → base64-encodes PNG
  → returns { ok: true, image: "data:image/png;base64,..." }
  → React renders in <img> tag
```

### Dependency graph

```
plotter_server.py
  ├── plotter_spec_bar.py
  │     └── plotter_plotly_theme.py
  ├── plotter_spec_grouped_bar.py
  │     └── plotter_plotly_theme.py
  ├── plotter_spec_line.py
  │     └── plotter_plotly_theme.py
  ├── plotter_spec_scatter.py
  │     └── plotter_plotly_theme.py
  └── plotter_functions.py       (matplotlib, lazy-loaded)
        └── plotter_validators.py (no external deps)

plotter_webview.py
  └── plotter_server.py

plotter_registry.py              (no prism deps — pure dataclasses)
plotter_validators.py            (no prism deps — pure pandas)
plotter_results.py               (receives app object; no other prism imports)
plotter_widgets.py               (no prism deps — pure Tk + constants)
```

---

## Section 3: Complete File Map

### Core computation

**`plotter_functions.py`** (~6,553 lines)
- Purpose: All 29 matplotlib chart functions plus the complete stats engine
- Key functions: `_ensure_imports()`, `_base_plot_setup()`, `_base_plot_finish()`, `_style_kwargs()`, `_apply_plotter_style()`, `_apply_stats_brackets()`, `_apply_grid()`, `_apply_legend()`, `_apply_log_formatting()`, `_set_categorical_xticks()`, `_draw_jitter_points()`, `_calc_error()`, `_calc_error_asymmetric()`, `_assign_colors()`, `_darken_color()`, `_run_stats()`, `_p_to_stars()`, `_apply_correction()`, `normality_warning()`
- Key constants: `PRISM_PALETTE`, `AXIS_STYLES`, `TICK_DIRS`, `LEGEND_POSITIONS`, `_DPI=144`, `_FONT="Arial"`, `_ALPHA_BAR=0.85`
- Dependencies: `numpy`, `pandas`, `matplotlib` (lazy), `seaborn` (lazy), `scipy.stats` (lazy)
- DO NOT import matplotlib at module level — it is lazy-loaded by `_ensure_imports()`
- DO NOT delete any chart functions — all 29 are tested

**`plotter_validators.py`** (~518 lines)
- Purpose: Standalone spreadsheet validation — each function takes a raw pandas DataFrame and returns `(errors: list[str], warnings: list[str])`
- Key functions: `validate_flat_header()`, `validate_line()`, `validate_grouped_bar()`, `validate_kaplan_meier()`, `validate_heatmap()`, `validate_two_way_anova()`, `validate_contingency()`, `validate_chi_square_gof()`, `validate_bland_altman()`, `validate_forest_plot()`, `validate_pyramid()`
- Dependencies: `pandas` (lazy via `_pd()`)
- Pure functions — no side effects, no Tk, no matplotlib

**`plotter_results.py`** (~401 lines)
- Purpose: Compute and display descriptive stats, test results, post-hoc comparisons, normality tables in the results panel
- Key functions: `populate_results(app, excel_path, sheet, plot_type, kw_snapshot)`, `export_results_csv(app)`, `copy_results_tsv(app)`
- Note: This module still renders Tk Treeview widgets for the legacy Tk app; in the React app this role is handled by the React results strip component receiving data from `/render`

**`plotter_registry.py`** (~475 lines)
- Purpose: Single source of truth for all 29 chart type configurations
- Key class: `PlotTypeConfig` — dataclass with fields: `key`, `label`, `fn_name`, `tab_mode`, `stats_tab`, `validate`, `extra_collect`, `has_points`, `has_error_bars`, `has_legend`, `has_stats`, `x_continuous`, `axes_has_bar_width`, `axes_has_line_opts`
- Key collections: `_REGISTRY_SPECS` (list of 29 `PlotTypeConfig`), `KEYBOARD_SHORTCUTS`, `ERROR_TYPE_MAP`, `STATS_TEST_MAP`, `MARKER_STYLE_MAP`
- Key method: `PlotTypeConfig.filter_kwargs(kw, fn)` — introspects function signature to strip unsupported kwargs (replaces manual `strip_keys`/`keep_keys`)
- To add a new chart type: append a `PlotTypeConfig` entry here. No other file needs to change (except the function file, validator, and tests).

### FastAPI server and Plotly spec builders

**`plotter_server.py`**
- Purpose: FastAPI app factory; all HTTP endpoints
- Key endpoints: `POST /render`, `POST /render-png`, `POST /event`, `GET /health`, `GET /chart-types`
- Key functions: `start_server(app_instance=None)`, `get_port()`, `_build_spec(chart_type, kw)`, `_dispatch_event(event, value, extra)`
- Auth: `PLOTTER_API_KEY` env var required for non-local requests; local (`127.0.0.1`/`localhost`) bypasses auth
- DO NOT touch while Agent B is working

**`plotter_webview.py`**
- Purpose: Desktop entry point — starts FastAPI server thread, opens pywebview window
- Key class: `PlotterWebView` — wraps a pywebview window; methods `show()`, `render(chart_type, kw)`, `destroy()`
- The HTML template embedded in this file loads Plotly.js from CDN and defines `window.plotterRender(chartType, kw)`
- DO NOT touch while other agents are working

**`plotter_spec_bar.py`**
- Purpose: Build Plotly JSON spec for bar charts
- Key function: `build_bar_spec(kw: dict) -> str` — reads Excel, computes means + SEM, returns `fig.to_json()`
- Dependencies: `plotly.graph_objects` (lazy import inside function), `pandas`, `plotter_plotly_theme`

**`plotter_spec_grouped_bar.py`**
- Purpose: Build Plotly JSON spec for grouped bar charts (two-row header Excel layout)
- Key function: `build_grouped_bar_spec(kw: dict) -> str`

**`plotter_spec_line.py`**
- Purpose: Build Plotly JSON spec for line graphs
- Key function: `build_line_spec(kw: dict) -> str` — reads first column as X, remaining columns as series

**`plotter_spec_scatter.py`**
- Purpose: Build Plotly JSON spec for scatter plots (same layout as line, mode="markers")
- Key function: `build_scatter_spec(kw: dict) -> str`

**`plotter_plotly_theme.py`**
- Purpose: Shared Plotly theme matching matplotlib Prism style
- Key exports: `PRISM_PALETTE` (10 hex colors), `PRISM_TEMPLATE` (full layout dict), `apply_open_spine(layout_update)`
- White background, Arial font, open spines (left+bottom only), outside ticks

### Legacy Tk app (spec reference only)

**`plotter_barplot_app.py`** (~6,688 lines)
- Purpose: The original Tkinter app — now a living spec for the React UI
- DO NOT maintain going forward; the React UI replaces it
- Key methods to read when building React UI: `_tab_data()`, `_tab_axes()`, `_tab_stats()`, `_collect()` (defines the full `kw` dict = API contract), `_build_sidebar()` (29 chart types + groupings)
- All `_tab_stats_*` variants define chart-specific stats controls

**`plotter_widgets.py`** (~952 lines)
- Purpose: Tk design tokens and widget classes — reference for React style constants
- Key class: `_DS` — color/font constants (`_DS.PRIMARY = "#2274A5"`, etc.)
- Key widgets: `PButton`, `PEntry`, `PCheckbox`, `PCombobox`
- Also contains: `LABELS`, `HINTS` dicts (human-readable names + tooltips for every field)

### Phase 2 infrastructure (mostly superseded by React state)

**`plotter_tabs.py`** (~532 lines) — `TabState`, `TabManager`, `TabBar` for multi-tab support; not yet wired into React

**`plotter_session.py`** (~77 lines) — Session persistence: auto-save/restore last-used settings as JSON

**`plotter_events.py`** (~75 lines) — `EventBus` for decoupled pub/sub messaging; optional, not widely used

**`plotter_types.py`** (~121 lines) — Shared dataclasses and type definitions

**`plotter_undo.py`** (~131 lines) — `UndoStack` for undo/redo support

**`plotter_errors.py`** (~99 lines) — `ErrorReporter` for structured, user-friendly error messages

**`plotter_comparisons.py`** (~248 lines) — Custom comparison builder: UI for selecting specific group pairs for stats tests

**`plotter_presets.py`** (~163 lines) — Style preset system: load/save named presets as `.json`

**`plotter_app_wiki.py`** (~522 lines) — Tk wiki popup viewer (retired; React help panel replaces this)

**`plotter_app_icons.py`** (~352 lines) — SVG icon definitions for all 29 chart types; reference for React sidebar icons

### Data and content

**`plotter_wiki_content.py`** (~2,224 lines)
- Purpose: Statistical reference wiki — 29 sections covering all supported tests with formulas, assumptions, and citations
- Key export: `WIKI_SECTIONS` — list of dicts with `title`, `tags`, `subsections`
- The React help panel renders these sections as formatted HTML

**`plotter_import_pzfx.py`** (~316 lines)
- Purpose: Import GraphPad Prism `.pzfx` (XML) files
- Key classes: `PzfxTable`, `PzfxImportResult`
- Extracts data tables, group names, titles; writes to a temp `.xlsx` file
- Uses only stdlib (`xml.etree.ElementTree`) + `openpyxl`

**`plotter_project.py`** (~207 lines)
- Purpose: Save/load `.cplot` project files (ZIP archives)
- ZIP contents: `manifest.json`, `state.json`, `plot_type.json`, `comparisons.json`, `data/` (CSV sheets), `thumbnail.png` (optional)
- Key functions: `save_project(path, app_vars, plot_type, excel_path, ...)`, `load_project(path)`

### Test infrastructure

**`run_all.py`** (~112 lines) — Unified test runner; runs all suites in one Python process sharing the loaded `plotter_functions` module

**`tests/plotter_test_harness.py`** (~363 lines) — Shared bootstrap: imports once, provides fixtures `bar_excel`, `line_excel`, `grouped_excel`, `km_excel`, `heatmap_excel`, `two_way_excel`, `contingency_excel`, `with_excel`

---

## Section 4: All 29 Chart Types

| Key | UI Label | Group | Function | Has Plotly Spec | Excel Layout |
|---|---|---|---|---|---|
| `bar` | Bar Chart | Column | `plotter_barplot` | Yes | Row 0: group names; rows 1+: numeric values |
| `box` | Box Plot | Column | `plotter_boxplot` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `violin` | Violin Plot | Column | `plotter_violin` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `dot_plot` | Dot Plot | Column | `plotter_dot_plot` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `subcolumn_scatter` | Subcolumn | Column | `plotter_subcolumn_scatter` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `before_after` | Before / After | Column | `plotter_before_after` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `repeated_measures` | Repeated Meas. | Column | `plotter_repeated_measures` | No (PNG) | Row 0: timepoint names; rows 1+: numeric values |
| `scatter` | Scatter Plot | XY | `plotter_scatterplot` | Yes | Row 0: X-label + series names; rows 1+: X value, Y replicates |
| `line` | Line Graph | XY | `plotter_linegraph` | Yes | Row 0: X-label + series names; rows 1+: X value, Y replicates |
| `curve_fit` | Curve Fit | XY | `plotter_curve_fit` | No (PNG) | Row 0: X-label + series names; rows 1+: X value, Y replicates |
| `area_chart` | Area Chart | XY | `plotter_area_chart` | No (PNG) | Row 0: X-label + series names; rows 1+: X value, Y replicates |
| `bubble` | Bubble Chart | XY | `plotter_bubble` | No (PNG) | Row 0: X, Y, Size, (Label); rows 1+: values |
| `bland_altman` | Bland-Altman | XY | `plotter_bland_altman` | No (PNG) | Row 0: Method A name, Method B name; rows 1+: paired measurements |
| `grouped_bar` | Grouped Bar | Grouped | `plotter_grouped_barplot` | Yes | Row 0: category names; row 1: subgroup names; rows 2+: numeric values |
| `stacked_bar` | Stacked Bar | Grouped | `plotter_stacked_bar` | No (PNG) | Row 0: category names; row 1: subgroup names; rows 2+: numeric values |
| `two_way_anova` | Two-Way ANOVA | Grouped | `plotter_two_way_anova` | No (PNG) | Headers: `Factor_A`, `Factor_B`, `Value`; one row per observation |
| `histogram` | Histogram | Distribution | `plotter_histogram` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `ecdf` | ECDF | Distribution | `plotter_ecdf` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `qq_plot` | Q-Q Plot | Distribution | `plotter_qq_plot` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `column_stats` | Col Statistics | Distribution | `plotter_column_stats` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `kaplan_meier` | Survival Curve | Survival | `plotter_kaplan_meier` | No (PNG) | Row 0: group names (each spanning 2 cols); row 1: "Time", "Event"; rows 2+: time value, 0/1 |
| `heatmap` | Heatmap | Correlation | `plotter_heatmap` | No (PNG) | Row 0: blank + column labels; rows 1+: row label + numeric values |
| `forest_plot` | Forest Plot | Correlation | `plotter_forest_plot` | No (PNG) | Headers: `Study`, `Effect`, `Lower CI`, `Upper CI`; one row per study |
| `contingency` | Contingency | Correlation | `plotter_contingency` | No (PNG) | Row 0: blank + outcome labels; rows 1+: group name + counts |
| `chi_square_gof` | Chi-Sq GoF | Correlation | `plotter_chi_square_gof` | No (PNG) | Row 0: category names; row 1: observed counts; row 2 (optional): expected counts |
| `waterfall` | Waterfall | Other | `plotter_waterfall` | No (PNG) | Row 0: category names; rows 1+: numeric values |
| `lollipop` | Lollipop | Other | `plotter_lollipop` | No (PNG) | Row 0: group names; rows 1+: numeric values |
| `pyramid` | Pyramid | Other | `plotter_pyramid` | No (PNG) | Row 0: `Category`, left series name, right series name; rows 1+: values |
| `raincloud` | Raincloud | Other | `plotter_raincloud` | No (PNG) | Row 0: group names; rows 1+: numeric values |

---

## Section 5: API Reference

All endpoints are served by `plotter_server.py` on `127.0.0.1:7331`.

### GET /health

Returns `{"status": "ok"}`. Used to check if the server is running.

### GET /chart-types

Returns metadata for all 29 chart types.

Response:
```json
{
  "ok": true,
  "chart_types": [
    {
      "key": "bar",
      "label": "Bar Chart",
      "group": "Column",
      "tab_mode": "bar",
      "has_plotly_spec": true
    }
  ]
}
```

### POST /render

Accepts chart kwargs, returns a Plotly figure spec. Only works for the 4 priority types (bar, grouped_bar, line, scatter).

Request body:
```json
{
  "chart_type": "bar",
  "kw": {
    "excel_path": "/path/to/data.xlsx",
    "sheet": 0,
    "title": "My Chart",
    "xlabel": "Groups",
    "ytitle": "Mean ± SEM",
    "color": null
  }
}
```

Response (success):
```json
{
  "ok": true,
  "spec": {
    "data": [...],
    "layout": {...}
  }
}
```

Response (error):
```json
{
  "ok": false,
  "error": "Unknown chart type: foo"
}
```

### POST /render-png

Calls `plotter_functions.py` to render any of the 25 non-Plotly chart types via matplotlib, returns base64 PNG.

Request body:
```json
{
  "chart_type": "violin",
  "kw": {
    "excel_path": "/path/to/data.xlsx",
    "title": "My Violin"
  }
}
```

Response (success):
```json
{
  "ok": true,
  "image": "data:image/png;base64,iVBORw0KGgo..."
}
```

### POST /event

Receives edit events from the React frontend (on-chart title/axis edits via Plotly's `plotly_relayout`). Dispatches back to app state for bidirectional sync.

Request body:
```json
{
  "event": "title_changed",
  "value": "New Title",
  "extra": {}
}
```

Supported event types: `title_changed`, `xlabel_changed`, `ytitle_changed`, `bar_recolored`, `yrange_changed`

Response: `{"ok": true}`

---

## Section 6: Excel / CSV Layout Conventions

All chart functions read data from Excel (`.xlsx`) or CSV. The `kw` dict always includes `excel_path` and `sheet` (sheet index or name).

### Flat header layout (most column-type charts)

Used by: bar, box, violin, dot_plot, subcolumn_scatter, before_after, repeated_measures, histogram, ecdf, qq_plot, lollipop, waterfall, raincloud, area_chart

```
Row 0:   Control    Drug A    Drug B      <- group names (strings)
Row 1:   1.2        2.5       3.1         <- first replicate
Row 2:   1.5        2.8       3.4
Row 3:   1.1        2.2       2.9
```

Validator: `validate_flat_header()`. Minimum 2 columns, minimum 3 rows (including header).

### XY layout (line, scatter, curve_fit, area_chart with numeric X)

```
Row 0:   X          Series1   Series2     <- X-axis label + series names
Row 1:   0.0        1.2       2.3         <- first data point
Row 2:   0.5        1.5       2.6
Row 3:   1.0        1.8       2.9
```

Validator: `validate_line()`.

### Grouped two-row header (grouped_bar, stacked_bar)

```
Row 0:   Control             Drug A                 <- category names
Row 1:   Male    Female      Male    Female          <- subgroup names
Row 2:   1.2     2.3         3.4     4.5
Row 3:   1.5     2.6         3.7     4.8
```

Read with `pd.read_excel(..., header=[0, 1])` to get a MultiIndex column. Validator: `validate_grouped_bar()`.

### Kaplan-Meier survival

```
Row 0:   Group A             Group B                <- group name (spans 2 cols each)
Row 1:   Time    Event       Time    Event           <- "Time" and "Event" headers
Row 2:   5       1           8       1
Row 3:   12      0           15      0
Row 4:   24      1           22      1
```

Event column: 1 = event occurred, 0 = censored. Validator: `validate_kaplan_meier()`.

### Heatmap

```
Row 0:   (blank)  ColA   ColB   ColC    <- blank first cell, then column labels
Row 1:   RowA     1.2    2.3    3.4     <- row label + numeric values
Row 2:   RowB     4.5    5.6    6.7
```

Validator: `validate_heatmap()`.

### Two-Way ANOVA (long format)

```
Row 0:   Factor_A    Factor_B    Value   <- exact header names required
Row 1:   Control     Male        1.2
Row 2:   Control     Female      2.3
Row 3:   Drug        Male        3.4
Row 4:   Drug        Female      4.5
```

Validator: `validate_two_way_anova()`.

### Contingency table

```
Row 0:   (blank)    Outcome1   Outcome2  <- blank first cell, then outcome labels
Row 1:   Group A    12         8
Row 2:   Group B    5          15
```

Validator: `validate_contingency()`.

### Chi-square goodness of fit

```
Row 0:   Cat1    Cat2    Cat3    <- category names
Row 1:   25      30      45      <- observed counts
Row 2:   33      33      34      <- expected counts (optional; defaults to equal)
```

Validator: `validate_chi_square_gof()`.

### Forest plot

```
Row 0:   Study    Effect    Lower CI    Upper CI    <- exact header names
Row 1:   Study A  0.85      0.70        1.02
Row 2:   Study B  1.12      0.95        1.32
```

Validator: `validate_forest_plot()`.

### Bland-Altman

```
Row 0:   Method A    Method B    <- method names
Row 1:   120         118
Row 2:   132         130
Row 3:   125         127
```

Validator: `validate_bland_altman()`.

### Pyramid chart

```
Row 0:   Age Group   Males   Females   <- first col = category label header
Row 1:   0-4         250     235
Row 2:   5-14        480     460
```

Validator: `validate_pyramid()`.

---

## Section 7: Stats Engine

All stats computation is in `plotter_functions.py`.

### _run_stats(groups, test_type, n_permutations, control, mc_correction, posthoc, mu0)

Main entry point for significance testing. Returns a list of `(group_a, group_b, p_value, stars)` tuples.

**test_type values:**
- `"parametric"` — 2 groups: Welch's t-test; 3+ groups: one-way ANOVA + posthoc
- `"nonparametric"` — 2 groups: Mann-Whitney U; 3+ groups: Kruskal-Wallis + Dunn's posthoc
- `"paired"` — 2 groups: paired t-test; 3+ groups: pairwise paired t-tests
- `"permutation"` — permutation test (n_permutations default 9999)
- `"one_sample"` — compares each group mean to mu0 via one-sample t-test

**posthoc values (parametric, 3+ groups):**
- `"Tukey HSD"` — Tukey's honest significant difference (default)
- `"Dunnett (vs control)"` — compare each treatment to one control; uses `scipy.stats.dunnett`
- `"Bonferroni"` — Welch pairwise with Bonferroni correction
- `"Sidak"` — Welch pairwise with Sidak correction
- `"Fisher LSD"` — Welch pairwise uncorrected

**mc_correction values:**
- `"Holm-Bonferroni"` — default; step-down method
- `"Bonferroni"` — multiply all p-values by number of tests
- `"Benjamini-Hochberg (FDR)"` — FDR control
- `"None (uncorrected)"` — raw p-values

### _calc_error(vals, error_type)

Returns `(mean, half_width)` for error bars.
- `"sem"` — standard error of the mean
- `"sd"` — standard deviation
- `"ci95"` — 95% confidence interval (t-distribution)

### _calc_error_asymmetric(vals, error_type)

Returns `(mean, err_down, err_up)` for log-scale plots. Computes error in log space and maps back to avoid negative lower bars on log axes.

### _p_to_stars(p, threshold=None)

Converts p-value to Prism-style annotation string:
- `p > threshold` → `"ns"` (hidden unless `__show_ns__=True`)
- `p <= 0.0001` → `"****"`
- `p <= 0.001` → `"***"`
- `p <= 0.01` → `"**"`
- `p <= threshold` → `"*"`

Uses module-level `__p_sig_threshold__` (default 0.05). App can override this before each plot run.

### _apply_correction(raw_p_list, method)

Applies multiple comparison correction to a list of raw p-values. Returns corrected p-values in the same order. Implements Bonferroni, Holm-Bonferroni, Benjamini-Hochberg FDR.

### normality_warning(groups, stats_test)

Returns a warning string if any group fails the Shapiro-Wilk normality test (p < 0.05) and a parametric test is selected. Returns empty string if no warning needed.

### kwargs that control statistics

Every chart function accepts these kwargs (extracted from the `kw` dict by `PlotTypeConfig.filter_kwargs`):
- `stats_test: str` — test type ("parametric", "nonparametric", "paired", "permutation", "one_sample")
- `posthoc: str` — post-hoc method name
- `mc_correction: str` — multiple comparison correction method
- `n_permutations: int` — permutations for permutation test
- `control: str | None` — control group name (for Dunnett and pairwise-vs-control)
- `show_ns: bool` — show "ns" brackets
- `show_brackets: bool` — show significance brackets at all
- `p_threshold: float` — significance cutoff (default 0.05)
- `error: str` — error bar type ("sem", "sd", "ci95")

---

## Section 8: Adding a New Chart Type — 5-Step Checklist

### Step 1 — Write the matplotlib function in `plotter_functions.py`

Insert before the `# P20 — Export all chart types` block. Every function must follow this template:

```python
def plotter_my_chart(
    excel_path: str,
    sheet=0,
    color=None,
    title: str = "",
    xlabel: str = "",
    ytitle: str = "",
    yscale: str = "linear",
    ylim=None,
    figsize=(5, 5),
    font_size: float = 12.0,
    # ... chart-specific params ...
    ref_line=None,
    ref_line_label: str = "",
    # -- shared style params (copy verbatim) ---------------------------------
    axis_style: str = "open",
    tick_dir: str = "out",
    minor_ticks: bool = False,
    point_size: float = 6.0,
    point_alpha: float = 0.80,
    cap_size: float = 4.0,
    ytick_interval: float = 0.0,
    xtick_interval: float = 0.0,
    fig_bg: str = "white",
    spine_width: float = 0.8,
    gridlines: bool = False,
    grid_style: str = "none",
):
    """One-line summary."""
    _ensure_imports()
    group_order, groups, bar_colors, fig, ax = _base_plot_setup(
        excel_path, sheet, color, None, figsize)
    _sk = _style_kwargs(locals())   # call immediately after _base_plot_setup

    # ... drawing code ...

    _apply_plotter_style(ax, font_size, **_sk)
    _apply_grid(ax, grid_style, gridlines)
    _base_plot_finish(ax, fig, title, xlabel, ytitle, yscale, ylim,
                      font_size, ref_line, len(group_order),
                      ref_line_label=ref_line_label, **_sk)
    return fig, ax
```

Critical rules:
- `_ensure_imports()` must be the very first call
- `_style_kwargs(locals())` must be called immediately after `_base_plot_setup()`, before any code that modifies `locals()`
- Always `return fig, ax`
- Never import matplotlib at module level

### Step 2 — Add PlotTypeConfig to `plotter_registry.py`

```python
PlotTypeConfig(
    key="my_chart",
    label="My Chart",
    fn_name="plotter_my_chart",
    tab_mode="bar",           # "bar" | "line" | "grouped_bar" | "scatter" | "heatmap" | "kaplan_meier" | "before_after"
    stats_tab="standard",     # see full list in registry file
    validate="_validate_bar", # validator method name on App class
    has_points=True,
    has_error_bars=True,
    has_legend=False,
    has_stats=True,
    x_continuous=False,
    axes_has_bar_width=False,
    axes_has_line_opts=False,
    extra_collect=lambda app, kw: kw.update({
        "my_param": app._get_var("my_var_key", default_value),
    }),
),
```

### Step 3 — Add Plotly spec builder (if this is a priority chart type)

Create `plotter_spec_my_chart.py`:

```python
"""Plotly spec builder for My Chart."""

import json
import pandas as pd
from plotter_plotly_theme import PRISM_TEMPLATE, PRISM_PALETTE

def build_my_chart_spec(kw: dict) -> str:
    import plotly.graph_objects as go
    # ... read Excel, build traces, return fig.to_json()
```

Then wire into `plotter_server._build_spec()`:
```python
elif chart_type == "my_chart":
    from plotter_spec_my_chart import build_my_chart_spec
    return build_my_chart_spec(kw)
```

### Step 4 — Update `/chart-types` metadata in `plotter_server.py`

The `/chart-types` endpoint reads from the registry. If your chart is in the registry, it should appear automatically. Confirm by checking the endpoint implementation.

### Step 5 — Write tests

Add tests to `tests/test_comprehensive.py` (chart function) and optionally `tests/test_specs.py` (if Plotly spec) and `tests/test_api.py` (if new endpoint).

Minimum test coverage:
1. Renders without crashing with valid data
2. Returns correct number of groups/traces
3. Validator rejects malformed data

Pattern:
```python
def test_my_chart_renders():
    with bar_excel({"Control": [1,2,3], "Drug": [4,5,6]}) as path:
        fig, ax = pf.plotter_my_chart(path)
        assert fig is not None
        plt.close(fig)
run("plotter_my_chart: renders without crash", test_my_chart_renders)
```

---

## Section 9: Development Commands

```bash
# Run the full test suite
python3 run_all.py

# Run a single suite
python3 run_all.py comprehensive     # chart function tests
python3 run_all.py control           # control-group logic tests
python3 run_all.py stats_verify      # statistical correctness tests
python3 run_all.py phase3_plotly     # Plotly spec builder tests

# Start web server (dev mode — no pywebview, browser access)
python3 plotter_web_server.py
# Open http://localhost:7331

# Build React SPA
cd plotter_web && npm install && npm run build && cd ..

# Launch desktop app (requires macOS + pywebview)
python3 plotter_webview.py

# Syntax check all Python modules
python3 -c "import plotter_functions, plotter_validators, plotter_results, plotter_registry, plotter_plotly_theme, plotter_spec_bar, plotter_spec_grouped_bar, plotter_spec_line, plotter_spec_scatter, plotter_widgets, plotter_wiki_content, plotter_import_pzfx, plotter_project, plotter_tabs, plotter_session, plotter_events, plotter_types, plotter_undo, plotter_errors, plotter_comparisons, plotter_presets, plotter_app_icons; print('OK')"

# Docker deployment
docker build -t spectra .
docker run -p 7331:7331 spectra

# PyInstaller packaging (not yet implemented)
# pyinstaller --onefile --windowed plotter_webview.py
```

---

## Section 10: Known Issues and Gotchas

1. **`_ensure_imports()` must be first** — matplotlib is `None` at module load. Calling `plt.subplots()` before `_ensure_imports()` raises `TypeError: 'NoneType' is not callable`.

2. **`_style_kwargs(locals())`** must be called after all parameters are defined but before any code that modifies `locals()`. Call it immediately after `_base_plot_setup()`.

3. **Docstring indentation after multi-line signatures** — place the docstring after the closing `):`, never between parameter lines.

4. **`plotter_results.py` for grouped charts** — `df.select_dtypes(include="number")` merges the two-row-header grouped layout incorrectly. Results panel shows all numeric cells combined for grouped/stacked charts. Known cosmetic issue.

5. **pywebview on headless servers** — pywebview requires a display. Use `plotter_web_server.py` (no Tk, no pywebview) for headless or server deployment.

6. **React SPA build** — Run `cd plotter_web && npm install && npm run build` before deployment. The `dist/` directory must exist for static file serving. FastAPI serves it at `/`.

7. **CORS** — FastAPI allows all origins by default. In production, restrict `allow_origins` in `plotter_server.py` to your domain.

8. **API key auth** — Set `PLOTTER_API_KEY` env var for non-local request authentication. Local requests (`127.0.0.1`/`localhost`) always bypass auth.

9. **test_canvas_renderer.py** — The canvas renderer module was removed. This test suite runs 0 tests (vacuous pass). Agent D will delete it.

10. **test_modular.py** — Tests for Tk widgets and tabs. Being retired by Agent D as the Tk app is superseded.

11. **`plotter_registry.py` is canonical** — Never add new chart types directly to `plotter_barplot_app.py`. All chart type definitions live in the registry.

12. **All new Python modules use `plotter_` prefix** — Never create modules with `prism_` prefix. Comments may say "GraphPad Prism" (that's the product being emulated) but Python identifiers use `plotter_`.

13. **`.cplot` files are ZIP archives** — contain `settings.json` + the original Excel. Do not assume plain JSON.

14. **ttk.Treeview heading colours on macOS Aqua** — `ttk.Style.configure` heading background is ignored. Fix requires `style.theme_use("clam")`. Not planned for React port.

15. **Phase 3 Plotly tests** — `test_phase3_plotly.py` has 9 failures when `plotly` is not installed. Install plotly first: `pip install plotly`.

16. **pingouin compatibility** — `prism_repeated_measures` had a `KeyError: 'p-unc'` bug (pingouin >= 0.5 uses `p_unc` with underscore). Fixed in Phase 2 with version-safe column lookup.

17. **`plotter_barplot_app.py` is spec only** — Do not maintain this file. Do not fix Tk bugs in it. The React UI replaces it. Read it to understand what controls the React UI needs.

18. **Multi-tab UI** — Deferred. The `TabState`/`TabManager`/`TabBar` infrastructure in `plotter_tabs.py` exists but is not wired into the React app. One chart at a time.

19. **`build_bar_spec` SEM calculation** — Current implementation computes population std then divides by sqrt(n). This matches the matplotlib implementation but uses pure Python (no numpy) for portability.

20. **`plotter_web_server.py`** — This is the standalone web server entry point (no Tk, no pywebview). Use this for headless/server deployment. The desktop entry point is `plotter_webview.py`.

---

## Section 11: Test Suite

Current suites registered in `run_all.py`:

| Suite key | File | Tests | Status | What it tests |
|---|---|---|---|---|
| `comprehensive` | `tests/test_comprehensive.py` | ~309 | Keep | All 29 matplotlib chart functions; stats engine |
| `p1p2p3` | `tests/test_p1_p2_p3.py` | ~80 | Delete (Agent D) | Style parameter regressions (overlapping with comprehensive) |
| `control` | `tests/test_control.py` | 20 | Keep | Control-group statistical logic |
| `canvas_renderer` | `tests/test_canvas_renderer.py` | 0 | Delete (Agent D) | Canvas renderer (module missing; vacuous) |
| `modular` | `tests/test_modular.py` | ~74 | Delete (Agent D) | Tk widgets and tabs (Tk retired) |
| `stats_verify` | `tests/test_stats_verification.py` | 37 | Keep | Statistical correctness |
| `phase3_plotly` | `tests/test_phase3_plotly.py` | 11 (9 fail without plotly) | Fix (Agent D) | Plotly spec builders |

Target after Agent D cleanup: ~200 tests across 6 suites in ~30 seconds.

New suites to add (Agent D):
- `tests/test_api.py` — FastAPI endpoint tests
- `tests/test_validators.py` — validator logic tests (extracted from test_modular)
- `tests/test_specs.py` — Plotly spec builder tests (expanded)

### When to add tests

- Every new chart function: minimum 3 tests in `test_comprehensive.py`
- Every new Plotly spec builder: tests in `tests/test_specs.py`
- Every new FastAPI endpoint: tests in `tests/test_api.py`
- Every new validator: tests in `tests/test_validators.py`

### Test harness patterns

```python
import plotter_test_harness as _h
from plotter_test_harness import pf, plt, ok, fail, run, section, summarise, bar_excel, with_excel

def test_my_chart():
    with bar_excel({"Control": [1,2,3], "Drug": [4,5,6]}) as path:
        fig, ax = pf.plotter_my_chart(path)
        assert ax.get_xlim()[0] < 0
        plt.close(fig)
run("plotter_my_chart: x axis extends left", test_my_chart)

summarise()
```

Available fixtures: `bar_excel`, `line_excel`, `grouped_excel`, `km_excel`, `heatmap_excel`, `two_way_excel`, `contingency_excel`, `with_excel`

---

## Section 12: Design Decisions and Reasoning

From `docs/PLAN.md`:

**Why pywebview over Electron?**
pywebview uses the native macOS WKWebView — no Chromium to bundle, smaller app size, authentic OS integration. Electron adds ~150MB+ to the app bundle. pywebview adds ~1MB.

**Why Plotly for 4 types, matplotlib PNG for 25?**
Plotly provides interactive charts (pan, zoom, editable labels, hover tooltips) that feel native in a desktop app. Writing full Plotly spec builders for all 29 chart types is a major engineering effort. The PNG fallback lets us ship a working app for all 29 types immediately while migrating incrementally. The Plotly path is the future; the PNG path is the present for the 25 remaining types.

**Why React for the UI instead of keeping Tkinter?**
Tkinter is limited — no CSS, no animation, no responsive layout, no npm ecosystem. The app needs a professional UI that matches GraphPad Prism's polish. React + Vite + TypeScript is the correct tool for a complex, stateful, data-driven UI. The Tk app proved the UX requirements; React delivers them.

**Why is the FastAPI server stateless?**
React owns all UI state. Each `/render` call is self-contained — it contains everything needed to reproduce the chart. This makes the server simple, testable, and horizontally scalable. The server holds no session, no chart state, no file handles.

**Why hybrid rendering (Plotly + PNG) instead of pure Plotly?**
The matplotlib 29 chart functions are tested, correct, mature. Rewriting all 29 in Plotly would require months and introduce new bugs. The hybrid approach preserves the matplotlib implementations as the source of truth while delivering interactive charts for the highest-value types immediately.

**Stats in Python, not JavaScript?**
Python has `scipy`, `pingouin`, `statsmodels`. JavaScript statistical libraries are not as mature or well-tested. All computation — data loading, stats, chart building — stays in Python. JavaScript only renders.

---

## One rule before every commit

```bash
python3 run_all.py   # must print 0 failures
```

Never commit if this fails. Never skip it. If tests regress, fix them before doing anything else.

---

## Commit conventions

```
feat: add lollipop chart Plotly spec builder
fix: correct asymmetric error bar calculation for log scale
test: add 8 forest plot validator tests
refactor: extract plotter_export.py from plotter_server
docs: update CLAUDE.md with pyramid chart layout
chore: move phase2/ to docs/archive/
```
