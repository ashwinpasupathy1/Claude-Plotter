"""
test_png_render.py
==================
Verifies that _build_png() in plotter_server.py successfully renders all
29 chart types to a base64 PNG data URI without crashing.

Each test:
  1. Creates a minimal valid Excel fixture using the harness helpers.
  2. Calls _build_png(chart_type, {"excel_path": path}) directly.
  3. Asserts the result starts with "data:image/png;base64,".
  4. Cleans up the temp file.

Run:
    python3 run_all.py png_render
    # or directly:
    python3 tests/test_png_render.py
"""

import sys
import os
import numpy as np

# ── Path setup ───────────────────────────────────────────────────────────────
_HERE = os.path.dirname(os.path.abspath(__file__))
_ROOT = os.path.dirname(_HERE)
sys.path.insert(0, _ROOT)
sys.path.insert(0, _HERE)

import plotter_test_harness as _h
from plotter_test_harness import (
    run, section,
    bar_excel, line_excel, simple_xy_excel, grouped_excel,
    km_excel, heatmap_excel, two_way_excel, contingency_excel,
    chi_gof_excel, bland_altman_excel, forest_excel, bubble_excel,
    with_excel,
)

import matplotlib
matplotlib.use("Agg")

# Import _build_png from the server module
from plotter_server import _build_png

_PNG_PREFIX = "data:image/png;base64,"


def _assert_png(result: str) -> None:
    assert isinstance(result, str), f"Expected str, got {type(result)}"
    assert result.startswith(_PNG_PREFIX), (
        f"Result does not start with PNG prefix. Got: {result[:80]!r}")
    # Sanity: base64 payload must be non-trivial (> 1 KB)
    assert len(result) > 1000, f"PNG payload suspiciously small ({len(result)} chars)"


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1 — Column charts (bar-style Excel layout)
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — Column charts")

_GROUPS3 = {
    "Control": np.array([10.1, 9.8, 10.5, 11.0, 9.5]),
    "Drug A":  np.array([14.2, 13.8, 15.1, 14.5, 13.9]),
    "Drug B":  np.array([18.0, 17.5, 19.2, 18.8, 17.9]),
}
_GROUPS2 = {
    "Before": np.array([10.0, 9.5, 11.0, 10.3, 9.8, 10.6]),
    "After":  np.array([13.0, 12.5, 14.1, 13.3, 12.8, 13.6]),
}


def test_bar():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("bar", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("bar: renders to PNG", test_bar)


def test_box():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("box", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("box: renders to PNG", test_box)


def test_violin():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("violin", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("violin: renders to PNG", test_violin)


def test_dot_plot():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("dot_plot", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("dot_plot: renders to PNG", test_dot_plot)


def test_subcolumn_scatter():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("subcolumn_scatter", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("subcolumn_scatter: renders to PNG", test_subcolumn_scatter)


def test_before_after():
    xl = bar_excel(_GROUPS2)
    try:
        result = _build_png("before_after", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("before_after: renders to PNG", test_before_after)


def test_repeated_measures():
    _rng = np.random.default_rng(7)
    t0 = _rng.normal(10.0, 1.0, 8)
    rm_groups = {
        "T0": t0,
        "T1": t0 + _rng.normal(1.0, 0.5, 8),
        "T2": t0 + _rng.normal(2.0, 0.5, 8),
        "T3": t0 + _rng.normal(3.0, 0.5, 8),
    }
    xl = bar_excel(rm_groups)
    try:
        result = _build_png("repeated_measures", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("repeated_measures: renders to PNG", test_repeated_measures)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2 — XY charts
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — XY charts")

_XS = np.linspace(1, 10, 12)
_YS = 2.5 * _XS + np.random.default_rng(42).normal(0, 1.5, 12)


def test_scatter():
    xl = simple_xy_excel(_XS, _YS)
    try:
        result = _build_png("scatter", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("scatter: renders to PNG", test_scatter)


def test_line():
    _rng = np.random.default_rng(99)
    x_vals = np.array([0, 1, 2, 4, 8, 16], dtype=float)
    series = {
        "Control": np.column_stack([
            x_vals * 0.5 + _rng.normal(0, 0.3, len(x_vals)) for _ in range(3)
        ]),
        "Drug": np.column_stack([
            x_vals * 0.9 + _rng.normal(0, 0.3, len(x_vals)) for _ in range(3)
        ]),
    }
    xl = line_excel(series, x_vals)
    try:
        result = _build_png("line", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("line: renders to PNG", test_line)


def test_curve_fit():
    # Simple XY data; use Linear model which always converges
    xl = simple_xy_excel(_XS, _YS)
    try:
        result = _build_png("curve_fit", {"excel_path": xl, "model_name": "Linear"})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("curve_fit: renders to PNG (Linear model)", test_curve_fit)


def test_area_chart():
    _rng = np.random.default_rng(11)
    x_vals = np.array([0, 1, 2, 4, 8], dtype=float)
    series = {
        "Series1": np.column_stack([
            x_vals * 1.5 + _rng.normal(0, 0.3, len(x_vals)) for _ in range(2)
        ]),
    }
    xl = line_excel(series, x_vals)
    try:
        result = _build_png("area_chart", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("area_chart: renders to PNG", test_area_chart)


def test_bubble():
    _rng = np.random.default_rng(55)
    xs   = _rng.uniform(1, 10, 8)
    ys   = _rng.uniform(1, 10, 8)
    szs  = _rng.uniform(5, 50, 8)
    xl = bubble_excel(xs, ys, szs)
    try:
        result = _build_png("bubble", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("bubble: renders to PNG", test_bubble)


def test_bland_altman():
    _rng = np.random.default_rng(77)
    a = _rng.normal(100, 10, 20)
    b = a + _rng.normal(0, 3, 20)
    xl = bland_altman_excel(a, b)
    try:
        result = _build_png("bland_altman", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("bland_altman: renders to PNG", test_bland_altman)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3 — Grouped charts
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — Grouped charts")

_CATS = ["CatA", "CatB"]
_SUBS = ["SubX", "SubY", "SubZ"]
_rng_g = np.random.default_rng(13)
_GROUPED_DATA = {
    c: {s: _rng_g.normal(i * 3 + j * 1.5, 1.0, 6).tolist()
        for j, s in enumerate(_SUBS)}
    for i, c in enumerate(_CATS)
}


def test_grouped_bar():
    xl = grouped_excel(_CATS, _SUBS, _GROUPED_DATA)
    try:
        result = _build_png("grouped_bar", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("grouped_bar: renders to PNG", test_grouped_bar)


def test_stacked_bar():
    xl = grouped_excel(_CATS, _SUBS, _GROUPED_DATA)
    try:
        result = _build_png("stacked_bar", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("stacked_bar: renders to PNG", test_stacked_bar)


def test_two_way_anova():
    _rng2 = np.random.default_rng(21)
    records = [
        (f, g, v)
        for f in ["Drug", "Control"]
        for g in ["Male", "Female"]
        for v in _rng2.normal(
            {"Drug_Male": 5, "Drug_Female": 6, "Control_Male": 3, "Control_Female": 4}[f + "_" + g],
            0.8, 6
        )
    ]
    xl = two_way_excel(records)
    try:
        result = _build_png("two_way_anova", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("two_way_anova: renders to PNG", test_two_way_anova)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4 — Distribution charts
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — Distribution charts")


def test_histogram():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("histogram", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("histogram: renders to PNG", test_histogram)


def test_ecdf():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("ecdf", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("ecdf: renders to PNG", test_ecdf)


def test_qq_plot():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("qq_plot", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("qq_plot: renders to PNG", test_qq_plot)


def test_column_stats():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("column_stats", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("column_stats: renders to PNG", test_column_stats)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5 — Survival chart
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — Survival charts")


def test_kaplan_meier():
    km_data = {
        "Control":   {"time": [5, 10, 15, 20, 25, 30, 35, 40], "event": [1, 1, 0, 1, 1, 0, 1, 0]},
        "Treatment": {"time": [3,  8, 12, 18, 22, 28, 32, 38], "event": [1, 1, 1, 0, 1, 1, 0, 0]},
    }
    xl = km_excel(km_data)
    try:
        result = _build_png("kaplan_meier", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("kaplan_meier: renders to PNG", test_kaplan_meier)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6 — Correlation charts
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — Correlation charts")


def test_heatmap():
    _rng3 = np.random.default_rng(88)
    matrix = _rng3.normal(0, 1, (6, 4))
    row_labels = [f"Gene{i}" for i in range(6)]
    col_labels = ["S1", "S2", "S3", "S4"]
    xl = heatmap_excel(matrix, row_labels, col_labels)
    try:
        result = _build_png("heatmap", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("heatmap: renders to PNG", test_heatmap)


def test_forest_plot():
    studies  = ["Study A", "Study B", "Study C", "Study D"]
    effects  = [0.5, -0.2, 0.8, 0.3]
    ci_lo    = [0.1, -0.6, 0.4, -0.1]
    ci_hi    = [0.9,  0.2, 1.2,  0.7]
    weights  = [30.0, 25.0, 20.0, 25.0]
    xl = forest_excel(studies, effects, ci_lo, ci_hi, weights)
    try:
        result = _build_png("forest_plot", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("forest_plot: renders to PNG", test_forest_plot)


def test_contingency():
    xl = contingency_excel(
        row_labels=["Young", "Middle", "Old"],
        col_labels=["Recovered", "Not Recovered"],
        matrix=np.array([[45, 15], [30, 20], [20, 30]]),
    )
    try:
        result = _build_png("contingency", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("contingency: renders to PNG", test_contingency)


def test_chi_square_gof():
    xl = chi_gof_excel(
        categories=["Cat A", "Cat B", "Cat C", "Cat D"],
        observed=[30.0, 20.0, 15.0, 35.0],
    )
    try:
        result = _build_png("chi_square_gof", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("chi_square_gof: renders to PNG", test_chi_square_gof)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 7 — Other charts
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — Other charts")


def test_waterfall():
    # Waterfall uses bar-style Excel (flat header), values are deltas
    groups = {
        "Revenue":    np.array([500.0]),
        "Cost":       np.array([-200.0]),
        "Tax":        np.array([-80.0]),
        "Investment": np.array([150.0]),
    }
    xl = bar_excel(groups)
    try:
        result = _build_png("waterfall", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("waterfall: renders to PNG", test_waterfall)


def test_lollipop():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("lollipop", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("lollipop: renders to PNG", test_lollipop)


def test_pyramid():
    """Pyramid uses header=0 (first row = column headers).
    Layout: Category | Left series | Right series."""
    import pandas as pd
    import tempfile
    with tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False) as f:
        path = f.name
    try:
        df = pd.DataFrame({
            "Age Group": ["0-9", "10-19", "20-29", "30-39", "40-49"],
            "Male":      [120, 150, 180, 160, 140],
            "Female":    [115, 145, 175, 165, 145],
        })
        df.to_excel(path, index=False)
        result = _build_png("pyramid", {"excel_path": path})
        _assert_png(result)
    finally:
        os.unlink(path)

run("pyramid: renders to PNG", test_pyramid)


def test_raincloud():
    xl = bar_excel(_GROUPS3)
    try:
        result = _build_png("raincloud", {"excel_path": xl})
        _assert_png(result)
    finally:
        os.unlink(xl)

run("raincloud: renders to PNG", test_raincloud)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 8 — Edge cases / integration
# ─────────────────────────────────────────────────────────────────────────────

section("PNG render — Edge cases")


def test_unknown_chart_type_raises():
    raised = False
    try:
        _build_png("does_not_exist", {"excel_path": "/dev/null"})
    except ValueError as exc:
        assert "does_not_exist" in str(exc)
        raised = True
    assert raised, "Expected ValueError for unknown chart type but none was raised"

run("unknown chart type raises ValueError", test_unknown_chart_type_raises)


def test_bar_with_title_and_labels():
    xl = bar_excel({"A": np.array([1, 2, 3]), "B": np.array([4, 5, 6])})
    try:
        result = _build_png("bar", {
            "excel_path": xl,
            "title": "Test Title",
            "xlabel": "Groups",
            "ytitle": "Values",
        })
        _assert_png(result)
    finally:
        os.unlink(xl)

run("bar: extra kwargs (title, xlabel, ytitle) pass through filter", test_bar_with_title_and_labels)


def test_bar_unsupported_kwarg_filtered():
    """Unsupported kwargs must be silently filtered, not raise TypeError."""
    xl = bar_excel({"A": np.array([1, 2, 3])})
    try:
        result = _build_png("bar", {
            "excel_path": xl,
            "nonexistent_param_xyz": "should_be_ignored",
        })
        _assert_png(result)
    finally:
        os.unlink(xl)

run("bar: unsupported kwargs are silently filtered", test_bar_unsupported_kwarg_filtered)


# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

_h.summarise("png_render")

if __name__ == "__main__":
    sys.exit(0 if _h.FAIL == 0 else 1)
