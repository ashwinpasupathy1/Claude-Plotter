import type { PlotKw } from './types.ts';

interface AxesTabProps {
  kw: PlotKw;
  onChange: (partial: Partial<PlotKw>) => void;
}

const Y_SCALES = [
  { value: 'linear', label: 'Linear' },
  { value: 'log', label: 'Log10' },
];

const AXIS_STYLES = [
  { value: 'open', label: 'Open (Prism default)' },
  { value: 'closed', label: 'Closed box' },
  { value: 'floating', label: 'Floating' },
  { value: 'none', label: 'None' },
];

const TICK_DIRS = [
  { value: 'out', label: 'Outward' },
  { value: 'in', label: 'Inward' },
  { value: 'inout', label: 'Both' },
  { value: '', label: 'None' },
];

export default function AxesTab({ kw, onChange }: AxesTabProps) {
  const yMin = kw.ylim ? kw.ylim[0] : '';
  const yMax = kw.ylim ? kw.ylim[1] : '';

  const setYLim = (min: string, max: string) => {
    if (min === '' && max === '') {
      onChange({ ylim: null });
    } else {
      onChange({ ylim: [Number(min) || 0, Number(max) || 0] });
    }
  };

  return (
    <div className="panel-scroll">
      <div className="section-header">Y Axis</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Y scale
          <span className="tip">Linear or logarithmic (base 10) scale for the Y axis</span>
        </span>
        <select
          className="form-select"
          value={kw.yscale}
          onChange={(e) => onChange({ yscale: e.target.value })}
        >
          {Y_SCALES.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
        </select>
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Y min
          <span className="tip">Minimum value for the Y axis (leave blank for auto)</span>
        </span>
        <input
          className="form-input"
          type="number"
          value={yMin}
          placeholder="auto"
          onChange={(e) => setYLim(e.target.value, String(yMax))}
        />
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Y max
          <span className="tip">Maximum value for the Y axis (leave blank for auto)</span>
        </span>
        <input
          className="form-input"
          type="number"
          value={yMax}
          placeholder="auto"
          onChange={(e) => setYLim(String(yMin), e.target.value)}
        />
      </div>

      <div className="section-header">Typography</div>
      <div className="slider-row">
        <label className="has-tooltip">
          Font size
          <span className="tip">Base font size for axis labels, titles, and tick marks</span>
        </label>
        <input
          type="range"
          min={8}
          max={18}
          step={0.5}
          value={kw.font_size}
          onChange={(e) => onChange({ font_size: Number(e.target.value) })}
        />
        <span className="slider-val">{kw.font_size}pt</span>
      </div>

      <div className="section-header">Bars</div>
      <div className="slider-row">
        <label className="has-tooltip">
          Bar width
          <span className="tip">Width of each bar relative to the available space (0.2 = thin, 0.9 = wide)</span>
        </label>
        <input
          type="range"
          min={20}
          max={90}
          value={Math.round(kw.bar_width * 100)}
          onChange={(e) => onChange({ bar_width: Number(e.target.value) / 100 })}
        />
        <span className="slider-val">{kw.bar_width.toFixed(2)}</span>
      </div>

      <div className="section-header">Axis Style</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Axis style
          <span className="tip">Controls which plot borders (spines) are visible</span>
        </span>
        <select
          className="form-select"
          value={kw.axis_style}
          onChange={(e) => onChange({ axis_style: e.target.value })}
        >
          {AXIS_STYLES.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
        </select>
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Tick direction
          <span className="tip">Direction that tick marks point relative to the axis line</span>
        </span>
        <select
          className="form-select"
          value={kw.tick_dir}
          onChange={(e) => onChange({ tick_dir: e.target.value })}
        >
          {TICK_DIRS.map((d) => <option key={d.value} value={d.value}>{d.label}</option>)}
        </select>
      </div>
      <label className="checkbox-row">
        <input
          type="checkbox"
          checked={kw.minor_ticks}
          onChange={(e) => onChange({ minor_ticks: e.target.checked })}
        />
        <span className="has-tooltip">
          Minor ticks
          <span className="tip">Show smaller tick marks between major ticks</span>
        </span>
      </label>
      <label className="checkbox-row">
        <input
          type="checkbox"
          checked={kw.gridlines}
          onChange={(e) => onChange({ gridlines: e.target.checked })}
        />
        <span className="has-tooltip">
          Gridlines
          <span className="tip">Show horizontal reference lines across the plot area</span>
        </span>
      </label>
    </div>
  );
}
