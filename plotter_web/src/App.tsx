import { useState, useCallback } from 'react';
import Sidebar from './Sidebar.tsx';
import ChartArea from './ChartArea.tsx';
import ControlPanel from './ControlPanel.tsx';
import HelpPanel from './HelpPanel.tsx';
import { DEFAULT_KW } from './types.ts';
import type { PlotKw, StatsResult } from './types.ts';
import './App.css';

declare global {
  interface Window {
    pywebview?: {
      api?: {
        open_file?: () => Promise<string | null>;
      };
    };
  }
}

export default function App() {
  const [chartType, setChartType] = useState('bar');
  const [kw, setKw] = useState<PlotKw>({ ...DEFAULT_KW });
  const [renderTrigger, setRenderTrigger] = useState(0);
  const [stats, setStats] = useState<StatsResult | null>(null);
  const [helpOpen, setHelpOpen] = useState(false);
  const [isDragOver, setIsDragOver] = useState(false);
  const [sheets, setSheets] = useState<string[]>([]);

  const updateKw = useCallback((partial: Partial<PlotKw>) => {
    setKw((prev) => ({ ...prev, ...partial }));
  }, []);

  const handlePlot = useCallback(() => {
    setRenderTrigger((n) => n + 1);
  }, []);

  const handleReset = useCallback(() => {
    setKw({ ...DEFAULT_KW, excel_path: kw.excel_path, sheet: kw.sheet });
  }, [kw.excel_path, kw.sheet]);

  const handleExport = useCallback(
    (_format: string, _width: number, _height: number, _dpi: number) => {
      // Export will be handled by the server in future
      // For now, use Plotly's built-in export from the modebar
    },
    [],
  );

  const handleOpenFile = useCallback(async () => {
    try {
      const path = await window.pywebview?.api?.open_file?.();
      if (path) {
        updateKw({ excel_path: path });
        // Attempt to fetch sheet names
        fetch(`http://127.0.0.1:7331/sheets?path=${encodeURIComponent(path)}`)
          .then((r) => r.json())
          .then((data) => {
            if (data.sheets) setSheets(data.sheets as string[]);
          })
          .catch(() => {});
      }
    } catch {
      // pywebview not available (running in browser)
    }
  }, [updateKw]);

  const handleDrop = useCallback(
    (path: string) => {
      updateKw({ excel_path: path });
    },
    [updateKw],
  );

  const handleLabelSync = useCallback(
    (field: string, value: string) => {
      updateKw({ [field]: value });
    },
    [updateKw],
  );

  const fileName = kw.excel_path
    ? kw.excel_path.split('/').pop() || kw.excel_path
    : '';

  const sheetName = typeof kw.sheet === 'string' ? kw.sheet : sheets[Number(kw.sheet)] || '';

  return (
    <div className="app-root">
      <div className="app-body">
        <Sidebar activeChart={chartType} onSelectChart={setChartType} />
        <div className="main-content">
          <ChartArea
            chartType={chartType}
            kw={kw}
            renderTrigger={renderTrigger}
            stats={stats}
            onPlot={handlePlot}
            onReset={handleReset}
            onExport={handleExport}
            onHelpToggle={() => setHelpOpen((o) => !o)}
            onStatsResult={setStats}
            onLabelSync={handleLabelSync}
            onDrop={handleDrop}
            fileName={fileName}
            sheetName={sheetName}
            isDragOver={isDragOver}
            onDragOver={() => setIsDragOver(true)}
            onDragLeave={() => setIsDragOver(false)}
          />
          <ControlPanel
            kw={kw}
            onChange={updateKw}
            onOpenFile={handleOpenFile}
            sheets={sheets}
          />
        </div>
        <HelpPanel isOpen={helpOpen} onClose={() => setHelpOpen(false)} />
      </div>
    </div>
  );
}
