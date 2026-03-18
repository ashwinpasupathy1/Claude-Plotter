"""Builds a Plotly figure spec for line graphs."""

import json
import pandas as pd
from plotter_plotly_theme import PRISM_TEMPLATE, PRISM_PALETTE


def build_line_spec(kw: dict) -> str:
    """Read Excel line data and return a Plotly figure as JSON string.

    Args:
        kw: The same kwargs dict passed to prism_linegraph().

    Returns:
        JSON string of a plotly.graph_objects.Figure.
    """
    import plotly.graph_objects as go

    excel_path = kw.get("excel_path", "")
    sheet = kw.get("sheet", 0)
    title = kw.get("title", "")
    xlabel = kw.get("xlabel", "")
    ytitle = kw.get("ytitle", "")

    try:
        df = pd.read_excel(excel_path, sheet_name=sheet, header=0)
    except Exception as e:
        return json.dumps({"error": str(e)})

    if df.shape[1] < 2:
        return json.dumps({"error": "Need at least 2 columns (X, Y1)"})

    x_col = df.columns[0]
    y_cols = df.columns[1:]
    x_vals = df[x_col].dropna().tolist()

    traces = []
    for i, col in enumerate(y_cols):
        y_vals = df[col].tolist()
        traces.append(go.Scatter(
            x=x_vals,
            y=y_vals,
            mode="lines+markers",
            name=str(col),
            line=dict(color=PRISM_PALETTE[i % len(PRISM_PALETTE)], width=2),
            marker=dict(size=6),
        ))

    fig = go.Figure(data=traces, layout=go.Layout(
        template=PRISM_TEMPLATE,
        title=dict(text=title),
        xaxis=dict(title=xlabel),
        yaxis=dict(title=ytitle),
    ))
    return fig.to_json()
