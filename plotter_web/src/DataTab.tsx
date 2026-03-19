import type { PlotKw } from './types.ts';

interface DataTabProps {
  kw: PlotKw;
  onChange: (partial: Partial<PlotKw>) => void;
  onOpenFile: () => void;
  sheets: string[];
}

const PALETTES = ['Prism default', 'Pastel', 'Vibrant', 'Grayscale'];
const ERROR_TYPES = ['SEM', 'SD', '95% CI', 'None'];
const PRESETS = ['Prism Classic', 'Minimal', 'Dark', 'Publication'];
const DEFAULT_COLORS = ['#E8453C', '#2274A5', '#32936F'];

export default function DataTab({ kw, onChange, onOpenFile, sheets }: DataTabProps) {
  return (
    <div className="panel-scroll">
      {/* Data File */}
      <div className="section-header">Data File</div>
      <div className="file-row">
        <div className="file-input" title={kw.excel_path || 'No file selected'}>
          {kw.excel_path || 'No file selected'}
        </div>
        <button className="file-btn" onClick={onOpenFile}>Open&#8230;</button>
      </div>
      <div className="drop-hint">or drag &amp; drop an Excel / CSV file onto the window</div>

      <div className="form-row">
        <span className="form-label has-tooltip">
          Sheet
          <span className="tip">Which worksheet to read data from</span>
        </span>
        <select
          className="form-select"
          value={String(kw.sheet)}
          onChange={(e) => onChange({ sheet: e.target.value })}
        >
          {sheets.length > 0 ? (
            sheets.map((s) => <option key={s} value={s}>{s}</option>)
          ) : (
            <option value="0">Sheet1</option>
          )}
        </select>
      </div>

      {/* Appearance */}
      <div className="section-header">Appearance</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Palette
          <span className="tip">Colour set applied to groups in order</span>
        </span>
        <select
          className="form-select"
          value={kw.palette}
          onChange={(e) => onChange({ palette: e.target.value })}
        >
          {PALETTES.map((p) => <option key={p} value={p}>{p}</option>)}
        </select>
      </div>
      <div className="form-row">
        <span className="form-label">Group colours</span>
        {DEFAULT_COLORS.map((c) => (
          <div key={c} className="color-swatch" style={{ background: c }} />
        ))}
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Preset
          <span className="tip">Saved style configurations -- apply all style settings at once</span>
        </span>
        <select
          className="form-select"
          value={kw.preset}
          onChange={(e) => onChange({ preset: e.target.value })}
        >
          {PRESETS.map((p) => <option key={p} value={p}>{p}</option>)}
        </select>
      </div>

      {/* Error Bars */}
      <div className="section-header">Error Bars</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Error type
          <span className="tip">SEM = standard error of mean. SD = standard deviation. 95% CI = confidence interval.</span>
        </span>
        <select
          className="form-select"
          value={kw.error_type}
          onChange={(e) => onChange({ error_type: e.target.value })}
        >
          {ERROR_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
        </select>
      </div>

      {/* Data Points */}
      <div className="section-header">Data Points</div>
      <label className="checkbox-row">
        <input
          type="checkbox"
          checked={kw.show_points}
          onChange={(e) => onChange({ show_points: e.target.checked })}
        />
        <span className="has-tooltip">
          Show individual points
          <span className="tip">Overlay each raw data value as a dot on the bar</span>
        </span>
      </label>
      <label className="checkbox-row">
        <input
          type="checkbox"
          checked={kw.jitter}
          onChange={(e) => onChange({ jitter: e.target.checked })}
        />
        <span className="has-tooltip">
          Jitter
          <span className="tip">Spread points horizontally so overlapping values stay visible</span>
        </span>
      </label>
      <div className="slider-row">
        <label className="has-tooltip">
          Point size
          <span className="tip">Diameter of individual data point markers</span>
        </label>
        <input
          type="range"
          min={2}
          max={12}
          value={kw.point_size}
          onChange={(e) => onChange({ point_size: Number(e.target.value) })}
        />
        <span className="slider-val">{kw.point_size} pt</span>
      </div>
      <div className="slider-row">
        <label className="has-tooltip">
          Opacity
          <span className="tip">Transparency of data point markers (lower = more transparent)</span>
        </label>
        <input
          type="range"
          min={10}
          max={100}
          value={Math.round(kw.point_alpha * 100)}
          onChange={(e) => onChange({ point_alpha: Number(e.target.value) / 100 })}
        />
        <span className="slider-val">{Math.round(kw.point_alpha * 100)}%</span>
      </div>

      {/* Labels */}
      <div className="section-header">Labels</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Title
          <span className="tip">Chart title displayed above the plot</span>
        </span>
        <input
          className="form-input"
          type="text"
          value={kw.title}
          onChange={(e) => onChange({ title: e.target.value })}
        />
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          X label
          <span className="tip">Label for the horizontal axis</span>
        </span>
        <input
          className="form-input"
          type="text"
          value={kw.xlabel}
          onChange={(e) => onChange({ xlabel: e.target.value })}
        />
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Y label
          <span className="tip">Label for the vertical axis</span>
        </span>
        <input
          className="form-input"
          type="text"
          value={kw.ytitle}
          onChange={(e) => onChange({ ytitle: e.target.value })}
        />
      </div>
    </div>
  );
}
