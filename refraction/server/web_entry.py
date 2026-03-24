#!/usr/bin/env python3
"""Refraction -- API server entry point.

Starts the FastAPI server that exposes /analyze, /upload, /health,
and /chart-types.

Usage:
    python3 -m refraction.server.web_entry [--port PORT] [--host HOST]
    REFRACTION_API_KEY=secret python3 -m refraction.server.web_entry

Environment variables:
    REFRACTION_API_KEY  -- API key for non-local requests (optional)
    PORT                -- Server port (default: 7331)
    HOST                -- Bind address (default: 0.0.0.0)
"""

import os
import argparse


def main():
    parser = argparse.ArgumentParser(description="Refraction API Server")
    parser.add_argument("--port", type=int,
                        default=int(os.environ.get("PORT", 7331)))
    parser.add_argument("--host",
                        default=os.environ.get("HOST", "0.0.0.0"))
    parser.add_argument("--reload", action="store_true",
                        help="Enable hot reload")
    args = parser.parse_args()

    print(f"Refraction API Server")
    print(f"Listening on http://{args.host}:{args.port}")
    if os.environ.get("REFRACTION_API_KEY"):
        print("API key authentication enabled")

    import uvicorn
    from refraction.server.api import _make_app
    uvicorn.run(
        _make_app(),
        host=args.host,
        port=args.port,
        reload=args.reload,
        log_level="info",
    )


if __name__ == "__main__":
    main()
