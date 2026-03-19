# Spectra — Master Plan
_Last updated: 2026-03-18. Replaces all previous phase documents. Agents A-E deployed._

---

## What this product is

**Spectra** is a GraphPad Prism-style scientific plotting desktop application for macOS. It runs as a native window powered by pywebview, with a React SPA as the UI and a local FastAPI server as the backend. From the user's perspective it is a double-click-to-launch native app — there is no visible server, no terminal, no ports.

There is no web deployment goal. Web deployment is not a priority and should not influence architectural decisions.

---

## Guiding principles

1. **The product is a desktop app.** pywebview is the shell. The user should never see a server, a port, or a terminal.
2. **Python owns all computation.** Stats, data loading, chart spec building — all Python. JavaScript only renders.
3. **React owns all UI state.** The FastAPI server is stateless. Each request to `/render` is self-contained.
4. **plotter_functions.py is the backbone.** All 29 chart functions stay in Python. The matplotlib implementations are the source of truth for chart logic even as Plotly handles rendering.
5. **Old Tkinter UI is a blueprint, not a product.** `plotter_barplot_app.py` is a 6,688-line spec document for what the React UI must contain. It is not maintained going forward.
6. **Tests test behaviour, not implementation.** Tests that test Tk widgets or a missing canvas renderer module are dead weight. Tests that verify statistical correctness and chart function outputs are permanent.

---

## Target architecture

```
User double-clicks Spectra.app
        │
        ▼
plotter_webview.py          ← thin entry point
  ├── starts FastAPI server  (background thread, 127.0.0.1:7331, invisible)
  └── opens pywebview window (WKWebView on macOS, full-screen native window)
        │
        ▼
React SPA  (plotter_web/src/)
  ├── sidebar:         chart type selector (29 types, 7 groups with correct labels)
  ├── main area:       Plotly.js chart (interactive, editable on-chart + in panel)
  ├── right panel:     tabbed controls — Data | Axes | Style | Stats
  ├── help panel:      slide-in statistical methods wiki (29 sections, triggered by ? button)
  └── results strip:   collapsible — hidden by default, toggle arrow to expand
        │
        │  POST /render { chart_type, kw }   → returns Plotly spec + stats results
        │  POST /render-png { chart_type, kw } → returns base64 PNG (fallback)
        ▼
FastAPI server  (plotter_server.py)
  ├── plotter_spec_*.py     ← Plotly JSON specs with significance brackets (4 types)
  └── plotter_functions.py  ← matplotlib → PNG fallback (25 remaining types)

Data flow for file loading:
  User clicks "Open…" OR drags file onto window
  → pywebview native file dialog / drop event → returns local path
  → React stores path in state → passed in kw on every /render call
  → FastAPI reads Excel (.xlsx) or CSV with pandas
```

---

## Rendering strategy

Only 4 of 29 chart types currently have Plotly spec builders. The strategy is **hybrid**:

| Category | Chart types | Rendering |
|---|---|---|
| **Plotly (interactive)** | bar, grouped_bar, line, scatter | `plotter_spec_*.py` → Plotly.js |
| **matplotlib → PNG (Phase 1)** | remaining 25 types | `plotter_functions.py` → base64 PNG |
| **Plotly (future)** | box, violin, histogram, heatmap, bubble, stacked_bar | migrate incrementally |
| **Plotly (hard, later)** | forest_plot, before_after, bland_altman, pyramid | custom work required |

Serving a PNG to the React frontend is one additional endpoint (`/render-png`) that returns `{ "image": "data:image/png;base64,..." }`. The React component renders it in an `<img>` tag. This is intentionally simple.

---

## All design decisions (fully settled)

| Decision | Choice | Notes |
|---|---|---|
| **App name** | Spectra | Scientific (spectrum/color), premium feel, GraphPad Prism peer |
| **Desktop shell** | pywebview | Native macOS WKWebView, no Electron |
| **Chart rendering** | Hybrid: Plotly + matplotlib-PNG | Plotly for 4 types now, PNG fallback for 25, migrate incrementally |
| **UI state ownership** | React owns all state | Server is stateless; each `/render` call is self-contained |
| **File loading** | Native file dialog + drag-and-drop | pywebview API for dialog; drop event on app window |
| **Data formats** | Excel (.xlsx) + CSV | One `elif` in validators; pandas handles both natively |
| **Stats UI** | Progressive disclosure (Option C) | Common options always visible; advanced in collapsible "Advanced" section |
| **Help Analyze** | Slide-in panel (Option A) | `?` toolbar button slides wiki panel in from right, chart stays visible |
| **Results strip** | Collapsible, hidden by default | Toggle arrow at bottom; stats shown in Stats tab panel when strip hidden |
| **Chart editing** | Both on-chart and in panel, synced | Plotly `editable: true` + bidirectional sync with right panel |
| **Export** | Configurable | Format (PNG / SVG / PDF) + width + height (inches) + DPI (72/150/300) |
| **Multi-tab** | Deferred — one chart at a time | Not in scope for current agent sprint |
| **Packaging** | PyInstaller → `.app` bundle | No Python install required for end users |
| **Significance brackets** | Yes — Plotly shapes + annotations | Horizontal bar + vertical drops + stars/p-value above; matches Prism style |
| **Tooltips** | Yes — every control has a `?` hover tooltip | Plain English explanation of what each option does |

## Sidebar chart groupings (corrected)

The sidebar groups charts by data type, matching GraphPad Prism's structure.

| Group | Charts (29 total) |
|---|---|
| **Column** | Bar Chart, Box Plot, Violin, Dot Plot, Subcolumn Scatter, Before/After, Repeated Measures |
| **XY** | Scatter, Line Graph, Curve Fit, Area Chart, Bubble, Bland-Altman |
| **Grouped** | Grouped Bar, Stacked Bar, Two-Way ANOVA |
| **Distribution** | Histogram, ECDF, Q-Q Plot, Column Stats |
| **Survival** | Kaplan-Meier |
| **Correlation** | Heatmap, Forest Plot, Contingency, Chi-Square GoF |
| **Other** | Waterfall, Lollipop, Pyramid, Raincloud |

---

## Agent breakdown

Run all agents simultaneously after decisions above are confirmed. None block each other except Agent E (runs last).

### Agent A — React UI (Opus 4.6, largest scope)
**Goal:** Build the full React SPA UI so the app is actually usable as Spectra.

Uses `plotter_barplot_app.py` as the spec — every control, label, and parameter in the Tk app must appear somewhere in the React UI. Reference `docs/mockup.html` for target layout and visual style.

Deliverables:
- **App name**: "Spectra" everywhere (title bar, window title, about)
- **Sidebar**: 29 chart type buttons with SVG icons, grouped into 7 labelled sections (Column / XY / Grouped / Distribution / Survival / Correlation / Other). See sidebar groupings table in PLAN.md.
- **Right panel**: tabbed Data / Axes / Style / Stats controls
  - Every control has a `?` hover tooltip in plain English
  - Stats tab: common options always visible (test type, post-hoc, show brackets, show p-values); advanced options (permutations, alpha, correction method) in a collapsible "Advanced ▸" section
- **File open**: `window.pywebview.api.open_file()` → local path in React state; also drag-and-drop onto app window
- **Chart area**: Plotly spec from `/render` (interactive, `editable: true`); PNG `<img>` from `/render-png` for fallback charts; on-chart edits (title, axis labels) sync bidirectionally to right panel
- **Help panel**: slide-in from right when `?` toolbar button clicked; renders `plotter_wiki_content.py` sections as formatted HTML; close button slides it back
- **Results strip**: collapsed by default; toggle arrow at bottom edge expands it; stats also shown inline in Stats tab
- **Toolbar**: Plot button, Reset, Export (with format/size/DPI picker: PNG/SVG/PDF, width×height in inches, 72/150/300 DPI), `?` Help button
- **Significance brackets**: rendered as Plotly shapes+annotations on chart when stats are enabled

### Agent B — FastAPI extension
**Goal:** Extend the server to handle all 29 chart types and file loading cleanly.

Deliverables:
- `/render-png` endpoint: calls `plotter_functions.py`, returns base64 PNG for the 25 non-Plotly chart types
- `/open-file` endpoint (or pywebview API bridge): triggers native macOS file dialog
- CSV support: detect `.csv` vs `.xlsx` in validators and all spec builders
- `/chart-types` endpoint: return full metadata (label, icon name, tab_mode) for React sidebar
- Clean error responses: `{ ok: false, error: "...", detail: "..." }` for all failure modes

### Agent C — matplotlib PNG fallback
**Goal:** Make all 25 remaining chart types work in the React UI via PNG rendering.

Deliverables:
- `/render-png` implementation that routes to the correct `plotter_functions.py` function
- React `PlotterImage` component that displays base64 PNG with download button
- Verify all 29 chart types render without crashing (use existing `test_comprehensive.py`)
- Basic PNG export (right-click save or download button)

### Agent D — Test suite cleanup
**Goal:** Retire dead tests, fix broken ones, add API tests. Target: ~200 focused tests.

Current state:
- `test_canvas_renderer.py` — 0 tests run (module doesn't exist). **Delete.**
- `test_modular.py` — 74 tests for Tk widgets and tabs. **Delete** (Tk is retired).
- `test_p1_p2_p3.py` — 80 style regression tests, heavily overlapping with comprehensive. **Delete.**
- `test_comprehensive.py` — 309 tests for matplotlib chart functions. **Keep, trim duplicates.**
- `test_stats_verification.py` — 37 statistical correctness tests. **Keep.**
- `test_control.py` — 20 control-group logic tests. **Keep.**
- `test_phase3_plotly.py` — 11 Plotly spec tests, 9 failing (plotly not installed). **Fix: install plotly, keep.**

New tests to add:
- `tests/test_api.py` — FastAPI endpoint tests (health, render, render-png, chart-types, error cases)
- `tests/test_validators.py` — extracted from test_modular, keep validator logic tests
- `tests/test_specs.py` — expand Plotly spec tests to cover all implemented spec builders

New target: ~200 tests across 6 suites in ~30 seconds.

### Agent E — File structure + CLAUDE.md (runs last)
**Goal:** Make the repository human-readable and document everything comprehensively.

File structure target:
```
claude-plotter/
├── CLAUDE.md                    ← comprehensive LLM context document (rewritten)
├── README.md                    ← user-facing: what it is, how to run, screenshots
├── docs/
│   ├── PLAN.md                  ← this file
│   ├── mockup.html              ← UI mockup (rendered, screenshottable)
│   └── archive/                 ← phase2/, phase3/, phase4/ moved here
├── backend/
│   ├── plotter_functions.py     ← 29 matplotlib chart functions
│   ├── plotter_validators.py    ← Excel/CSV layout validators
│   ├── plotter_registry.py      ← PlotTypeConfig registry
│   ├── plotter_server.py        ← FastAPI app factory
│   ├── plotter_spec_bar.py      ← Plotly spec builders (4 types)
│   ├── plotter_spec_grouped_bar.py
│   ├── plotter_spec_line.py
│   ├── plotter_spec_scatter.py
│   ├── plotter_plotly_theme.py  ← shared Plotly theme
│   ├── plotter_results.py       ← results panel data
│   ├── plotter_wiki_content.py  ← statistical reference text
│   └── plotter_import_pzfx.py  ← GraphPad .pzfx importer
├── desktop/
│   ├── plotter_webview.py       ← entry point: starts server + opens pywebview
│   ├── plotter_widgets.py       ← (legacy Tk, keep for reference)
│   └── plotter_app_icons.py     ← SVG icon definitions (reference for React)
├── frontend/                    ← (rename from plotter_web/)
│   ├── src/
│   │   ├── App.tsx
│   │   ├── Sidebar.tsx
│   │   ├── ControlPanel.tsx
│   │   ├── ChartArea.tsx
│   │   └── ResultsStrip.tsx
│   ├── package.json
│   └── vite.config.ts
├── tests/
│   ├── test_comprehensive.py    ← chart function tests (trimmed)
│   ├── test_stats.py            ← merged stats_verify + control
│   ├── test_specs.py            ← Plotly spec builder tests
│   ├── test_api.py              ← FastAPI endpoint tests (new)
│   ├── test_validators.py       ← validator tests (extracted)
│   └── plotter_test_harness.py  ← shared fixtures
├── run_all.py                   ← unified test runner
├── requirements.txt             ← all deps including plotly
├── requirements-dev.txt         ← test deps
└── Dockerfile                   ← web deployment (if ever needed)
```

CLAUDE.md rewrite must cover:
- Product definition and target user
- Full architecture diagram (pywebview → React → FastAPI → plotter_functions)
- Every file: purpose, key functions/classes, dependencies, what NOT to touch
- Rendering pipeline: Plotly path vs PNG fallback path
- How to add a new chart type (5-step checklist, updated for new structure)
- Test suite: what each suite tests, how to run, target counts
- Excel/CSV layout conventions for all 29 chart types
- Statistical methods: which function uses which test, effect sizes, corrections
- Known issues and gotchas
- How to package as .app with PyInstaller

---

## Current test status (as of 2026-03-18)

```
python3 run_all.py
  comprehensive:   309/309  ✓
  p1p2p3:           80/80   ✓  (to be deleted by Agent D)
  control:          20/20   ✓
  canvas_renderer:   0/0    ✓  (vacuous — module missing, to be deleted)
  modular:          74/74   ✓  (to be deleted by Agent D)
  stats_verify:     37/37   ✓
  phase3_plotly:    2/11    ✗  9 failures (plotly not installed)

Total: 522 passing, 9 failing, 531 registered
```

---

## What exists and works right now

| Component | Status |
|---|---|
| 29 matplotlib chart functions | Working, tested |
| Statistical engine (t-test, ANOVA, Dunnett, KM, etc.) | Working, tested |
| Excel validators for all 29 chart types | Working, tested |
| FastAPI server (`/render`, `/event`, `/health`, `/chart-types`) | Working |
| Plotly spec builders for bar, grouped_bar, line, scatter | Working (needs plotly installed) |
| pywebview desktop shell | Built, untested end-to-end |
| React SPA | Stub only — App.tsx has hardcoded empty values |
| PyInstaller packaging | Not started |

## What the old Tk app (`plotter_barplot_app.py`) tells us

This 6,688-line file is the living spec for the React UI. Every tab, control, and parameter that the React UI needs is already implemented there. Before Agent A starts, read:
- `_tab_data()` — Data tab controls
- `_tab_axes()` — Axes tab controls
- `_tab_stats()` — Stats tab controls (and all `_tab_stats_*` variants per chart type)
- `_collect()` — the complete `kw` dict sent to chart functions (defines the API contract)
- `_build_sidebar()` — 29 chart types and their groupings

Do not delete this file until the React UI has parity.
