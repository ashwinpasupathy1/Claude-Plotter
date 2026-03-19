import { useState, useCallback } from 'react';

interface ToolbarProps {
  onPlot: () => void;
  onReset: () => void;
  onExport: (format: string, width: number, height: number, dpi: number) => void;
  onHelpToggle: () => void;
  fileName: string;
  sheetName: string;
}

export default function Toolbar({ onPlot, onReset, onExport, onHelpToggle, fileName, sheetName }: ToolbarProps) {
  const [showExport, setShowExport] = useState(false);
  const [exportFormat, setExportFormat] = useState('PNG');
  const [exportWidth, setExportWidth] = useState(5);
  const [exportHeight, setExportHeight] = useState(5);
  const [exportDpi, setExportDpi] = useState(300);

  const handleDownload = useCallback(() => {
    onExport(exportFormat, exportWidth, exportHeight, exportDpi);
  }, [onExport, exportFormat, exportWidth, exportHeight, exportDpi]);

  const fileLabel = fileName
    ? `${fileName}${sheetName ? ` \u00B7 ${sheetName}` : ''}`
    : 'No file loaded';

  return (
    <>
      <div className="chart-toolbar">
        <button className="toolbar-btn primary has-tooltip" onClick={onPlot}>
          &#9654; Plot
          <span className="tip">Generate chart from current data and settings</span>
        </button>
        <div className="toolbar-sep" />
        <button className="toolbar-btn has-tooltip" onClick={onReset}>
          &#8634; Reset
          <span className="tip">Reset all parameters to defaults</span>
        </button>
        <button
          className="toolbar-btn has-tooltip"
          onClick={() => setShowExport(!showExport)}
        >
          &#10515; Export
          <span className="tip">Export chart as image file</span>
        </button>
        <div className="toolbar-sep" />
        <span className="toolbar-spacer" />
        <span className="toolbar-file-label">{fileLabel}</span>
        <div className="toolbar-sep" />
        <button className="toolbar-btn has-tooltip" onClick={onHelpToggle}>
          Help Analyze
          <span className="tip">Open the statistical methods reference panel</span>
        </button>
      </div>

      {showExport && (
        <div className="export-panel">
          <span className="export-label">Format:</span>
          <select
            className="export-select"
            value={exportFormat}
            onChange={(e) => setExportFormat(e.target.value)}
          >
            <option>PNG</option>
            <option>SVG</option>
            <option>PDF</option>
          </select>
          <span className="export-label">Width:</span>
          <input
            type="number"
            className="export-num"
            value={exportWidth}
            onChange={(e) => setExportWidth(Number(e.target.value))}
          />
          <span className="export-unit">in</span>
          <span className="export-label">Height:</span>
          <input
            type="number"
            className="export-num"
            value={exportHeight}
            onChange={(e) => setExportHeight(Number(e.target.value))}
          />
          <span className="export-unit">in</span>
          <span className="export-label">DPI:</span>
          <select
            className="export-select"
            value={exportDpi}
            onChange={(e) => setExportDpi(Number(e.target.value))}
          >
            <option value={72}>72</option>
            <option value={150}>150</option>
            <option value={300}>300</option>
          </select>
          <button className="export-download-btn" onClick={handleDownload}>Download</button>
          <button className="export-close-btn" onClick={() => setShowExport(false)}>&#10005;</button>
        </div>
      )}
    </>
  );
}
