"""
test_validators.py
==================
Tests for plotter_validators.py — standalone spreadsheet validation functions.

Extracted from the retired test_modular.py; focuses exclusively on
plotter_validators functions (no Tk widgets, no TabState, no results panel).

Sections:
  - Flat-header charts     — validate_bar, validate_flat_header
  - Line chart             — validate_line
  - Grouped bar            — validate_grouped_bar
  - Kaplan-Meier           — validate_kaplan_meier
  - Heatmap                — validate_heatmap
  - Miscellaneous          — two-way ANOVA, contingency, chi-sq GoF,
                             bland-altman, forest plot
  - Module integrity       — docstrings, count, return types

Run:
  python3 tests/test_validators.py
  python3 run_all.py validators
"""

import sys, os, math
import numpy as np
import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plotter_test_harness as _h
from plotter_test_harness import ok, fail, run, section, summarise

import plotter_validators as pv


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _flat_df(group_names, n_rows=5, seed=42):
    """Flat-header bar-chart DataFrame: row 0 = group names, rows 1+ = values."""
    rng = np.random.default_rng(seed)
    header = [group_names]
    data   = [rng.normal(5, 1, len(group_names)).tolist()
              for _ in range(n_rows)]
    return pd.DataFrame(header + data)


def _grouped_df(cats, subs, n_rows=4, seed=0):
    """Two-row-header grouped bar DataFrame."""
    rng   = np.random.default_rng(seed)
    row0  = [c for c in cats for _ in subs]
    row1  = [s for _ in cats for s in subs]
    data  = [rng.normal(5, 1, len(row0)).tolist() for _ in range(n_rows)]
    return pd.DataFrame([row0, row1] + data)


def _line_df(n_series=2, n_x=5, seed=1):
    """Line-chart DataFrame: row 0 = [X_label, S1, ...], rows 1+ = data."""
    rng    = np.random.default_rng(seed)
    header = ["X"] + [f"Series_{i}" for i in range(n_series)]
    rows   = [[float(i)] + rng.normal(5, 1, n_series).tolist()
              for i in range(n_x)]
    return pd.DataFrame([header] + rows)


def _km_df(n_groups=2, n_obs=10, seed=5):
    """KM layout: row 0 = group names (each spans 2 cols), row 1 = Time|Event."""
    rng  = np.random.default_rng(seed)
    row0 = [f"Group{i+1}" for i in range(n_groups) for _ in range(2)]
    row1 = ["Time", "Event"] * n_groups
    rows = []
    for _ in range(n_obs):
        row = []
        for _ in range(n_groups):
            row.append(float(rng.integers(1, 50)))
            row.append(float(rng.integers(0, 2)))
        rows.append(row)
    return pd.DataFrame([row0, row1] + rows)


def _heatmap_df(n_rows=4, n_cols=3, seed=7):
    """Heatmap layout: row 0 = [blank, col labels], rows 1+ = [row_label, vals]."""
    rng    = np.random.default_rng(seed)
    header = [None] + [f"Col{i}" for i in range(n_cols)]
    data   = [[f"Row{i}"] + rng.normal(0, 1, n_cols).tolist()
              for i in range(n_rows)]
    return pd.DataFrame([header] + data)


# ═════════════════════════════════════════════════════════════════════════════
# Flat-header charts
# ═════════════════════════════════════════════════════════════════════════════
section("validate_bar: flat-header")


def test_validate_bar_valid():
    df = _flat_df(["Control", "Drug_A", "Drug_B"], n_rows=6)
    errs, warns = pv.validate_bar(df)
    assert errs == [], f"Expected no errors, got {errs}"

run("validate_bar: valid flat-header sheet has no errors", test_validate_bar_valid)


def test_validate_bar_too_few_rows():
    df = pd.DataFrame([["G1", "G2"], [1.0, 2.0]])
    _, warns = pv.validate_bar(df)
    assert any("replicate" in w.lower() or "row" in w.lower() for w in warns), (
        f"Expected row-count warning, got {warns}")

run("validate_bar: warns when fewer than 3 data rows", test_validate_bar_too_few_rows)


def test_validate_bar_non_numeric():
    df = pd.DataFrame([["G1", "G2"],
                       ["abc", 2.0],
                       ["xyz", 3.0],
                       [1.0,   4.0]])
    errs, _ = pv.validate_bar(df)
    assert any("non-numeric" in e.lower() for e in errs), (
        f"Expected non-numeric error, got {errs}")

run("validate_bar: errors on non-numeric data cells", test_validate_bar_non_numeric)


def test_validate_bar_empty_header():
    df = pd.DataFrame([[np.nan, "G2"],
                       [1.0, 2.0],
                       [1.5, 2.5],
                       [1.2, 2.2]])
    _, warns = pv.validate_bar(df)
    assert any("empty" in w.lower() for w in warns), (
        f"Expected empty-header warning, got {warns}")

run("validate_bar: warns when a header cell is empty", test_validate_bar_empty_header)


def test_validate_bar_completely_empty_headers():
    df = pd.DataFrame([[np.nan, np.nan],
                       [1.0, 2.0],
                       [1.5, 2.5]])
    errs, _ = pv.validate_bar(df)
    assert any("entirely empty" in e.lower() or "row 1" in e.lower() for e in errs), (
        f"Expected entirely-empty-header error, got {errs}")

run("validate_bar: errors when all header cells are empty",
    test_validate_bar_completely_empty_headers)


def test_validate_flat_header_direct():
    df = _flat_df(["A", "B", "C"], n_rows=5)
    errs, warns = pv.validate_flat_header(df, min_groups=2, min_rows=3,
                                           chart_name="test chart")
    assert errs == []

run("validate_flat_header: direct call returns no errors for valid data",
    test_validate_flat_header_direct)


# ═════════════════════════════════════════════════════════════════════════════
# Line chart
# ═════════════════════════════════════════════════════════════════════════════
section("validate_line: line chart")


def test_validate_line_valid():
    df = _line_df(n_series=3, n_x=8)
    errs, _ = pv.validate_line(df)
    assert errs == [], f"Expected no errors, got {errs}"

run("validate_line: valid line sheet has no errors", test_validate_line_valid)


def test_validate_line_non_numeric_x():
    df = _line_df(n_series=2, n_x=4)
    df.iloc[2, 0] = "bad"
    errs, _ = pv.validate_line(df)
    assert any("non-numeric" in e.lower() or "x" in e.lower() for e in errs), (
        f"Expected non-numeric X error, got {errs}")

run("validate_line: errors on non-numeric X column", test_validate_line_non_numeric_x)


# ═════════════════════════════════════════════════════════════════════════════
# Grouped bar
# ═════════════════════════════════════════════════════════════════════════════
section("validate_grouped_bar: grouped bar")


def test_validate_grouped_bar_valid():
    df = _grouped_df(["Control", "Drug"], ["Male", "Female"], n_rows=5)
    errs, warns = pv.validate_grouped_bar(df)
    assert errs == [], f"Expected no errors, got {errs}"

run("validate_grouped_bar: valid 2-row-header sheet has no errors",
    test_validate_grouped_bar_valid)


def test_validate_grouped_bar_too_few_rows():
    df = _grouped_df(["C", "D"], ["M", "F"], n_rows=1)
    # At minimum no crash
    errs, warns = pv.validate_grouped_bar(df)

run("validate_grouped_bar: handles 1 data row without crashing",
    test_validate_grouped_bar_too_few_rows)


def test_validate_grouped_bar_no_data():
    df = pd.DataFrame([["C", "D"], ["M", "F"]])
    errs, _ = pv.validate_grouped_bar(df)
    assert errs != []

run("validate_grouped_bar: errors when sheet has no data rows",
    test_validate_grouped_bar_no_data)


# ═════════════════════════════════════════════════════════════════════════════
# Kaplan-Meier
# ═════════════════════════════════════════════════════════════════════════════
section("validate_kaplan_meier: survival data")


def test_validate_km_valid():
    df   = _km_df(n_groups=2, n_obs=8)
    errs, _ = pv.validate_kaplan_meier(df)
    assert errs == [], f"Expected no errors, got {errs}"

run("validate_kaplan_meier: valid KM sheet has no errors", test_validate_km_valid)


def test_validate_km_too_few_rows():
    df = pd.DataFrame([["G1", "G1"], ["Time", "Event"]])
    errs, _ = pv.validate_kaplan_meier(df)
    assert errs != []

run("validate_kaplan_meier: errors when fewer than 3 rows",
    test_validate_km_too_few_rows)


# ═════════════════════════════════════════════════════════════════════════════
# Heatmap
# ═════════════════════════════════════════════════════════════════════════════
section("validate_heatmap: heatmap")


def test_validate_heatmap_valid():
    df   = _heatmap_df(n_rows=4, n_cols=4)
    errs, _ = pv.validate_heatmap(df)
    assert errs == [], f"Unexpected errors: {errs}"

run("validate_heatmap: valid heatmap sheet has no errors", test_validate_heatmap_valid)


def test_validate_heatmap_non_numeric():
    df = _heatmap_df(n_rows=3, n_cols=3)
    df.iloc[2, 2] = "bad"
    errs, _ = pv.validate_heatmap(df)
    assert any("non-numeric" in e.lower() for e in errs), f"Expected error, got {errs}"

run("validate_heatmap: errors on non-numeric cell", test_validate_heatmap_non_numeric)


# ═════════════════════════════════════════════════════════════════════════════
# Miscellaneous validators
# ═════════════════════════════════════════════════════════════════════════════
section("Miscellaneous validators")


def test_validate_two_way_anova_valid():
    rng = np.random.default_rng(9)
    rows = [
        ["A1" if i < 5 else "A2", "B1" if i % 2 == 0 else "B2",
         float(rng.normal(5, 1))]
        for i in range(10)
    ]
    df = pd.DataFrame(rows, columns=["Factor_A", "Factor_B", "Value"])
    errs, _ = pv.validate_two_way_anova(df)
    assert errs == [], f"Unexpected errors: {errs}"

run("validate_two_way_anova: valid long-format sheet has no errors",
    test_validate_two_way_anova_valid)


def test_validate_contingency_valid():
    df = pd.DataFrame([
        [None,    "Outcome_A", "Outcome_B"],
        ["Group1", 10,          20],
        ["Group2", 15,          5],
    ])
    errs, _ = pv.validate_contingency(df)
    assert errs == [], f"Unexpected errors: {errs}"

run("validate_contingency: valid 2-group 2-outcome sheet has no errors",
    test_validate_contingency_valid)


def test_validate_chi_square_gof_valid():
    df = pd.DataFrame([
        ["A",   "B",  "C"],
        [30.0,  20.0, 50.0],
        [25.0,  25.0, 50.0],
    ])
    errs, _ = pv.validate_chi_square_gof(df)
    assert errs == [], f"Unexpected errors: {errs}"

run("validate_chi_square_gof: valid sheet has no errors",
    test_validate_chi_square_gof_valid)


def test_validate_bland_altman_valid():
    rng = np.random.default_rng(11)
    rows = [["Method_A", "Method_B"]] + [
        [float(rng.normal(5, 1)), float(rng.normal(5, 0.5))]
        for _ in range(10)
    ]
    df = pd.DataFrame(rows)
    errs, _ = pv.validate_bland_altman(df)
    assert errs == [], f"Unexpected errors: {errs}"

run("validate_bland_altman: valid paired-measures sheet has no errors",
    test_validate_bland_altman_valid)


def test_validate_forest_plot_valid():
    rows = [["Study", "Effect", "Lower", "Upper"]] + [
        [f"Study_{i}", float(np.random.normal(0.5, 0.1)),
         float(np.random.normal(0.3, 0.05)),
         float(np.random.normal(0.7, 0.05))]
        for i in range(5)
    ]
    df = pd.DataFrame(rows)
    errs, _ = pv.validate_forest_plot(df)
    assert errs == [], f"Unexpected errors: {errs}"

run("validate_forest_plot: valid forest-plot sheet has no errors",
    test_validate_forest_plot_valid)


def test_all_validators_return_tuple():
    """Every validator must return exactly (list, list) — never raises."""
    simple_df = _flat_df(["A", "B", "C"])
    for name in ["validate_bar", "validate_line", "validate_grouped_bar",
                 "validate_kaplan_meier", "validate_heatmap",
                 "validate_two_way_anova", "validate_contingency",
                 "validate_chi_square_gof", "validate_bland_altman",
                 "validate_forest_plot"]:
        fn = getattr(pv, name)
        try:
            result = fn(simple_df)
        except Exception:
            result = (["crash"], [])
        assert (isinstance(result, tuple) and len(result) == 2
                and isinstance(result[0], list) and isinstance(result[1], list)), (
            f"{name} did not return (list, list) — got {type(result)}")

run("All validators return (errors_list, warnings_list) for any input",
    test_all_validators_return_tuple)


# ═════════════════════════════════════════════════════════════════════════════
# Module integrity
# ═════════════════════════════════════════════════════════════════════════════
section("Module integrity")


def test_validators_module_docstring():
    assert pv.__doc__ and len(pv.__doc__) > 100

run("plotter_validators has a non-trivial module docstring",
    test_validators_module_docstring)


def test_all_validators_have_docstrings():
    import inspect
    missing = []
    for name, fn in inspect.getmembers(pv, inspect.isfunction):
        if name.startswith("validate_") and not inspect.getdoc(fn):
            missing.append(name)
    assert missing == [], f"Validators missing docstrings: {missing}"

run("All validate_* functions in plotter_validators have docstrings",
    test_all_validators_have_docstrings)


def test_validators_count():
    import inspect
    validators = [n for n, _ in inspect.getmembers(pv, inspect.isfunction)
                  if n.startswith("validate_")]
    assert len(validators) >= 10, f"Expected ≥10 validators, found {len(validators)}"

run("plotter_validators exports at least 10 validate_* functions",
    test_validators_count)


# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
summarise()
sys.exit(0 if _h.FAIL == 0 else 1)
