# Spectra

A GraphPad Prism-style scientific plotting desktop application for macOS. Load your data from an Excel spreadsheet, choose from 29 chart types, configure statistics, and generate publication-quality figures — all without writing code.

Spectra runs as a native macOS window (pywebview + WKWebView) backed by a React UI and a local FastAPI server. No terminal, no browser, no ports visible to the user.

---

## Requirements

- Python 3.11+
- macOS (for desktop app; web server mode works on Linux/Windows)
- Node.js 18+ (for building the frontend)

---

## Quick Start

```bash
# Install Python dependencies
pip install -r requirements.txt

# Build the React frontend
cd plotter_web && npm install && npm run build && cd ..

# Launch the desktop app
python3 plotter_webview.py
```

For UI design reference, open `docs/mockup.html` in a browser.

---

## Architecture

Spectra runs as a pywebview shell that opens a native WKWebView window. Inside, a React SPA communicates with a local FastAPI server at `127.0.0.1:7331`. Python handles all computation (data loading, statistics, chart rendering); JavaScript handles all rendering.

The 4 priority chart types (bar, grouped bar, line, scatter) render interactively via Plotly.js. The remaining 25 types render as high-DPI PNG via matplotlib and display as `<img>` elements. Both paths share the same Python functions and validators.

---

## 29 Chart Types

### Column
Bar Chart, Box Plot, Violin Plot, Dot Plot, Subcolumn Scatter, Before / After, Repeated Measures

### XY
Scatter Plot, Line Graph, Curve Fit, Area Chart, Bubble Chart, Bland-Altman

### Grouped
Grouped Bar, Stacked Bar, Two-Way ANOVA

### Distribution
Histogram, ECDF, Q-Q Plot, Column Statistics

### Survival
Kaplan-Meier

### Correlation
Heatmap, Forest Plot, Contingency, Chi-Square GoF

### Other
Waterfall, Lollipop, Pyramid, Raincloud

---

## Data Format

All charts read from a single Excel (`.xlsx`) or CSV file. Layout depends on chart type:

| Chart family | Row 0 | Rows 1+ |
|---|---|---|
| Bar, Box, Violin, Dot, Before/After | Group names | Numeric values |
| Line, Scatter, Curve Fit | X-label + series names | X value, Y replicates |
| Grouped Bar, Stacked Bar | Category names (row 0) + subgroup names (row 1) | Numeric values |
| Kaplan-Meier | Group names (each spanning 2 columns) | Time value, event (0/1) |
| Heatmap | Blank + column labels | Row label + numeric values |
| Two-Way ANOVA | `Factor_A`, `Factor_B`, `Value` | One observation per row |
| Contingency | Blank + outcome labels | Group name + counts |
| Forest Plot | `Study`, `Effect`, `Lower CI`, `Upper CI` | One study per row |
| Bland-Altman | Method A name, Method B name | Paired measurements |
| Pyramid | Category, Left series, Right series | Values |

The app validates your spreadsheet layout before plotting and shows specific error messages for any issues.

---

## Development

```bash
# Run the full test suite (must pass before committing)
python3 run_all.py

# Run a specific suite
python3 run_all.py comprehensive     # chart function tests
python3 run_all.py stats_verify      # statistical correctness
python3 run_all.py control           # control-group logic

# Start the web server only (no pywebview, for headless dev)
python3 plotter_web_server.py
# Open http://localhost:7331

# Syntax check all modules
python3 -c "import plotter_functions, plotter_validators, plotter_registry, plotter_server; print('OK')"
```

### Adding a chart type

See `CLAUDE.md` Section 8 for the full 5-step checklist. Short version:

1. Write the matplotlib function in `plotter_functions.py`
2. Add a `PlotTypeConfig` entry in `plotter_registry.py`
3. Add a Plotly spec builder in `plotter_spec_*.py` (if it's a priority type)
4. Add tests in `tests/test_comprehensive.py`

### Commit conventions

```
feat: add lollipop chart Plotly spec builder
fix: correct asymmetric error bar calculation for log scale
test: add validator tests for pyramid chart
docs: update CLAUDE.md with two-way ANOVA layout
```

---

## Credits

Built by [Claude](https://claude.ai) (Anthropic) in collaboration with Ashwin Pasupathy.
