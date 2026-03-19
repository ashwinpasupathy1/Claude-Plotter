"""FastAPI server for Claude Plotter — serves Plotly chart specs
and receives edit events from the pywebview frontend."""

import json
import os
import threading
from typing import Any, Optional

_server_thread: Optional[threading.Thread] = None
_app_ref = None  # reference to the App instance, set during startup
_PORT = 7331


def get_port() -> int:
    return _PORT


def start_server(app_instance=None) -> None:
    """Start the FastAPI server in a background daemon thread."""
    global _server_thread, _app_ref
    if _server_thread and _server_thread.is_alive():
        return  # Already running

    _app_ref = app_instance

    def _run():
        import uvicorn
        uvicorn.run(_make_app(), host="127.0.0.1", port=_PORT,
                    log_level="warning", access_log=False)

    _server_thread = threading.Thread(target=_run, daemon=True, name="plotter-server")
    _server_thread.start()


CHART_FN_MAP = {
    "bar":                "plotter_barplot",
    "line":               "plotter_linegraph",
    "grouped_bar":        "plotter_grouped_barplot",
    "box":                "plotter_boxplot",
    "scatter":            "plotter_scatterplot",
    "violin":             "plotter_violin",
    "kaplan_meier":       "plotter_kaplan_meier",
    "heatmap":            "plotter_heatmap",
    "two_way_anova":      "plotter_two_way_anova",
    "before_after":       "plotter_before_after",
    "histogram":          "plotter_histogram",
    "subcolumn_scatter":  "plotter_subcolumn_scatter",
    "curve_fit":          "plotter_curve_fit",
    "column_stats":       "plotter_column_stats",
    "contingency":        "plotter_contingency",
    "repeated_measures":  "plotter_repeated_measures",
    "chi_square_gof":     "plotter_chi_square_gof",
    "stacked_bar":        "plotter_stacked_bar",
    "bubble":             "plotter_bubble",
    "dot_plot":           "plotter_dot_plot",
    "bland_altman":       "plotter_bland_altman",
    "forest_plot":        "plotter_forest_plot",
    "area_chart":         "plotter_area_chart",
    "raincloud":          "plotter_raincloud",
    "qq_plot":            "plotter_qq_plot",
    "lollipop":           "plotter_lollipop",
    "waterfall":          "plotter_waterfall",
    "pyramid":            "plotter_pyramid",
    "ecdf":               "plotter_ecdf",
}

_CHART_TYPE_METADATA = [
    # Column group
    {"key": "bar",               "label": "Bar Chart",         "group": "Column",       "has_plotly_spec": True,  "description": "Compare means across independent groups"},
    {"key": "box",               "label": "Box Plot",          "group": "Column",       "has_plotly_spec": False, "description": "Show distribution via quartiles and outliers"},
    {"key": "violin",            "label": "Violin Plot",       "group": "Column",       "has_plotly_spec": False, "description": "Show distribution shape with kernel density"},
    {"key": "dot_plot",          "label": "Dot Plot",          "group": "Column",       "has_plotly_spec": False, "description": "Plot individual data points by group"},
    {"key": "subcolumn_scatter", "label": "Subcolumn",         "group": "Column",       "has_plotly_spec": False, "description": "Scatter points within subcolumns"},
    {"key": "before_after",      "label": "Before / After",    "group": "Column",       "has_plotly_spec": False, "description": "Show paired measurements before and after treatment"},
    {"key": "repeated_measures", "label": "Repeated Meas.",    "group": "Column",       "has_plotly_spec": False, "description": "Visualise repeated measures within subjects"},
    # XY group
    {"key": "scatter",           "label": "Scatter Plot",      "group": "XY",           "has_plotly_spec": True,  "description": "Plot two continuous variables against each other"},
    {"key": "line",              "label": "Line Graph",        "group": "XY",           "has_plotly_spec": True,  "description": "Connect data points with lines over a numeric X axis"},
    {"key": "curve_fit",         "label": "Curve Fit",         "group": "XY",           "has_plotly_spec": False, "description": "Fit a regression or custom curve to XY data"},
    {"key": "area_chart",        "label": "Area Chart",        "group": "XY",           "has_plotly_spec": False, "description": "Filled area under a line series"},
    {"key": "bubble",            "label": "Bubble Chart",      "group": "XY",           "has_plotly_spec": False, "description": "Scatter plot with bubble size encoding a third variable"},
    {"key": "bland_altman",      "label": "Bland-Altman",      "group": "XY",           "has_plotly_spec": False, "description": "Compare two measurement methods via difference plot"},
    # Grouped group
    {"key": "grouped_bar",       "label": "Grouped Bar",       "group": "Grouped",      "has_plotly_spec": True,  "description": "Compare groups across multiple categories side by side"},
    {"key": "stacked_bar",       "label": "Stacked Bar",       "group": "Grouped",      "has_plotly_spec": False, "description": "Show part-to-whole relationships across categories"},
    {"key": "two_way_anova",     "label": "Two-Way ANOVA",     "group": "Grouped",      "has_plotly_spec": False, "description": "Analyse interactions between two categorical factors"},
    # Distribution group
    {"key": "histogram",         "label": "Histogram",         "group": "Distribution", "has_plotly_spec": False, "description": "Show frequency distribution of a single variable"},
    {"key": "ecdf",              "label": "ECDF",              "group": "Distribution", "has_plotly_spec": False, "description": "Empirical cumulative distribution function"},
    {"key": "qq_plot",           "label": "Q-Q Plot",          "group": "Distribution", "has_plotly_spec": False, "description": "Check normality via quantile-quantile plot"},
    {"key": "column_stats",      "label": "Col Statistics",    "group": "Distribution", "has_plotly_spec": False, "description": "Summary statistics table for column data"},
    # Survival group
    {"key": "kaplan_meier",      "label": "Survival Curve",    "group": "Survival",     "has_plotly_spec": False, "description": "Kaplan-Meier survival analysis with log-rank test"},
    # Correlation group
    {"key": "heatmap",           "label": "Heatmap",           "group": "Correlation",  "has_plotly_spec": False, "description": "Colour-encoded matrix for pairwise or tabular data"},
    {"key": "forest_plot",       "label": "Forest Plot",       "group": "Correlation",  "has_plotly_spec": False, "description": "Meta-analysis effect sizes with confidence intervals"},
    {"key": "contingency",       "label": "Contingency",       "group": "Correlation",  "has_plotly_spec": False, "description": "Visualise contingency table and chi-square test"},
    {"key": "chi_square_gof",    "label": "Chi-Sq GoF",        "group": "Correlation",  "has_plotly_spec": False, "description": "Chi-square goodness-of-fit test bar chart"},
    # Other group
    {"key": "waterfall",         "label": "Waterfall",         "group": "Other",        "has_plotly_spec": False, "description": "Sequential cumulative changes from a starting value"},
    {"key": "lollipop",          "label": "Lollipop",          "group": "Other",        "has_plotly_spec": False, "description": "Dot-and-stem variant of a bar chart"},
    {"key": "pyramid",           "label": "Pyramid",           "group": "Other",        "has_plotly_spec": False, "description": "Back-to-back bar chart for comparing two series"},
    {"key": "raincloud",         "label": "Raincloud",         "group": "Other",        "has_plotly_spec": False, "description": "Combined half-violin, box plot, and jitter plot"},
]


def _make_app():
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
    from pydantic import BaseModel

    class RenderRequest(BaseModel):
        chart_type: str
        kw: dict[str, Any]

    class EventRequest(BaseModel):
        event: str
        value: Any = None
        extra: dict[str, Any] = {}

    from fastapi.responses import JSONResponse
    from fastapi import Request

    API_KEY = os.environ.get("PLOTTER_API_KEY", "")

    api = FastAPI(title="Claude Plotter API", version="1.0.0")

    api.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @api.middleware("http")
    async def check_auth(request: Request, call_next):
        """Require API key for non-local requests (if PLOTTER_API_KEY is set)."""
        host = request.headers.get("host", "")
        if host.startswith("127.0.0.1") or host.startswith("localhost"):
            return await call_next(request)
        if API_KEY and request.headers.get("x-api-key") != API_KEY:
            return JSONResponse({"error": "Unauthorized"}, status_code=401)
        return await call_next(request)

    @api.post("/render")
    def render(req: RenderRequest):
        """Accept chart kwargs, return Plotly JSON."""
        try:
            spec_json = _build_spec(req.chart_type, req.kw)
            spec = json.loads(spec_json)
            # Spec builders embed errors rather than raising — surface them properly
            if "error" in spec and len(spec) == 1:
                return {"ok": False, "error": spec["error"]}
            return {"ok": True, "spec": spec}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    @api.post("/render-png")
    def render_png(req: RenderRequest):
        """Render a chart via matplotlib and return a base64-encoded PNG."""
        try:
            image_b64 = _build_png(req.chart_type, req.kw)
            return {"ok": True, "image": image_b64}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    @api.post("/event")
    def handle_event(req: EventRequest):
        """Receive edit events from the frontend (e.g. title changed)."""
        try:
            _dispatch_event(req.event, req.value, req.extra)
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    @api.post("/spec")
    def get_spec(req: RenderRequest):
        """Return raw Plotly JSON spec without rendering."""
        try:
            spec_json = _build_spec(req.chart_type, req.kw)
            return {"ok": True, "spec_json": spec_json}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    @api.get("/chart-types")
    def chart_types():
        """List available chart types with rich metadata."""
        return {"chart_types": _CHART_TYPE_METADATA}

    @api.get("/wiki")
    def wiki():
        """Return statistical methods wiki content."""
        try:
            from plotter_wiki_content import WIKI_SECTIONS
            sections = []
            for sec in WIKI_SECTIONS:
                sections.append({
                    "title": sec.get("title", ""),
                    "content": sec,
                    "tags": sec.get("tags", []),
                })
            return {"ok": True, "sections": sections}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    @api.get("/health")
    def health():
        return {"status": "ok"}

    # Serve React SPA static files if the build exists
    from fastapi.staticfiles import StaticFiles
    web_dist = os.path.join(os.path.dirname(__file__), "plotter_web", "dist")
    if os.path.isdir(web_dist):
        api.mount("/", StaticFiles(directory=web_dist, html=True), name="static")

    return api


def _build_spec(chart_type: str, kw: dict) -> str:
    """Route to the correct spec builder."""
    if chart_type == "bar":
        from plotter_spec_bar import build_bar_spec
        return build_bar_spec(kw)
    elif chart_type == "grouped_bar":
        from plotter_spec_grouped_bar import build_grouped_bar_spec
        return build_grouped_bar_spec(kw)
    elif chart_type == "line":
        from plotter_spec_line import build_line_spec
        return build_line_spec(kw)
    elif chart_type == "scatter":
        from plotter_spec_scatter import build_scatter_spec
        return build_scatter_spec(kw)
    else:
        return json.dumps({"error": f"Unknown chart type: {chart_type}"})


def _build_png(chart_type: str, kw: dict) -> str:
    """Render a chart via matplotlib and return a data-URI base64 PNG string."""
    import inspect
    import base64
    from io import BytesIO
    import plotter_functions as pf

    fn_name = CHART_FN_MAP.get(chart_type)
    if fn_name is None:
        raise ValueError(f"Unknown chart type: {chart_type!r}")

    fn = getattr(pf, fn_name, None)
    if fn is None:
        raise AttributeError(f"plotter_functions has no function {fn_name!r}")

    # Filter kw to only keys the function actually accepts
    sig = inspect.signature(fn)
    accepted = set(sig.parameters)
    filtered_kw = {k: v for k, v in kw.items() if k in accepted}

    fig, _ax = fn(**filtered_kw)

    buf = BytesIO()
    fig.savefig(buf, format="png", dpi=144, bbox_inches="tight")
    buf.seek(0)
    b64 = base64.b64encode(buf.read()).decode("ascii")

    try:
        import matplotlib.pyplot as plt
        plt.close(fig)
    except Exception:
        pass

    return f"data:image/png;base64,{b64}"


def _dispatch_event(event: str, value: Any, extra: dict) -> None:
    """Dispatch a frontend edit event back to the App form state."""
    if _app_ref is None:
        return
    app = _app_ref

    # Title changed in chart
    if event == "title_changed":
        _set_var(app, "title", value)

    # X-axis label changed
    elif event == "xlabel_changed":
        _set_var(app, "xlabel", value)

    # Y-axis label changed
    elif event == "ytitle_changed":
        _set_var(app, "ytitle", value)

    # Bar recolored
    elif event == "bar_recolored":
        # extra = {"group_index": int, "color": "#rrggbb"}
        pass  # Color sync TBD in Phase 3 polish

    # Y-axis range changed via drag
    elif event == "yrange_changed":
        # extra = {"ymin": float, "ymax": float}
        _set_var(app, "ymin", str(extra.get("ymin", "")))
        _set_var(app, "ymax", str(extra.get("ymax", "")))


def _set_var(app, key: str, value: str) -> None:
    """Safely set a tkinter StringVar on the main thread."""
    try:
        var = app._vars.get(key)
        if var is not None:
            app.after(0, lambda: var.set(value))
    except Exception:
        pass
