import { useCallback, useRef } from 'react';
import Toolbar from './Toolbar.tsx';
import { PlotterChart } from './PlotterChart.tsx';
import ResultsStrip from './ResultsStrip.tsx';
import type { PlotKw, StatsResult } from './types.ts';

interface ChartAreaProps {
  chartType: string;
  kw: PlotKw;
  renderTrigger: number;
  stats: StatsResult | null;
  onPlot: () => void;
  onReset: () => void;
  onExport: (format: string, width: number, height: number, dpi: number) => void;
  onHelpToggle: () => void;
  onStatsResult: (stats: StatsResult | null) => void;
  onLabelSync: (field: string, value: string) => void;
  onDrop: (path: string) => void;
  fileName: string;
  sheetName: string;
  isDragOver: boolean;
  onDragOver: () => void;
  onDragLeave: () => void;
}

export default function ChartArea({
  chartType,
  kw,
  renderTrigger,
  stats,
  onPlot,
  onReset,
  onExport,
  onHelpToggle,
  onStatsResult,
  onLabelSync,
  onDrop,
  fileName,
  sheetName,
  isDragOver,
  onDragOver,
  onDragLeave,
}: ChartAreaProps) {
  const chartAreaRef = useRef<HTMLDivElement>(null);

  const handleDragOver = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      onDragOver();
    },
    [onDragOver],
  );

  const handleDragLeave = useCallback(() => {
    onDragLeave();
  }, [onDragLeave]);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      onDragLeave();
      const files = e.dataTransfer.files;
      if (files.length > 0) {
        const file = files[0];
        // In pywebview context, we get the file path
        // In browser context, we use the File object name
        const path = (file as unknown as Record<string, string>).path || file.name;
        onDrop(path);
      }
    },
    [onDrop, onDragLeave],
  );

  const handleResultsToggle = useCallback(() => {
    // After toggle animation, resize Plotly chart
    setTimeout(() => {
      const plotDiv = chartAreaRef.current?.querySelector('.chart-plotly');
      if (plotDiv) {
        // Trigger a window resize event so Plotly recalculates layout
        window.dispatchEvent(new Event('resize'));
      }
    }, 320);
  }, []);

  return (
    <div
      className="chart-area"
      ref={chartAreaRef}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {isDragOver && (
        <div className="drop-overlay">Drop Excel or CSV file here</div>
      )}
      <Toolbar
        onPlot={onPlot}
        onReset={onReset}
        onExport={onExport}
        onHelpToggle={onHelpToggle}
        fileName={fileName}
        sheetName={sheetName}
      />
      <div className="chart-plot">
        <PlotterChart
          chartType={chartType}
          kw={kw}
          renderTrigger={renderTrigger}
          onStatsResult={onStatsResult}
          onLabelSync={onLabelSync}
        />
      </div>
      <ResultsStrip stats={stats} onToggle={handleResultsToggle} />
    </div>
  );
}
