import { useState } from 'react';
import type { PlotKw, TabName } from './types.ts';
import DataTab from './DataTab.tsx';
import AxesTab from './AxesTab.tsx';
import StyleTab from './StyleTab.tsx';
import StatsTab from './StatsTab.tsx';

const TABS: TabName[] = ['Data', 'Axes', 'Style', 'Stats'];

interface ControlPanelProps {
  kw: PlotKw;
  onChange: (partial: Partial<PlotKw>) => void;
  onOpenFile: () => void;
  sheets: string[];
}

export default function ControlPanel({ kw, onChange, onOpenFile, sheets }: ControlPanelProps) {
  const [activeTab, setActiveTab] = useState<TabName>('Data');

  return (
    <div className="control-panel">
      <div className="tab-bar">
        {TABS.map((tab) => (
          <div
            key={tab}
            className={`tab${activeTab === tab ? ' active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab}
          </div>
        ))}
      </div>
      {activeTab === 'Data' && (
        <DataTab kw={kw} onChange={onChange} onOpenFile={onOpenFile} sheets={sheets} />
      )}
      {activeTab === 'Axes' && <AxesTab kw={kw} onChange={onChange} />}
      {activeTab === 'Style' && <StyleTab kw={kw} onChange={onChange} />}
      {activeTab === 'Stats' && <StatsTab kw={kw} onChange={onChange} />}
    </div>
  );
}
