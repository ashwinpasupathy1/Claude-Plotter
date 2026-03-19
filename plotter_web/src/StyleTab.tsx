import type { PlotKw } from './types.ts';

interface StyleTabProps {
  kw: PlotKw;
  onChange: (partial: Partial<PlotKw>) => void;
}

export default function StyleTab({ kw, onChange }: StyleTabProps) {
  return (
    <div className="panel-scroll">
      <div className="section-header">Line Style</div>
      <div className="slider-row">
        <label className="has-tooltip">
          Spine width
          <span className="tip">Thickness of the axis border lines (spines)</span>
        </label>
        <input
          type="range"
          min={2}
          max={30}
          value={Math.round(kw.spine_width * 10)}
          onChange={(e) => onChange({ spine_width: Number(e.target.value) / 10 })}
        />
        <span className="slider-val">{kw.spine_width.toFixed(1)}</span>
      </div>

      <div className="section-header">Background</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Fig background
          <span className="tip">Background colour of the entire figure area</span>
        </span>
        <input
          className="form-input"
          type="text"
          value={kw.fig_bg}
          onChange={(e) => onChange({ fig_bg: e.target.value })}
        />
      </div>

      <div className="section-header">Error Bars</div>
      <div className="slider-row">
        <label className="has-tooltip">
          Cap size
          <span className="tip">Width of the horizontal caps at the ends of error bars</span>
        </label>
        <input
          type="range"
          min={0}
          max={12}
          value={kw.cap_size}
          onChange={(e) => onChange({ cap_size: Number(e.target.value) })}
        />
        <span className="slider-val">{kw.cap_size} pt</span>
      </div>

      <div className="section-header">Reference Line</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Y value
          <span className="tip">Draw a horizontal reference line at this Y value</span>
        </span>
        <input
          className="form-input"
          type="number"
          value={kw.ref_line ?? ''}
          placeholder="none"
          onChange={(e) => {
            const val = e.target.value;
            onChange({ ref_line: val === '' ? null : Number(val) });
          }}
        />
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Label
          <span className="tip">Text label shown next to the reference line</span>
        </span>
        <input
          className="form-input"
          type="text"
          value={kw.ref_line_label}
          placeholder="e.g. Baseline"
          onChange={(e) => onChange({ ref_line_label: e.target.value })}
        />
      </div>
    </div>
  );
}
