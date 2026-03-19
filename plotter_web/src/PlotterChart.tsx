import { useEffect, useRef, useState, useCallback } from 'react';
import Plotly from 'plotly.js-dist-min';
import type { PlotlyHTMLElement } from 'plotly.js-dist-min';
import { API_BASE } from './types.ts';
import type { PlotKw, StatsResult, BracketData } from './types.ts';

// Chart types that have native Plotly spec builders on the server
const PLOTLY_CHART_TYPES = new Set(['bar', 'grouped_bar', 'line', 'scatter']);

interface ChartProps {
  chartType: string;
  kw: PlotKw;
  renderTrigger: number;
  onStatsResult?: (stats: StatsResult | null) => void;
  onLabelSync?: (field: string, value: string) => void;
}

function addBrackets(
  layout: Record<string, unknown>,
  brackets: BracketData[],
  numGroups: number,
) {
  if (!brackets || brackets.length === 0) return;

  const shapes: Record<string, unknown>[] = (layout.shapes as Record<string, unknown>[]) || [];
  const annotations: Record<string, unknown>[] = (layout.annotations as Record<string, unknown>[]) || [];
  const ls = { color: '#444', width: 1.4 };
  const tick = 2.5;

  for (const b of brackets) {
    // Convert group indices to paper-x positions
    const paperX0 = (b.x0 + 0.5) / numGroups;
    const paperX1 = (b.x1 + 0.5) / numGroups;

    // Horizontal bar
    shapes.push({ type: 'line', x0: paperX0, x1: paperX1, y0: b.y, y1: b.y, xref: 'paper', yref: 'y', line: ls });
    // Left tick
    shapes.push({ type: 'line', x0: paperX0, x1: paperX0, y0: b.y, y1: b.y - tick, xref: 'paper', yref: 'y', line: ls });
    // Right tick
    shapes.push({ type: 'line', x0: paperX1, x1: paperX1, y0: b.y, y1: b.y - tick, xref: 'paper', yref: 'y', line: ls });
    // Text above
    annotations.push({
      x: (paperX0 + paperX1) / 2,
      y: b.y + 1.8,
      xref: 'paper',
      yref: 'y',
      text: b.text,
      showarrow: false,
      font: { size: 13, color: '#333', family: 'Arial' },
    });
  }

  layout.shapes = shapes;
  layout.annotations = annotations;
}

export function PlotterChart({ chartType, kw, renderTrigger, onStatsResult, onLabelSync }: ChartProps) {
  const plotDivRef = useRef<HTMLDivElement>(null);
  const imgRef = useRef<HTMLImageElement>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [pngSrc, setPngSrc] = useState<string | null>(null);
  const isPlotly = PLOTLY_CHART_TYPES.has(chartType);

  const postEvent = useCallback(
    (event: string, value: unknown) => {
      fetch(`${API_BASE}/event`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ event, value, extra: {} }),
      }).catch(() => {});
      if (onLabelSync) {
        if (event === 'title_changed') onLabelSync('title', String(value));
        if (event === 'xlabel_changed') onLabelSync('xlabel', String(value));
        if (event === 'ytitle_changed') onLabelSync('ytitle', String(value));
      }
    },
    [onLabelSync],
  );

  useEffect(() => {
    if (!kw.excel_path) {
      // No file loaded — show nothing / clear
      setPngSrc(null);
      setError(null);
      return;
    }

    setLoading(true);
    setError(null);
    setPngSrc(null);

    const endpoint = isPlotly ? '/render' : '/render-png';
    fetch(`${API_BASE}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chart_type: chartType, kw }),
    })
      .then((r) => r.json())
      .then((data) => {
        if (!data.ok) {
          setError(data.error ?? 'Unknown error');
          onStatsResult?.(null);
          return;
        }

        // Stats results
        if (data.stats) {
          onStatsResult?.(data.stats as StatsResult);
        } else {
          onStatsResult?.(null);
        }

        if (isPlotly && data.spec && plotDivRef.current) {
          const spec = data.spec;

          // Add significance brackets if present
          if (data.brackets) {
            const numGroups = Array.isArray(spec.data) ? spec.data.filter((d: Record<string, unknown>) => d.type === 'bar').length : 3;
            addBrackets(spec.layout, data.brackets as BracketData[], numGroups);
          }

          Plotly.newPlot(plotDivRef.current, spec.data, spec.layout, {
            responsive: true,
            displayModeBar: true,
            editable: true,
          });

          // Wire edit events for bidirectional sync
          const div = plotDivRef.current as unknown as PlotlyHTMLElement;
          div.on('plotly_relayout', (update: Record<string, unknown>) => {
            if (update['title.text'] !== undefined)
              postEvent('title_changed', update['title.text']);
            if (update['xaxis.title.text'] !== undefined)
              postEvent('xlabel_changed', update['xaxis.title.text']);
            if (update['yaxis.title.text'] !== undefined)
              postEvent('ytitle_changed', update['yaxis.title.text']);
          });
        } else if (data.image) {
          // PNG fallback
          setPngSrc(data.image);
        }
      })
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [chartType, renderTrigger]);

  // Resize Plotly when container changes
  const resizePlotly = useCallback(() => {
    if (plotDivRef.current && isPlotly) {
      Plotly.react(plotDivRef.current, [], {});
    }
  }, [isPlotly]);

  useEffect(() => {
    const observer = new ResizeObserver(() => {
      if (plotDivRef.current && isPlotly) {
        // Use Plots.resize from the global
        const el = plotDivRef.current;
        if ((el as unknown as Record<string, unknown>).data) {
          resizePlotly();
        }
      }
    });
    if (plotDivRef.current) observer.observe(plotDivRef.current);
    return () => observer.disconnect();
  }, [isPlotly, resizePlotly]);

  if (loading) {
    return <div className="chart-loading">Rendering chart...</div>;
  }

  if (error) {
    return <div className="chart-error">Error: {error}</div>;
  }

  if (!kw.excel_path) {
    return (
      <div className="chart-placeholder">
        <div className="placeholder-icon">
          <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
            <rect x="8" y="18" width="12" height="38" fill="#2274A5" opacity="0.3" rx="2"/>
            <rect x="26" y="8" width="12" height="48" fill="#2274A5" opacity="0.5" rx="2"/>
            <rect x="44" y="28" width="12" height="28" fill="#2274A5" opacity="0.3" rx="2"/>
            <line x1="4" y1="56" x2="60" y2="56" stroke="#2274A5" strokeWidth="2"/>
          </svg>
        </div>
        <div className="placeholder-title">Spectra</div>
        <div className="placeholder-text">Open an Excel or CSV file to get started</div>
      </div>
    );
  }

  if (pngSrc) {
    return (
      <div className="chart-png-container">
        <img ref={imgRef} src={pngSrc} alt="Chart" className="chart-png" />
      </div>
    );
  }

  return <div ref={plotDivRef} className="chart-plotly" />;
}
