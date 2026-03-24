"""
test_api.py — pytest tests for FastAPI endpoints.

Covers: /health, /chart-types, /analyze, /upload.
"""

import os
import tempfile

import numpy as np
import pytest

from tests.conftest import (
    _bar_excel, _simple_xy_excel, _grouped_excel,
    _with_excel,
)

from refraction.server.api import _make_app

try:
    from starlette.testclient import TestClient
except ImportError:
    from fastapi.testclient import TestClient


@pytest.fixture(scope="module")
def client():
    app = _make_app()
    return TestClient(app, raise_server_exceptions=False)


# =========================================================================
# /health endpoint
# =========================================================================

class TestHealth:
    def test_returns_ok(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"


# =========================================================================
# /chart-types endpoint
# =========================================================================

class TestChartTypes:
    def test_returns_list(self, client):
        resp = client.get("/chart-types")
        assert resp.status_code == 200
        data = resp.json()
        assert "all" in data
        assert "priority" in data

    def test_has_analyzer_types(self, client):
        resp = client.get("/chart-types")
        data = resp.json()
        assert len(data["all"]) >= 8, (
            f"Expected >= 8 chart types, got {len(data['all'])}: {data['all']}"
        )

    def test_priority_subset(self, client):
        resp = client.get("/chart-types")
        data = resp.json()
        for ct in data["priority"]:
            assert ct in data["all"], f"Priority type {ct} not in 'all' list"


# =========================================================================
# /analyze — bar chart
# =========================================================================

class TestAnalyzeBar:
    def test_basic(self, client):
        with _with_excel(lambda p: _bar_excel(
                {"Control": np.array([1, 2, 3]), "Drug": np.array([4, 5, 6])}, path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "bar",
                "data_path": xl,
            })
            assert resp.status_code == 200
            data = resp.json()
            assert data["ok"] is True
            assert "spec" in data
            assert data["spec"]["chart_type"] == "bar"
            assert "data" in data["spec"]
            assert "axes" in data["spec"]
            assert "style" in data["spec"]

    def test_with_title(self, client):
        with _with_excel(lambda p: _bar_excel(
                {"A": np.array([10, 20, 30])}, path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "bar",
                "data_path": xl,
                "config": {"title": "Test Title"},
            })
            data = resp.json()
            assert data["ok"] is True
            assert data["spec"]["title"] == "Test Title"

    def test_group_count(self, client):
        with _with_excel(lambda p: _bar_excel(
                {"A": np.array([1, 2]), "B": np.array([3, 4]), "C": np.array([5, 6])},
                path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "bar",
                "data_path": xl,
            })
            data = resp.json()
            groups = data["spec"]["data"]["groups"]
            assert len(groups) == 3, f"Expected 3 groups, got {len(groups)}"


# =========================================================================
# /analyze — other chart types
# =========================================================================

class TestAnalyzeOther:
    def test_box(self, client):
        with _with_excel(lambda p: _bar_excel(
                {"G1": np.array([1, 2, 3, 4, 5]),
                 "G2": np.array([6, 7, 8, 9, 10])}, path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "box",
                "data_path": xl,
            })
            data = resp.json()
            assert data["ok"] is True

    def test_scatter(self, client):
        with _with_excel(lambda p: _simple_xy_excel(
                np.array([1, 2, 3, 4]), np.array([2, 4, 6, 8]), path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "scatter",
                "data_path": xl,
            })
            data = resp.json()
            assert data["ok"] is True

    def test_line(self, client):
        with _with_excel(lambda p: _simple_xy_excel(
                np.array([1, 2, 3, 4, 5]),
                np.array([10, 20, 30, 40, 50]), path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "line",
                "data_path": xl,
            })
            data = resp.json()
            assert data["ok"] is True

    def test_violin(self, client):
        with _with_excel(lambda p: _bar_excel(
                {"G1": np.random.default_rng(0).normal(5, 1, 20),
                 "G2": np.random.default_rng(0).normal(8, 1, 20)}, path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "violin",
                "data_path": xl,
            })
            data = resp.json()
            assert data["ok"] is True

    def test_histogram(self, client):
        with _with_excel(lambda p: _bar_excel(
                {"Data": np.random.default_rng(1).normal(0, 1, 50)}, path=p)) as xl:
            resp = client.post("/analyze", json={
                "chart_type": "histogram",
                "data_path": xl,
            })
            data = resp.json()
            assert data["ok"] is True


# =========================================================================
# /analyze — error handling
# =========================================================================

class TestAnalyzeErrors:
    def test_unknown_chart_type(self, client):
        resp = client.post("/analyze", json={
            "chart_type": "nonexistent_chart",
            "config": {},
        })
        data = resp.json()
        assert data["ok"] is False
        assert "error" in data


# =========================================================================
# /upload endpoint
# =========================================================================

class TestUpload:
    def test_xlsx(self, client):
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

    def test_unsupported_type(self, client):
        tmp = tempfile.NamedTemporaryFile(suffix=".txt", delete=False)
        tmp.write(b"hello")
        tmp.close()
        try:
            with open(tmp.name, "rb") as f:
                resp = client.post("/upload", files={"file": ("test.txt", f, "text/plain")})
            d = resp.json()
            assert d["ok"] is False
            assert "unsupported" in d.get("error", "").lower() or \
                   "Unsupported" in d.get("error", "")
        finally:
            os.unlink(tmp.name)
