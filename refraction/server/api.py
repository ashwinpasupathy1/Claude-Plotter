"""FastAPI server for Refraction — serves renderer-agnostic ChartSpec
via the /analyze endpoint. The SwiftUI frontend consumes these specs
and renders them natively."""

import logging
import os
import tempfile
import threading
import uuid
from typing import Any, Optional

_log = logging.getLogger(__name__)

_server_thread: Optional[threading.Thread] = None
_PORT = 7331


def get_port() -> int:
    return _PORT


def start_server() -> None:
    """Start the FastAPI server in a background daemon thread."""
    global _server_thread
    if _server_thread and _server_thread.is_alive():
        return  # Already running

    def _run():
        import uvicorn
        uvicorn.run(_make_app(), host="127.0.0.1", port=_PORT,
                    log_level="warning", access_log=False)

    _server_thread = threading.Thread(target=_run, daemon=True, name="refraction-server")
    _server_thread.start()


def _make_app():
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
    from fastapi import Request
    from pydantic import BaseModel

    API_KEY = os.environ.get("REFRACTION_API_KEY", "")

    api = FastAPI(title="Refraction API", version="2.0.0")

    api.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @api.middleware("http")
    async def check_auth(request: Request, call_next):
        """Require API key for non-local requests (if REFRACTION_API_KEY is set)."""
        client_ip = request.client.host if request.client else ""
        if client_ip in ("127.0.0.1", "localhost", "::1"):
            return await call_next(request)
        if API_KEY and request.headers.get("x-api-key") != API_KEY:
            return JSONResponse({"error": "Unauthorized"}, status_code=401)
        return await call_next(request)

    @api.get("/health")
    def health():
        return {"status": "ok"}

    @api.get("/chart-types")
    def chart_types():
        """List available chart types."""
        from refraction.analysis.engine import available_chart_types
        all_types = available_chart_types()
        return {
            "priority": ["bar", "grouped_bar", "line", "scatter"],
            "all": all_types,
        }

    class AnalyzeRequest(BaseModel):
        chart_type: str
        config: dict[str, Any] = {}
        data_path: str = ""

    @api.post("/analyze")
    def analyze_chart(req: AnalyzeRequest):
        """Accept chart config, return renderer-agnostic ChartSpec."""
        try:
            from refraction.analysis import analyze
            data_path = req.data_path or req.config.get("excel_path", "")
            kw = dict(req.config)
            kw["excel_path"] = data_path
            spec = analyze(req.chart_type, kw)
            return {"ok": True, "spec": spec.to_dict()}
        except Exception as e:
            _log.exception("Analyze failed for chart_type=%s", req.chart_type)
            return JSONResponse({"ok": False, "error": str(e)}, status_code=500)

    # ── File upload ──────────────────────────────────────────────
    from fastapi import UploadFile, File as FastAPIFile

    UPLOAD_DIR = os.path.join(tempfile.gettempdir(), "refraction-uploads")
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    @api.post("/upload")
    async def upload_file(file: UploadFile = FastAPIFile(...)):
        """Accept .xlsx/.xls/.csv upload; return server-side path."""
        ext = os.path.splitext(file.filename or "")[1].lower()
        if ext not in (".xlsx", ".xls", ".csv"):
            return JSONResponse(
                {"ok": False, "error": f"Unsupported file type: {ext}"},
                status_code=400,
            )
        contents = await file.read()
        if len(contents) > 10 * 1024 * 1024:  # 10 MB limit
            return JSONResponse(
                {"ok": False, "error": "File too large (max 10 MB)"},
                status_code=413,
            )
        safe_name = f"{uuid.uuid4().hex}{ext}"
        dest = os.path.join(UPLOAD_DIR, safe_name)
        with open(dest, "wb") as f:
            f.write(contents)
        return {"ok": True, "path": dest, "filename": file.filename}

    return api
