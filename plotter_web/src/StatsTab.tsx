import { useState } from 'react';
import type { PlotKw } from './types.ts';

interface StatsTabProps {
  kw: PlotKw;
  onChange: (partial: Partial<PlotKw>) => void;
}

const TEST_TYPES = [
  { value: 'parametric', label: 'Parametric' },
  { value: 'nonparametric', label: 'Non-parametric' },
  { value: 'permutation', label: 'Permutation' },
];

const POSTHOC_TESTS = [
  { value: 'tukey', label: 'Tukey HSD' },
  { value: 'bonferroni', label: 'Bonferroni' },
  { value: 'sidak', label: 'Sidak' },
  { value: 'fisher', label: 'Fisher LSD' },
  { value: 'dunnett', label: 'Dunnett' },
];

const CORRECTIONS = [
  { value: 'holm', label: 'Holm' },
  { value: 'fdr_bh', label: 'BH FDR' },
  { value: 'bonferroni', label: 'Bonferroni' },
  { value: 'none', label: 'None' },
];

export default function StatsTab({ kw, onChange }: StatsTabProps) {
  const [showAdvanced, setShowAdvanced] = useState(false);

  return (
    <div className="panel-scroll">
      <div className="section-header">Statistical Test</div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Test type
          <span className="tip">Parametric tests assume normal distribution; non-parametric tests do not</span>
        </span>
        <select
          className="form-select"
          value={kw.stats_test}
          onChange={(e) => onChange({ stats_test: e.target.value })}
        >
          {TEST_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
        </select>
      </div>
      <div className="form-row">
        <span className="form-label has-tooltip">
          Post-hoc
          <span className="tip">Pairwise comparison method applied after a significant omnibus test</span>
        </span>
        <select
          className="form-select"
          value={kw.posthoc}
          onChange={(e) => onChange({ posthoc: e.target.value })}
        >
          {POSTHOC_TESTS.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
        </select>
      </div>

      <div className="section-header">Display</div>
      <label className="checkbox-row">
        <input
          type="checkbox"
          checked={kw.show_brackets}
          onChange={(e) => onChange({ show_brackets: e.target.checked })}
        />
        <span className="has-tooltip">
          Show significance brackets
          <span className="tip">Draw horizontal brackets connecting compared groups with significance stars</span>
        </span>
      </label>
      <label className="checkbox-row">
        <input
          type="checkbox"
          checked={kw.show_pvalues}
          onChange={(e) => onChange({ show_pvalues: e.target.checked })}
        />
        <span className="has-tooltip">
          Show p-values
          <span className="tip">Display exact p-values instead of or alongside significance stars</span>
        </span>
      </label>

      {/* Advanced collapsible */}
      <div
        className="advanced-toggle"
        onClick={() => setShowAdvanced(!showAdvanced)}
      >
        <span>{showAdvanced ? '\u25BE' : '\u25B8'}</span>
        <span>Advanced</span>
      </div>
      <div className={`advanced-body${showAdvanced ? ' open' : ''}`}>
        <div className="form-row">
          <span className="form-label has-tooltip">
            Correction
            <span className="tip">Method to adjust p-values for multiple comparisons</span>
          </span>
          <select
            className="form-select"
            value={kw.correction}
            onChange={(e) => onChange({ correction: e.target.value })}
          >
            {CORRECTIONS.map((c) => <option key={c.value} value={c.value}>{c.label}</option>)}
          </select>
        </div>
        <div className="form-row">
          <span className="form-label has-tooltip">
            Control group
            <span className="tip">Reference group for Dunnett test (compare all others vs this group)</span>
          </span>
          <input
            className="form-input"
            type="text"
            value={kw.control_group}
            placeholder="e.g. Control"
            onChange={(e) => onChange({ control_group: e.target.value })}
          />
        </div>
        <div className="form-row">
          <span className="form-label has-tooltip">
            Permutations
            <span className="tip">Number of random permutations for permutation tests (higher = more accurate but slower)</span>
          </span>
          <input
            className="form-input"
            type="number"
            value={kw.permutations}
            onChange={(e) => onChange({ permutations: Number(e.target.value) })}
          />
        </div>
        <div className="form-row">
          <span className="form-label has-tooltip">
            Alpha level
            <span className="tip">Significance threshold (typically 0.05). Results with p less than alpha are considered significant.</span>
          </span>
          <input
            className="form-input"
            type="number"
            step={0.01}
            min={0.001}
            max={0.5}
            value={kw.alpha}
            onChange={(e) => onChange({ alpha: Number(e.target.value) })}
          />
        </div>
      </div>
    </div>
  );
}
