"""Analysis engine — dispatches chart type to the correct analyzer.

Usage:
    from refraction.analysis import analyze
    spec = analyze("bar", kw)
"""

from __future__ import annotations

from typing import Callable

from refraction.analysis.schema import ChartSpec

# Lazy imports — each analyzer is imported only when first requested.
_ANALYZERS: dict[str, Callable[[dict], ChartSpec]] = {}


def _ensure_analyzers() -> None:
    """Populate _ANALYZERS on first call (lazy to avoid circular imports)."""
    if _ANALYZERS:
        return

    from refraction.analysis.bar import analyze_bar
    from refraction.analysis.box import analyze_box
    from refraction.analysis.scatter import analyze_scatter
    from refraction.analysis.line import analyze_line
    from refraction.analysis.grouped_bar import analyze_grouped_bar
    from refraction.analysis.violin import analyze_violin
    from refraction.analysis.histogram import analyze_histogram
    from refraction.analysis.before_after import analyze_before_after

    _ANALYZERS.update({
        "bar": analyze_bar,
        "box": analyze_box,
        "scatter": analyze_scatter,
        "line": analyze_line,
        "grouped_bar": analyze_grouped_bar,
        "violin": analyze_violin,
        "histogram": analyze_histogram,
        "before_after": analyze_before_after,
    })


def analyze(chart_type: str, kw_or_path=None, config: dict | None = None) -> ChartSpec:
    """Analyze data for *chart_type* and return a ChartSpec.

    Args:
        chart_type: Registry key (e.g. "bar", "box", "scatter").
        kw_or_path: Either a dict of kwargs, or a string path to an Excel file.
            If a string is given, it is wrapped into {"excel_path": path}.
        config: Optional extra config to merge (only used when kw_or_path is a path).

    Returns:
        A fully populated ChartSpec instance.

    Raises:
        ValueError: If *chart_type* is not registered.
    """
    _ensure_analyzers()
    if chart_type not in _ANALYZERS:
        raise ValueError(
            f"Unknown chart type {chart_type!r}. "
            f"Available: {sorted(_ANALYZERS)}"
        )

    # Normalize input: accept both dict and plain path string
    if isinstance(kw_or_path, str):
        kw: dict = {"excel_path": kw_or_path}
        if config:
            kw.update(config)
    elif kw_or_path is None:
        kw = config or {}
    else:
        kw = dict(kw_or_path)
        if config:
            kw.update(config)

    return _ANALYZERS[chart_type](kw)


def available_chart_types() -> list[str]:
    """Return sorted list of registered chart type keys."""
    _ensure_analyzers()
    return sorted(_ANALYZERS.keys())
