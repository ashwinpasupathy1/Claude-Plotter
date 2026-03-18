"""Builds a Plotly figure spec for grouped bar charts."""

import json
import pandas as pd
from plotter_plotly_theme import PRISM_TEMPLATE, PRISM_PALETTE


def build_grouped_bar_spec(kw: dict) -> str:
    """Read Excel grouped bar data and return a Plotly figure as JSON string.

    Args:
        kw: The same kwargs dict passed to prism_grouped_barplot().

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
        df = pd.read_excel(excel_path, sheet_name=sheet, header=[0, 1])
    except Exception as e:
        return json.dumps({"error": str(e)})

    # df has a MultiIndex column: (category, subgroup)
    categories = df.columns.get_level_values(0).unique().tolist()
    subgroups = df.columns.get_level_values(1).unique().tolist()

    traces = []
    for j, sg in enumerate(subgroups):
        y_vals = []
        for cat in categories:
            try:
                col_data = df[(cat, sg)].dropna()
                y_vals.append(col_data.mean() if len(col_data) > 0 else 0)
            except KeyError:
                y_vals.append(0)
        traces.append(go.Bar(
            name=sg,
            x=categories,
            y=y_vals,
            marker_color=PRISM_PALETTE[j % len(PRISM_PALETTE)],
        ))

    fig = go.Figure(data=traces, layout=go.Layout(
        template=PRISM_TEMPLATE,
        barmode="group",
        title=dict(text=title),
        xaxis=dict(title=xlabel),
        yaxis=dict(title=ytitle),
    ))
    return fig.to_json()
