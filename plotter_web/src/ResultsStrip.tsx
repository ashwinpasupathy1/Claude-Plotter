import { useState, useCallback } from 'react';
import type { StatsResult } from './types.ts';

interface ResultsStripProps {
  stats: StatsResult | null;
  onToggle: () => void;
}

export default function ResultsStrip({ stats, onToggle }: ResultsStripProps) {
  const [isOpen, setIsOpen] = useState(false);

  const toggle = useCallback(() => {
    setIsOpen((prev) => !prev);
    onToggle();
  }, [onToggle]);

  const summaryText = stats?.test_name
    ? `${stats.test_name}${stats.p_value !== undefined ? ` \u00B7 p=${stats.p_value.toFixed(4)}` : ''}`
    : 'No results';

  return (
    <div className="results-wrapper">
      <div className="results-toggle" onClick={toggle}>
        <span className={`arrow${isOpen ? ' open' : ''}`}>{'\u25BC'}</span>
        <span>Statistical Results</span>
        <span className="results-summary">{summaryText}</span>
      </div>
      <div className={`results-strip${isOpen ? ' open' : ''}`}>
        {stats ? (
          <>
            {stats.statistic && (
              <div className="result-item">
                {stats.test_name}: <span>{stats.statistic}</span>
              </div>
            )}
            {stats.pairwise && stats.pairwise.length > 0 && (
              <div className="result-item">
                {stats.pairwise.map((pw, i) => (
                  <span key={i}>
                    {pw.group1} vs {pw.group2}{' '}
                    <span className={`stat-badge${pw.p_value < 0.05 ? ' sig' : ' ns'}`}>
                      p = {pw.p_value.toFixed(4)} {pw.significance}
                    </span>
                    {' '}
                  </span>
                ))}
              </div>
            )}
            {stats.summary && (
              <div className="result-item">{stats.summary}</div>
            )}
          </>
        ) : (
          <div className="result-item">Run a plot with statistics enabled to see results here.</div>
        )}
      </div>
    </div>
  );
}
