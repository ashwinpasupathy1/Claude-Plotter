import { useState, useEffect, useRef, useCallback } from 'react';
import { API_BASE } from './types.ts';
import type { WikiSection } from './types.ts';

interface HelpPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function HelpPanel({ isOpen, onClose }: HelpPanelProps) {
  const [sections, setSections] = useState<WikiSection[]>([]);
  const [loading, setLoading] = useState(false);
  const bodyRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isOpen && sections.length === 0) {
      setLoading(true);
      fetch(`${API_BASE}/wiki`)
        .then((r) => r.json())
        .then((data) => {
          if (data.sections) {
            setSections(data.sections);
          }
        })
        .catch(() => {
          // If wiki endpoint not available, show placeholder sections
          setSections([
            { title: 'One-Way ANOVA', content: '<p>Tests whether the means of three or more independent groups differ significantly. Assumes each group is normally distributed with equal variance.</p><p><strong>When to use:</strong> You have one categorical independent variable with 3+ levels and one continuous outcome.</p>' },
            { title: 't-test', content: '<p>Compares the means of two groups. The independent t-test is for two separate groups; the paired t-test is for repeated measures on the same subjects.</p>' },
            { title: 'Tukey HSD', content: '<p>Post-hoc test for pairwise comparisons after a significant ANOVA. Controls the family-wise error rate.</p>' },
            { title: 'Mann-Whitney U', content: '<p>Non-parametric alternative to the independent t-test. Compares two independent groups when normality assumptions are violated.</p>' },
            { title: 'Kruskal-Wallis', content: '<p>Non-parametric alternative to one-way ANOVA. Tests whether samples originate from the same distribution.</p>' },
            { title: 'Log-rank Test', content: '<p>Compares survival curves between two or more groups. Used with Kaplan-Meier analysis.</p>' },
            { title: 'Chi-square Test', content: '<p>Tests the association between two categorical variables. Compares observed vs expected frequencies.</p>' },
            { title: 'Effect Sizes', content: '<p>Quantifies the magnitude of a difference or relationship. Common measures include Cohen\'s d, eta-squared, and odds ratios.</p>' },
          ]);
        })
        .finally(() => setLoading(false));
    }
  }, [isOpen, sections.length]);

  const scrollToSection = useCallback((title: string) => {
    if (!bodyRef.current) return;
    const el = bodyRef.current.querySelector(`[data-section="${title}"]`);
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }, []);

  return (
    <div className={`help-panel${isOpen ? ' open' : ''}`}>
      <div className="help-header">
        <h3>Statistical Methods Reference</h3>
        <span className="help-close" onClick={onClose}>{'\u2715'}</span>
      </div>
      <div className="help-nav">
        {sections.map((s) => (
          <span key={s.title} className="help-tag" onClick={() => scrollToSection(s.title)}>
            {s.title}
          </span>
        ))}
      </div>
      <div className="help-body" ref={bodyRef}>
        {loading && <p>Loading...</p>}
        {sections.map((s) => (
          <div key={s.title} data-section={s.title}>
            <h4>{s.title}</h4>
            <div dangerouslySetInnerHTML={{ __html: s.content }} />
          </div>
        ))}
      </div>
    </div>
  );
}
