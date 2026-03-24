"""
test_api.py
===========
FastAPI endpoint tests for the Refraction API.

Covers: /health, /chart-types, /analyze, /upload.

Uses TestClient from starlette.testclient.

Run:
  python3 -m pytest tests/test_api.py  (or via run_all.py)
"""

import sys, os, json, tempfile
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import plotter_test_harness as _h
from plotter_test_harness import (
    ok, fail, run, section, summarise,
    bar_excel, simple_xy_excel, grouped_excel,
    km_excel, heatmap_excel, contingency_excel,
    bland_altman_excel, forest_excel, chi_gof_excel,
    with_excel,
)

# -- Import FastAPI app and test client ----------------------------------------
from refraction.server.api import _make_app

try:
    from starlette.testclient import TestClient
except ImportError:
    from fastapi.testclient import TestClient

app = _make_app()
client = TestClient(app, raise_server_exceptions=False)

# ==============================================================================
# 1. Health endpoint
# ==============================================================================
section("API -- /health endpoint")

def test_health_returns_ok():
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"

run("/health: returns 200 and status=ok", test_health_returns_ok)


# ==============================================================================
# 2. Chart-types endpoint
# ==============================================================================
section("API -- /chart-types endpoint")

def test_chart_types_returns_list():
    resp = client.get("/chart-types")
    assert resp.status_code == 200
    data = resp.json()
    assert "all" in data
    assert "priority" in data

run("/chart-types: returns 200 with all + priority", test_chart_types_returns_list)

def test_chart_types_has_29_entries():
    resp = client.get("/chart-types")
    data = resp.json()
    assert len(data["all"]) == 29, f"Expected 29, got {len(data['all'])}"

run("/chart-types: 29 chart types listed", test_chart_types_has_29_entries)

def test_chart_types_priority_subset():
    resp = client.get("/chart-types")
    data = resp.json()
    for ct in data["priority"]:
        assert ct in data["all"], f"Priority type {ct} not in 'all' list"

run("/chart-types: priority types are subset of all", test_chart_types_priority_subset)


# ==============================================================================
# 3. /analyze -- bar chart
# ==============================================================================
section("API -- /analyze bar chart")

def test_analyze_bar_basic():
    with with_excel(lambda p: bar_excel(
            {"Control": np.array([1, 2, 3]), "Drug": np.array([4, 5, 6])}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "bar",
            "excel_path": xl,
        })
        assert resp.status_code == 200
        data = resp.json()
        assert data["ok"] is True
        assert "groups" in data
        assert len(data["groups"]) == 2

run("/analyze bar: returns groups with descriptive stats", test_analyze_bar_basic)

def test_analyze_bar_with_title():
    with with_excel(lambda p: bar_excel(
            {"A": np.array([10, 20, 30])}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "bar",
            "excel_path": xl,
            "config": {"title": "Test Title"},
        })
        data = resp.json()
        assert data["ok"] is True
        assert data["title"] == "Test Title"

run("/analyze bar: title passed through", test_analyze_bar_with_title)

def test_analyze_bar_group_count():
    with with_excel(lambda p: bar_excel(
            {"A": np.array([1, 2]), "B": np.array([3, 4]), "C": np.array([5, 6])},
            path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "bar",
            "excel_path": xl,
        })
        data = resp.json()
        assert len(data["groups"]) == 3, \
            f"Expected 3 groups, got {len(data['groups'])}"

run("/analyze bar: 3 groups returned", test_analyze_bar_group_count)

def test_analyze_bar_mean_correct():
    with with_excel(lambda p: bar_excel(
            {"A": np.array([10, 20, 30])}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "bar",
            "excel_path": xl,
        })
        data = resp.json()
        assert abs(data["groups"][0]["mean"] - 20.0) < 0.01

run("/analyze bar: mean is correct", test_analyze_bar_mean_correct)


# ==============================================================================
# 4. /analyze -- with stats
# ==============================================================================
section("API -- /analyze with statistics")

def test_analyze_bar_with_stats():
    with with_excel(lambda p: bar_excel(
            {"Control": np.array([1, 2, 3, 4, 5]),
             "Drug": np.array([6, 7, 8, 9, 10])}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "bar",
            "excel_path": xl,
            "config": {"stats_test": "parametric"},
        })
        data = resp.json()
        assert data["ok"] is True
        assert len(data["comparisons"]) >= 1
        assert "p_value" in data["comparisons"][0]
        assert "stars" in data["comparisons"][0]

run("/analyze bar+stats: returns comparisons", test_analyze_bar_with_stats)


# ==============================================================================
# 5. /analyze -- distribution charts
# ==============================================================================
section("API -- /analyze distribution charts")

def test_analyze_violin():
    with with_excel(lambda p: bar_excel(
            {"G1": np.random.default_rng(0).normal(5, 1, 20),
             "G2": np.random.default_rng(0).normal(8, 1, 20)}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "violin",
            "excel_path": xl,
        })
        d = resp.json()
        assert d["ok"] is True, f"violin analyze failed: {d}"

run("/analyze violin: returns ok", test_analyze_violin)

def test_analyze_box():
    with with_excel(lambda p: bar_excel(
            {"G1": np.array([1, 2, 3, 4, 5]),
             "G2": np.array([6, 7, 8, 9, 10])}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "box",
            "excel_path": xl,
        })
        d = resp.json()
        assert d["ok"] is True, f"box analyze failed: {d}"

run("/analyze box: returns ok", test_analyze_box)

def test_analyze_histogram():
    with with_excel(lambda p: bar_excel(
            {"Data": np.random.default_rng(1).normal(0, 1, 50)}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "histogram",
            "excel_path": xl,
        })
        d = resp.json()
        assert d["ok"] is True, f"histogram analyze failed: {d}"

run("/analyze histogram: returns ok", test_analyze_histogram)


# ==============================================================================
# 6. /analyze -- error handling
# ==============================================================================
section("API -- /analyze error handling")

def test_analyze_missing_file():
    resp = client.post("/analyze", json={
        "chart_type": "bar",
        "excel_path": "/nonexistent/file.xlsx",
    })
    d = resp.json()
    assert d["ok"] is False
    assert "error" in d

run("/analyze missing file: returns error", test_analyze_missing_file)


# ==============================================================================
# 7. /upload endpoint
# ==============================================================================
section("API -- /upload endpoint")

def test_upload_xlsx():
    import openpyxl
    tmp = tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False)
    tmp.close()
    try:
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.append(["A", "B"])
        ws.append([1, 4])
        ws.append([2, 5])
        wb.save(tmp.name)

        with open(tmp.name, "rb") as f:
            resp = client.post("/upload", files={"file": ("test.xlsx", f,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")})
        d = resp.json()
        assert d["ok"] is True, f"Upload failed: {d}"
        assert "path" in d
        assert os.path.exists(d["path"])
        os.unlink(d["path"])
    finally:
        os.unlink(tmp.name)

run("/upload: .xlsx file accepted and stored", test_upload_xlsx)

def test_upload_unsupported_type():
    tmp = tempfile.NamedTemporaryFile(suffix=".txt", delete=False)
    tmp.write(b"hello")
    tmp.close()
    try:
        with open(tmp.name, "rb") as f:
            resp = client.post("/upload", files={"file": ("test.txt", f, "text/plain")})
        d = resp.json()
        assert d["ok"] is False
        assert "unsupported" in d.get("error", "").lower() or "Unsupported" in d.get("error", "")
    finally:
        os.unlink(tmp.name)

run("/upload: .txt file rejected", test_upload_unsupported_type)


# ==============================================================================
# 8. /analyze -- SEM accuracy
# ==============================================================================
section("API -- /analyze SEM accuracy")

def test_analyze_sem_matches_scipy():
    from scipy import stats as scipy_stats
    vals_a = np.array([2.0, 4.0, 6.0, 8.0, 10.0])
    vals_b = np.array([1.0, 3.0, 5.0, 7.0, 9.0])
    expected_sem_a = scipy_stats.sem(vals_a)
    expected_sem_b = scipy_stats.sem(vals_b)

    with with_excel(lambda p: bar_excel({"A": vals_a, "B": vals_b}, path=p)) as xl:
        resp = client.post("/analyze", json={
            "chart_type": "bar",
            "excel_path": xl,
            "config": {"error_type": "sem"},
        })
        data = resp.json()
        actual_sem_a = data["groups"][0]["sem"]
        actual_sem_b = data["groups"][1]["sem"]
        assert abs(actual_sem_a - expected_sem_a) < 1e-10, \
            f"SEM mismatch: got {actual_sem_a}, expected {expected_sem_a}"
        assert abs(actual_sem_b - expected_sem_b) < 1e-10, \
            f"SEM mismatch: got {actual_sem_b}, expected {expected_sem_b}"

run("/analyze bar: SEM matches scipy.stats.sem", test_analyze_sem_matches_scipy)


# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
summarise()
sys.exit(0 if _h.FAIL == 0 else 1)
