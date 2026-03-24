"""Analysis engine tests -- replaces legacy Plotly spec builder tests."""

import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import plotter_test_harness as _h
from plotter_test_harness import run, section, bar_excel, simple_xy_excel
import numpy as np

# ===================================================================
# Analysis engine -- bar
# ===================================================================

section("Analysis engine: bar chart analysis")

def test_bar_analysis_returns_groups():
    xl = bar_excel({"Control": np.array([1,2,3]), "Drug": np.array([4,5,6])})
    try:
        from refraction.analysis import analyze
        result = analyze("bar", xl, {"title": "Test"})
        assert result["ok"] is True
        assert "groups" in result
        assert len(result["groups"]) == 2
        assert result["title"] == "Test"
    finally:
        os.unlink(xl)
run("analysis engine: bar returns groups", test_bar_analysis_returns_groups)


def test_bar_analysis_has_two_groups():
    xl = bar_excel({"Control": np.array([1,2,3]), "Drug": np.array([4,5,6])})
    try:
        from refraction.analysis import analyze
        result = analyze("bar", xl)
        assert len(result["groups"]) == 2, f"Expected 2, got {len(result['groups'])}"
    finally:
        os.unlink(xl)
run("analysis engine: two groups = two entries", test_bar_analysis_has_two_groups)


def test_bar_analysis_means_correct():
    xl = bar_excel({"A": np.array([10, 20, 30])})
    try:
        from refraction.analysis import analyze
        result = analyze("bar", xl)
        assert abs(result["groups"][0]["mean"] - 20.0) < 0.01
    finally:
        os.unlink(xl)
run("analysis engine: mean is correct", test_bar_analysis_means_correct)


# ===================================================================
# Analysis engine -- statistics
# ===================================================================

section("Analysis engine: statistical comparisons")

def test_bar_analysis_with_stats():
    xl = bar_excel({"Control": np.array([1,2,3,4,5]),
                    "Drug": np.array([10,11,12,13,14])})
    try:
        from refraction.analysis import analyze
        result = analyze("bar", xl, {"stats_test": "parametric"})
        assert result["ok"] is True
        assert len(result["comparisons"]) >= 1
        assert "p_value" in result["comparisons"][0]
        assert "stars" in result["comparisons"][0]
    finally:
        os.unlink(xl)
run("analysis engine: parametric stats returns comparisons", test_bar_analysis_with_stats)


def test_bar_analysis_no_stats():
    xl = bar_excel({"A": np.array([1,2,3])})
    try:
        from refraction.analysis import analyze
        result = analyze("bar", xl, {"stats_test": "none"})
        assert result["ok"] is True
        assert result["comparisons"] == []
    finally:
        os.unlink(xl)
run("analysis engine: stats_test=none returns empty comparisons", test_bar_analysis_no_stats)


# ===================================================================
# Analysis engine -- descriptive statistics
# ===================================================================

section("Analysis engine: descriptive statistics")

def test_group_has_all_stats():
    xl = bar_excel({"A": np.array([2.0, 4.0, 6.0, 8.0, 10.0])})
    try:
        from refraction.analysis import analyze
        result = analyze("bar", xl)
        g = result["groups"][0]
        for key in ("name", "values", "mean", "median", "sd", "sem", "ci95", "n", "color"):
            assert key in g, f"Missing key: {key}"
        assert g["n"] == 5
        assert abs(g["mean"] - 6.0) < 0.01
        assert abs(g["median"] - 6.0) < 0.01
    finally:
        os.unlink(xl)
run("analysis engine: group has all stat fields", test_group_has_all_stats)


# ===================================================================
# SEM accuracy -- verifies sample variance (n-1), not population (n)
# ===================================================================

section("Analysis engine: SEM calculation accuracy")

def test_sem_matches_scipy():
    """SEM should match scipy.stats.sem (which uses ddof=1)."""
    from scipy import stats as scipy_stats
    vals_a = np.array([2.0, 4.0, 6.0, 8.0, 10.0])
    vals_b = np.array([1.0, 3.0, 5.0, 7.0, 9.0])
    expected_sem_a = scipy_stats.sem(vals_a)
    expected_sem_b = scipy_stats.sem(vals_b)

    xl = bar_excel({"A": vals_a, "B": vals_b})
    try:
        from refraction.analysis import analyze
        result = analyze("bar", xl, {"error_type": "sem"})
        actual_sem_a = result["groups"][0]["sem"]
        actual_sem_b = result["groups"][1]["sem"]
        assert abs(actual_sem_a - expected_sem_a) < 1e-10, \
            f"SEM mismatch: got {actual_sem_a}, expected {expected_sem_a}"
        assert abs(actual_sem_b - expected_sem_b) < 1e-10, \
            f"SEM mismatch: got {actual_sem_b}, expected {expected_sem_b}"
    finally:
        os.unlink(xl)
run("analysis engine: SEM matches scipy.stats.sem (sample variance)", test_sem_matches_scipy)


# ===================================================================
# Error handling
# ===================================================================

section("Analysis engine: error handling")

def test_missing_file():
    from refraction.analysis import analyze
    result = analyze("bar", "/nonexistent/file.xlsx")
    assert result["ok"] is False
    assert "error" in result
run("analysis engine: missing file returns error", test_missing_file)


# ===================================================================
# FastAPI server
# ===================================================================

section("FastAPI server: health endpoint")

def test_server_starts():
    from refraction.server.api import start_server, get_port
    import urllib.request
    start_server()
    time.sleep(2)
    try:
        resp = urllib.request.urlopen(f"http://127.0.0.1:{get_port()}/health", timeout=3)
        assert resp.status == 200
    except Exception as e:
        assert False, f"Server did not start: {e}"
run("server: /health endpoint responds", test_server_starts)


def test_server_analyze_endpoint():
    from refraction.server.api import get_port
    import urllib.request
    xl = bar_excel({"A": np.array([1,2,3]), "B": np.array([4,5,6])})
    try:
        payload = json.dumps({
            "chart_type": "bar",
            "excel_path": xl,
        }).encode()
        req = urllib.request.Request(
            f"http://127.0.0.1:{get_port()}/analyze",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        resp = urllib.request.urlopen(req, timeout=5)
        data = json.loads(resp.read())
        assert data["ok"] is True, f"Analyze failed: {data}"
        assert "groups" in data
    finally:
        os.unlink(xl)
run("server: /analyze returns analysis result", test_server_analyze_endpoint)


# ===================================================================
# Config key compatibility
# ===================================================================

section("Analysis engine: config key compatibility")

def test_xlabel_alias():
    """Both x_label and xlabel should work."""
    xl = bar_excel({"A": np.array([1,2,3])})
    try:
        from refraction.analysis import analyze
        r1 = analyze("bar", xl, {"xlabel": "Foo"})
        assert r1["x_label"] == "Foo"
        r2 = analyze("bar", xl, {"x_label": "Bar"})
        assert r2["x_label"] == "Bar"
    finally:
        os.unlink(xl)
run("analysis engine: xlabel/x_label aliases work", test_xlabel_alias)


# -------------------------------------------------------------------
# Final summary
# -------------------------------------------------------------------

_h.summarise()
sys.exit(0 if _h.FAIL == 0 else 1)
