"""
test_api.py
===========
Tests for the FastAPI endpoints in plotter_server.py.

Starts the server in a background thread on port 7332 (avoiding conflicts
with the default 7331 production port), waits for it to become ready,
then exercises each endpoint.

Sections:
  - API: health
  - API: chart-types
  - API: wiki
  - API: render (bar chart)
  - API: render error handling
  - API: render-png (bar chart)
  - API: invalid chart type
  - API: spec endpoint

Run:
  python3 tests/test_api.py
  python3 run_all.py api
"""

import sys, os, json, time, urllib.request, urllib.error

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import plotter_test_harness as _h
from plotter_test_harness import run, section, summarise, bar_excel, simple_xy_excel
import numpy as np

# ─── Start the test server on a different port so we don't collide ────────────
_TEST_PORT = 7332
BASE = f"http://127.0.0.1:{_TEST_PORT}"

_server_started = False


def _start_test_server():
    """Launch the FastAPI server in a daemon thread on _TEST_PORT."""
    import threading

    def _run():
        try:
            import uvicorn
            from plotter_server import _make_app
            uvicorn.run(_make_app(), host="127.0.0.1", port=_TEST_PORT,
                        log_level="error", access_log=False)
        except Exception as exc:
            print(f"  [test_api] server thread exited: {exc}")

    t = threading.Thread(target=_run, daemon=True, name="test-api-server")
    t.start()
    # Wait up to 10 seconds for the server to become ready
    deadline = time.monotonic() + 10.0
    while time.monotonic() < deadline:
        try:
            urllib.request.urlopen(f"{BASE}/health", timeout=1)
            return True   # server is up
        except Exception:
            time.sleep(0.3)
    return False   # timed out


# Try to start. If uvicorn/fastapi are not installed the tests will fail
# with clear error messages rather than obscure import errors.
try:
    _server_started = _start_test_server()
except Exception as _exc:
    print(f"  [test_api] Could not start server: {_exc}")
    _server_started = False


def _get(path: str):
    """GET request; returns parsed JSON dict or raises."""
    resp = urllib.request.urlopen(f"{BASE}{path}", timeout=5)
    return json.loads(resp.read())


def _post(path: str, body: dict):
    """POST request with JSON body; returns parsed JSON dict or raises."""
    payload = json.dumps(body).encode()
    req = urllib.request.Request(
        f"{BASE}{path}",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    resp = urllib.request.urlopen(req, timeout=15)
    return json.loads(resp.read())


# ═════════════════════════════════════════════════════════════════════════════
# API: health
# ═════════════════════════════════════════════════════════════════════════════
section("API: health")


def test_health():
    if not _server_started:
        raise RuntimeError("Server did not start — check uvicorn/fastapi install")
    data = _get("/health")
    assert data.get("status") == "ok", f"Expected status='ok', got {data}"

run("GET /health returns {\"status\": \"ok\"}", test_health)


def test_health_returns_200():
    if not _server_started:
        raise RuntimeError("Server did not start")
    resp = urllib.request.urlopen(f"{BASE}/health", timeout=5)
    assert resp.status == 200, f"Expected HTTP 200, got {resp.status}"

run("GET /health returns HTTP 200", test_health_returns_200)


# ═════════════════════════════════════════════════════════════════════════════
# API: chart-types
# ═════════════════════════════════════════════════════════════════════════════
section("API: chart-types")


def test_chart_types_returns_list():
    if not _server_started:
        raise RuntimeError("Server did not start")
    data = _get("/chart-types")
    assert "chart_types" in data, f"Expected 'chart_types' key, got {list(data.keys())}"
    ct = data["chart_types"]
    assert isinstance(ct, list) and len(ct) > 0, "chart_types should be a non-empty list"

run("GET /chart-types returns chart list", test_chart_types_returns_list)


def test_chart_types_has_bar():
    if not _server_started:
        raise RuntimeError("Server did not start")
    data = _get("/chart-types")
    keys = [item["key"] for item in data["chart_types"]]
    assert "bar" in keys, f"'bar' not found in chart_types keys: {keys}"

run("GET /chart-types includes 'bar' chart type", test_chart_types_has_bar)


def test_chart_types_metadata_fields():
    if not _server_started:
        raise RuntimeError("Server did not start")
    data = _get("/chart-types")
    first = data["chart_types"][0]
    for field in ("key", "label", "group"):
        assert field in first, f"chart_types entry missing field '{field}': {first}"

run("GET /chart-types entries have key, label, group fields",
    test_chart_types_metadata_fields)


# ═════════════════════════════════════════════════════════════════════════════
# API: wiki
# ═════════════════════════════════════════════════════════════════════════════
section("API: wiki")


def test_wiki_returns_sections():
    if not _server_started:
        raise RuntimeError("Server did not start")
    data = _get("/wiki")
    assert data.get("ok") is True, f"Expected ok=true, got {data}"
    assert "sections" in data, f"Expected 'sections' key, got {list(data.keys())}"
    assert len(data["sections"]) > 0, "Wiki sections should be non-empty"

run("GET /wiki returns sections list", test_wiki_returns_sections)


def test_wiki_sections_count():
    if not _server_started:
        raise RuntimeError("Server did not start")
    data = _get("/wiki")
    # The wiki has 29 documented test sections per CLAUDE.md
    assert len(data["sections"]) >= 10, (
        f"Expected ≥10 wiki sections, got {len(data['sections'])}")

run("GET /wiki returns at least 10 sections", test_wiki_sections_count)


# ═════════════════════════════════════════════════════════════════════════════
# API: render (bar chart)
# ═════════════════════════════════════════════════════════════════════════════
section("API: render (bar chart)")


def test_render_bar_returns_spec():
    if not _server_started:
        raise RuntimeError("Server did not start")
    xl = bar_excel({"A": np.array([1, 2, 3]), "B": np.array([4, 5, 6])})
    try:
        data = _post("/render", {"chart_type": "bar", "kw": {"excel_path": xl}})
        assert data.get("ok") is True, f"Render failed: {data}"
        assert "spec" in data, f"Expected 'spec' key in response, got {list(data.keys())}"
    finally:
        os.unlink(xl)

run("POST /render (bar): returns Plotly spec with ok=true", test_render_bar_returns_spec)


def test_render_bar_spec_structure():
    if not _server_started:
        raise RuntimeError("Server did not start")
    xl = bar_excel({"Control": np.array([1, 2, 3]),
                    "Drug":    np.array([4, 5, 6])})
    try:
        data = _post("/render", {"chart_type": "bar", "kw": {"excel_path": xl}})
        spec = data["spec"]
        assert "data" in spec, f"Plotly spec missing 'data': {list(spec.keys())}"
        assert "layout" in spec, f"Plotly spec missing 'layout': {list(spec.keys())}"
    finally:
        os.unlink(xl)

run("POST /render (bar): spec has 'data' and 'layout' keys", test_render_bar_spec_structure)


def test_render_bar_two_traces():
    if not _server_started:
        raise RuntimeError("Server did not start")
    xl = bar_excel({"Control": np.array([1, 2, 3]),
                    "Drug":    np.array([4, 5, 6])})
    try:
        data = _post("/render", {"chart_type": "bar", "kw": {"excel_path": xl}})
        traces = data["spec"]["data"]
        assert len(traces) == 2, f"Expected 2 traces for 2 groups, got {len(traces)}"
    finally:
        os.unlink(xl)

run("POST /render (bar): 2 groups → 2 traces in spec", test_render_bar_two_traces)


# ═════════════════════════════════════════════════════════════════════════════
# API: render error handling
# ═════════════════════════════════════════════════════════════════════════════
section("API: render error handling")


def test_render_missing_excel_path():
    if not _server_started:
        raise RuntimeError("Server did not start")
    data = _post("/render", {"chart_type": "bar", "kw": {"excel_path": "/no/such/file.xlsx"}})
    # Should return ok=false with an error string, not crash the server
    assert data.get("ok") is False, (
        f"Expected ok=false for missing file, got {data}")
    assert "error" in data, f"Expected 'error' key, got {list(data.keys())}"

run("POST /render: missing file returns ok=false with error message",
    test_render_missing_excel_path)


def test_render_invalid_chart_type():
    if not _server_started:
        raise RuntimeError("Server did not start")
    xl = bar_excel({"A": np.array([1, 2, 3])})
    try:
        data = _post("/render", {"chart_type": "totally_fake_chart_xyz",
                                  "kw": {"excel_path": xl}})
        # Server should return a response (not crash); ok may be true or false
        # depending on how unknown types are handled, but must not 500-error
        assert isinstance(data, dict), f"Expected dict response, got {type(data)}"
    finally:
        os.unlink(xl)

run("POST /render: unknown chart type returns a dict response (no 500 crash)",
    test_render_invalid_chart_type)


# ═════════════════════════════════════════════════════════════════════════════
# API: render-png (bar chart)
# ═════════════════════════════════════════════════════════════════════════════
section("API: render-png")


def test_render_png_returns_b64():
    if not _server_started:
        raise RuntimeError("Server did not start")
    xl = bar_excel({"A": np.array([1, 2, 3]), "B": np.array([4, 5, 6])})
    try:
        data = _post("/render-png", {"chart_type": "bar", "kw": {"excel_path": xl}})
        assert data.get("ok") is True, f"render-png failed: {data}"
        assert "image" in data, f"Expected 'image' key in response"
        img = data["image"]
        assert img.startswith("data:image/png;base64,"), (
            f"Expected data-URI prefix, got {img[:50]!r}")
    finally:
        os.unlink(xl)

run("POST /render-png (bar): returns base64-encoded PNG data-URI",
    test_render_png_returns_b64)


def test_render_png_image_non_empty():
    if not _server_started:
        raise RuntimeError("Server did not start")
    xl = bar_excel({"G1": np.array([1, 2, 3])})
    try:
        data = _post("/render-png", {"chart_type": "bar", "kw": {"excel_path": xl}})
        if data.get("ok"):
            # Strip prefix and check that base64 payload is non-trivial
            b64 = data["image"].split(",", 1)[1]
            assert len(b64) > 1000, (
                f"PNG base64 payload too short ({len(b64)} chars) — likely empty image")
    finally:
        os.unlink(xl)

run("POST /render-png: PNG payload is non-trivially large (>1000 chars)",
    test_render_png_image_non_empty)


# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
summarise()
sys.exit(0 if _h.FAIL == 0 else 1)
