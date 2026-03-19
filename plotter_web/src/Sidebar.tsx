import type { ChartTypeInfo } from './types.ts';

// ── SVG icon components for all 29 chart types ──

function BarIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="7" width="5" height="13" fill="#E8453C" rx="1"/>
      <rect x="10" y="3" width="5" height="17" fill="#2274A5" rx="1"/>
      <rect x="19" y="10" width="5" height="10" fill="#32936F" rx="1"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1.2"/>
    </svg>
  );
}

function BoxIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="3" y="6" width="7" height="10" fill="none" stroke="#E8453C" strokeWidth="1.4" rx="1"/>
      <line x1="3" y1="11" x2="10" y2="11" stroke="#E8453C" strokeWidth="1.4"/>
      <line x1="6.5" y1="2" x2="6.5" y2="6" stroke="#E8453C" strokeWidth="1.2"/>
      <line x1="6.5" y1="16" x2="6.5" y2="20" stroke="#E8453C" strokeWidth="1.2"/>
      <rect x="15" y="4" width="7" height="13" fill="none" stroke="#2274A5" strokeWidth="1.4" rx="1"/>
      <line x1="15" y1="10" x2="22" y2="10" stroke="#2274A5" strokeWidth="1.4"/>
      <line x1="18.5" y1="1" x2="18.5" y2="4" stroke="#2274A5" strokeWidth="1.2"/>
      <line x1="18.5" y1="17" x2="18.5" y2="20" stroke="#2274A5" strokeWidth="1.2"/>
    </svg>
  );
}

function ViolinIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <ellipse cx="7" cy="11" rx="3.5" ry="8.5" fill="#E8453C" opacity="0.25" stroke="#E8453C" strokeWidth="1.2"/>
      <ellipse cx="7" cy="11" rx="2" ry="4" fill="#E8453C" opacity="0.65"/>
      <ellipse cx="19" cy="11" rx="3.5" ry="8.5" fill="#2274A5" opacity="0.25" stroke="#2274A5" strokeWidth="1.2"/>
      <ellipse cx="19" cy="11" rx="2" ry="5" fill="#2274A5" opacity="0.65"/>
    </svg>
  );
}

function DotPlotIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <circle cx="5" cy="8" r="1.8" fill="#E8453C"/><circle cx="5" cy="12" r="1.8" fill="#E8453C"/>
      <circle cx="5" cy="16" r="1.8" fill="#E8453C"/><circle cx="13" cy="6" r="1.8" fill="#2274A5"/>
      <circle cx="13" cy="11" r="1.8" fill="#2274A5"/><circle cx="13" cy="17" r="1.8" fill="#2274A5"/>
      <line x1="5" y1="6" x2="5" y2="18" stroke="#E8453C" strokeWidth="1"/>
      <line x1="13" y1="4" x2="13" y2="19" stroke="#2274A5" strokeWidth="1"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function SubcolumnIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <circle cx="4" cy="14" r="1.6" fill="#E8453C"/><circle cx="6" cy="10" r="1.6" fill="#E8453C"/>
      <circle cx="5" cy="17" r="1.6" fill="#E8453C"/>
      <circle cx="14" cy="8" r="1.6" fill="#2274A5"/><circle cx="16" cy="12" r="1.6" fill="#2274A5"/>
      <circle cx="15" cy="5" r="1.6" fill="#2274A5"/>
      <circle cx="22" cy="15" r="1.6" fill="#32936F"/><circle cx="24" cy="11" r="1.6" fill="#32936F"/>
      <line x1="3" y1="13" x2="7" y2="13" stroke="#E8453C" strokeWidth="1.2"/>
      <line x1="13" y1="8" x2="17" y2="8" stroke="#2274A5" strokeWidth="1.2"/>
      <line x1="21" y1="13" x2="25" y2="13" stroke="#32936F" strokeWidth="1.2"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function BeforeAfterIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <circle cx="5" cy="17" r="1.8" fill="#E8453C"/><circle cx="5" cy="8" r="1.8" fill="#2274A5"/>
      <circle cx="14" cy="13" r="1.8" fill="#E8453C"/><circle cx="14" cy="5" r="1.8" fill="#2274A5"/>
      <circle cx="21" cy="16" r="1.8" fill="#E8453C"/><circle cx="21" cy="9" r="1.8" fill="#2274A5"/>
      <line x1="5" y1="17" x2="5" y2="8" stroke="#888" strokeWidth="0.8" strokeDasharray="2,1.5"/>
      <line x1="14" y1="13" x2="14" y2="5" stroke="#888" strokeWidth="0.8" strokeDasharray="2,1.5"/>
      <line x1="21" y1="16" x2="21" y2="9" stroke="#888" strokeWidth="0.8" strokeDasharray="2,1.5"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function RepeatedMeasuresIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <polyline points="2,16 8,10 14,12 20,5 24,7" fill="none" stroke="#E8453C" strokeWidth="1.5"/>
      <polyline points="2,18 8,14 14,15 20,9 24,11" fill="none" stroke="#2274A5" strokeWidth="1.5"/>
      <circle cx="2" cy="16" r="1.5" fill="#E8453C"/><circle cx="8" cy="10" r="1.5" fill="#E8453C"/>
      <circle cx="14" cy="12" r="1.5" fill="#E8453C"/><circle cx="20" cy="5" r="1.5" fill="#E8453C"/>
      <circle cx="2" cy="18" r="1.5" fill="#2274A5"/><circle cx="8" cy="14" r="1.5" fill="#2274A5"/>
      <circle cx="14" cy="15" r="1.5" fill="#2274A5"/><circle cx="20" cy="9" r="1.5" fill="#2274A5"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function ScatterIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <circle cx="4" cy="17" r="1.8" fill="#E8453C"/><circle cx="9" cy="13" r="1.8" fill="#E8453C"/>
      <circle cx="13" cy="8" r="1.8" fill="#E8453C"/><circle cx="18" cy="10" r="1.8" fill="#2274A5"/>
      <circle cx="22" cy="4" r="1.8" fill="#2274A5"/><circle cx="7" cy="19" r="1.8" fill="#E8453C"/>
      <line x1="2" y1="20" x2="24" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="2" y1="1" x2="2" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function LineIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <polyline points="2,19 7,13 13,15 19,5 24,8" fill="none" stroke="#E8453C" strokeWidth="1.8"/>
      <polyline points="2,17 7,9 13,12 19,3 24,6" fill="none" stroke="#2274A5" strokeWidth="1.8" strokeDasharray="3,2"/>
      <line x1="1" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="1" y1="1" x2="1" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function CurveFitIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <polyline points="2,18 24,4" fill="none" stroke="#E8453C" strokeWidth="1.8" strokeDasharray="3,2"/>
      <circle cx="4" cy="16" r="2" fill="#2274A5"/><circle cx="8" cy="14" r="2" fill="#2274A5"/>
      <circle cx="13" cy="10" r="2" fill="#2274A5"/><circle cx="18" cy="7" r="2" fill="#2274A5"/>
      <circle cx="22" cy="5" r="2" fill="#2274A5"/>
      <line x1="1" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="1" y1="1" x2="1" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function AreaIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <polygon points="2,20 2,16 7,10 13,13 19,5 24,8 24,20" fill="#2274A5" opacity="0.3"/>
      <polyline points="2,16 7,10 13,13 19,5 24,8" fill="none" stroke="#2274A5" strokeWidth="1.8"/>
      <line x1="1" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="1" y1="1" x2="1" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function BubbleIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <circle cx="7" cy="14" r="4" fill="#E8453C" opacity="0.5"/>
      <circle cx="15" cy="8" r="3" fill="#2274A5" opacity="0.5"/>
      <circle cx="20" cy="13" r="5" fill="#32936F" opacity="0.5"/>
      <circle cx="10" cy="6" r="2" fill="#F18F01" opacity="0.5"/>
      <line x1="1" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="1" y1="1" x2="1" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function BlandAltmanIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <line x1="1" y1="11" x2="25" y2="11" stroke="#888" strokeWidth="1" strokeDasharray="3,2"/>
      <line x1="1" y1="5" x2="25" y2="5" stroke="#E8453C" strokeWidth="0.8" strokeDasharray="2,2"/>
      <line x1="1" y1="17" x2="25" y2="17" stroke="#E8453C" strokeWidth="0.8" strokeDasharray="2,2"/>
      <circle cx="5" cy="9" r="1.8" fill="#2274A5"/><circle cx="9" cy="13" r="1.8" fill="#2274A5"/>
      <circle cx="13" cy="10" r="1.8" fill="#2274A5"/><circle cx="17" cy="12" r="1.8" fill="#2274A5"/>
      <circle cx="21" cy="8" r="1.8" fill="#2274A5"/>
      <line x1="1" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function GroupedBarIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="8" width="4" height="12" fill="#E8453C" rx="1"/>
      <rect x="6" y="4" width="4" height="16" fill="#2274A5" rx="1"/>
      <rect x="14" y="10" width="4" height="10" fill="#E8453C" rx="1"/>
      <rect x="19" y="6" width="4" height="14" fill="#2274A5" rx="1"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function StackedBarIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="2" y="12" width="7" height="8" fill="#E8453C" rx="1"/>
      <rect x="2" y="5" width="7" height="7" fill="#2274A5" rx="1"/>
      <rect x="14" y="10" width="7" height="10" fill="#E8453C" rx="1"/>
      <rect x="14" y="4" width="7" height="6" fill="#2274A5" rx="1"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function TwoWayAnovaIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="10" width="3" height="10" fill="#E8453C" rx="0.5"/>
      <rect x="5" y="6" width="3" height="14" fill="#2274A5" rx="0.5"/>
      <rect x="9" y="8" width="3" height="12" fill="#32936F" rx="0.5"/>
      <rect x="14" y="12" width="3" height="8" fill="#E8453C" rx="0.5"/>
      <rect x="18" y="4" width="3" height="16" fill="#2274A5" rx="0.5"/>
      <rect x="22" y="9" width="3" height="11" fill="#32936F" rx="0.5"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function HistogramIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="13" width="4" height="7" fill="#2274A5" rx="1"/>
      <rect x="6" y="7" width="4" height="13" fill="#2274A5" rx="1"/>
      <rect x="11" y="3" width="4" height="17" fill="#2274A5" rx="1"/>
      <rect x="16" y="8" width="4" height="12" fill="#2274A5" rx="1"/>
      <rect x="21" y="14" width="4" height="6" fill="#2274A5" rx="1"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function ECDFIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <polyline points="1,19 5,19 5,15 9,15 9,11 14,11 14,7 19,7 19,4 25,4" fill="none" stroke="#2274A5" strokeWidth="1.8"/>
      <line x1="1" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="1" y1="1" x2="1" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function QQIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <line x1="2" y1="19" x2="24" y2="2" stroke="#888" strokeWidth="1" strokeDasharray="3,2"/>
      <circle cx="4" cy="18" r="1.5" fill="#2274A5"/><circle cx="7" cy="16" r="1.5" fill="#2274A5"/>
      <circle cx="10" cy="13" r="1.5" fill="#2274A5"/><circle cx="13" cy="10" r="1.5" fill="#2274A5"/>
      <circle cx="16" cy="9" r="1.5" fill="#2274A5"/><circle cx="19" cy="6" r="1.5" fill="#2274A5"/>
      <circle cx="22" cy="3" r="1.5" fill="#2274A5"/>
      <line x1="1" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="1" y1="1" x2="1" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function ColumnStatsIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="3" y="8" width="6" height="12" fill="#2274A5" opacity="0.3" rx="1"/>
      <line x1="3" y1="14" x2="9" y2="14" stroke="#2274A5" strokeWidth="1.5"/>
      <line x1="6" y1="8" x2="6" y2="20" stroke="#2274A5" strokeWidth="0.8"/>
      <rect x="16" y="6" width="6" height="14" fill="#E8453C" opacity="0.3" rx="1"/>
      <line x1="16" y1="12" x2="22" y2="12" stroke="#E8453C" strokeWidth="1.5"/>
      <line x1="19" y1="6" x2="19" y2="20" stroke="#E8453C" strokeWidth="0.8"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function KaplanMeierIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <polyline points="1,2 1,10 7,10 7,14 13,14 13,17 19,17 19,20 25,20" fill="none" stroke="#E8453C" strokeWidth="1.8"/>
      <polyline points="1,2 1,8 5,8 5,13 11,13 11,16 17,16 17,19 25,19" fill="none" stroke="#2274A5" strokeWidth="1.8" strokeDasharray="3,2"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
      <line x1="0" y1="1" x2="0" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function HeatmapIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="1" width="7" height="6" fill="#E8453C" opacity="0.85" rx="1"/>
      <rect x="10" y="1" width="7" height="6" fill="#F18F01" opacity="0.6" rx="1"/>
      <rect x="19" y="1" width="6" height="6" fill="#E8453C" opacity="0.25" rx="1"/>
      <rect x="1" y="9" width="7" height="6" fill="#2274A5" opacity="0.35" rx="1"/>
      <rect x="10" y="9" width="7" height="6" fill="#2274A5" opacity="0.9" rx="1"/>
      <rect x="19" y="9" width="6" height="6" fill="#2274A5" opacity="0.55" rx="1"/>
      <rect x="1" y="17" width="7" height="4" fill="#32936F" opacity="0.5" rx="1"/>
      <rect x="10" y="17" width="7" height="4" fill="#32936F" opacity="0.8" rx="1"/>
      <rect x="19" y="17" width="6" height="4" fill="#32936F" opacity="0.3" rx="1"/>
    </svg>
  );
}

function ForestPlotIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <line x1="13" y1="1" x2="13" y2="20" stroke="#ccc" strokeWidth="0.8" strokeDasharray="2,2"/>
      <line x1="3" y1="5" x2="23" y2="5" stroke="#E8453C" strokeWidth="1.5"/>
      <rect x="9" y="3.5" width="8" height="3" fill="#E8453C" opacity="0.25"/>
      <circle cx="13" cy="5" r="2" fill="#E8453C"/>
      <line x1="5" y1="11" x2="21" y2="11" stroke="#2274A5" strokeWidth="1.5"/>
      <rect x="10" y="9.5" width="6" height="3" fill="#2274A5" opacity="0.25"/>
      <circle cx="14" cy="11" r="2" fill="#2274A5"/>
      <line x1="4" y1="17" x2="19" y2="17" stroke="#32936F" strokeWidth="1.5"/>
      <rect x="8" y="15.5" width="7" height="3" fill="#32936F" opacity="0.25"/>
      <circle cx="11" cy="17" r="2" fill="#32936F"/>
    </svg>
  );
}

function ContingencyIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="1" width="11" height="9" fill="#2274A5" opacity="0.6" rx="1"/>
      <rect x="14" y="1" width="11" height="9" fill="#E8453C" opacity="0.4" rx="1"/>
      <rect x="1" y="12" width="11" height="9" fill="#E8453C" opacity="0.6" rx="1"/>
      <rect x="14" y="12" width="11" height="9" fill="#2274A5" opacity="0.4" rx="1"/>
      <line x1="13" y1="0" x2="13" y2="22" stroke="#555" strokeWidth="0.8"/>
      <line x1="0" y1="11" x2="26" y2="11" stroke="#555" strokeWidth="0.8"/>
    </svg>
  );
}

function ChiSquareIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="10" width="5" height="10" fill="#2274A5" rx="1"/>
      <rect x="8" y="4" width="5" height="16" fill="#2274A5" rx="1"/>
      <rect x="15" y="7" width="5" height="13" fill="#2274A5" rx="1"/>
      <rect x="3" y="9" width="1" height="11" fill="none" stroke="#E8453C" strokeWidth="1" strokeDasharray="2,1"/>
      <rect x="10" y="3" width="1" height="17" fill="none" stroke="#E8453C" strokeWidth="1" strokeDasharray="2,1"/>
      <rect x="17" y="6" width="1" height="14" fill="none" stroke="#E8453C" strokeWidth="1" strokeDasharray="2,1"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function WaterfallIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="1" y="3" width="4" height="17" fill="#2274A5" rx="0.5"/>
      <rect x="7" y="3" width="4" height="6" fill="#32936F" rx="0.5"/>
      <rect x="13" y="9" width="4" height="4" fill="#E8453C" rx="0.5"/>
      <rect x="19" y="7" width="4" height="13" fill="#2274A5" rx="0.5"/>
      <line x1="5" y1="3" x2="7" y2="3" stroke="#888" strokeWidth="0.8" strokeDasharray="1.5,1"/>
      <line x1="11" y1="9" x2="13" y2="9" stroke="#888" strokeWidth="0.8" strokeDasharray="1.5,1"/>
      <line x1="17" y1="13" x2="19" y2="13" stroke="#888" strokeWidth="0.8" strokeDasharray="1.5,1"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function LollipopIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <line x1="5" y1="20" x2="5" y2="7" stroke="#2274A5" strokeWidth="1.5"/>
      <circle cx="5" cy="7" r="2.5" fill="#2274A5"/>
      <line x1="13" y1="20" x2="13" y2="4" stroke="#E8453C" strokeWidth="1.5"/>
      <circle cx="13" cy="4" r="2.5" fill="#E8453C"/>
      <line x1="21" y1="20" x2="21" y2="10" stroke="#32936F" strokeWidth="1.5"/>
      <circle cx="21" cy="10" r="2.5" fill="#32936F"/>
      <line x1="0" y1="20" x2="25" y2="20" stroke="#555" strokeWidth="1"/>
    </svg>
  );
}

function PyramidIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <rect x="2" y="2" width="9" height="4" fill="#2274A5" rx="0.5"/>
      <rect x="2" y="8" width="7" height="4" fill="#2274A5" rx="0.5"/>
      <rect x="2" y="14" width="5" height="4" fill="#2274A5" rx="0.5"/>
      <rect x="15" y="2" width="8" height="4" fill="#E8453C" rx="0.5"/>
      <rect x="15" y="8" width="6" height="4" fill="#E8453C" rx="0.5"/>
      <rect x="15" y="14" width="4" height="4" fill="#E8453C" rx="0.5"/>
      <line x1="13" y1="0" x2="13" y2="22" stroke="#555" strokeWidth="0.8"/>
    </svg>
  );
}

function RaincloudIcon() {
  return (
    <svg viewBox="0 0 26 22" fill="none">
      <ellipse cx="8" cy="8" rx="5" ry="3" fill="#2274A5" opacity="0.3" stroke="#2274A5" strokeWidth="0.8"/>
      <rect x="5" y="10" width="6" height="3" fill="none" stroke="#2274A5" strokeWidth="1"/>
      <line x1="8" y1="11.5" x2="8" y2="11.5" stroke="#2274A5" strokeWidth="2"/>
      <circle cx="5" cy="16" r="1" fill="#2274A5" opacity="0.6"/>
      <circle cx="7" cy="17" r="1" fill="#2274A5" opacity="0.6"/>
      <circle cx="9" cy="15" r="1" fill="#2274A5" opacity="0.6"/>
      <circle cx="6" cy="18" r="1" fill="#2274A5" opacity="0.6"/>
      <circle cx="10" cy="17" r="1" fill="#2274A5" opacity="0.6"/>
      <ellipse cx="20" cy="8" rx="4" ry="2.5" fill="#E8453C" opacity="0.3" stroke="#E8453C" strokeWidth="0.8"/>
      <rect x="17" y="10" width="6" height="3" fill="none" stroke="#E8453C" strokeWidth="1"/>
      <circle cx="18" cy="15" r="1" fill="#E8453C" opacity="0.6"/>
      <circle cx="20" cy="16" r="1" fill="#E8453C" opacity="0.6"/>
      <circle cx="22" cy="15" r="1" fill="#E8453C" opacity="0.6"/>
    </svg>
  );
}

// ── Chart type definitions grouped by category ──

export const CHART_GROUPS: { group: string; charts: ChartTypeInfo[] }[] = [
  {
    group: 'Column',
    charts: [
      { key: 'bar', label: 'Bar Chart', group: 'Column', icon: <BarIcon /> },
      { key: 'box', label: 'Box Plot', group: 'Column', icon: <BoxIcon /> },
      { key: 'violin', label: 'Violin', group: 'Column', icon: <ViolinIcon /> },
      { key: 'dot_plot', label: 'Dot Plot', group: 'Column', icon: <DotPlotIcon /> },
      { key: 'subcolumn_scatter', label: 'Subcolumn', group: 'Column', icon: <SubcolumnIcon /> },
      { key: 'before_after', label: 'Before/After', group: 'Column', icon: <BeforeAfterIcon /> },
      { key: 'repeated_measures', label: 'Repeated Meas.', group: 'Column', icon: <RepeatedMeasuresIcon /> },
    ],
  },
  {
    group: 'XY',
    charts: [
      { key: 'scatter', label: 'Scatter', group: 'XY', icon: <ScatterIcon /> },
      { key: 'line', label: 'Line Graph', group: 'XY', icon: <LineIcon /> },
      { key: 'curve_fit', label: 'Curve Fit', group: 'XY', icon: <CurveFitIcon /> },
      { key: 'area_chart', label: 'Area Chart', group: 'XY', icon: <AreaIcon /> },
      { key: 'bubble', label: 'Bubble', group: 'XY', icon: <BubbleIcon /> },
      { key: 'bland_altman', label: 'Bland-Altman', group: 'XY', icon: <BlandAltmanIcon /> },
    ],
  },
  {
    group: 'Grouped',
    charts: [
      { key: 'grouped_bar', label: 'Grouped Bar', group: 'Grouped', icon: <GroupedBarIcon /> },
      { key: 'stacked_bar', label: 'Stacked Bar', group: 'Grouped', icon: <StackedBarIcon /> },
      { key: 'two_way_anova', label: 'Two-Way ANOVA', group: 'Grouped', icon: <TwoWayAnovaIcon /> },
    ],
  },
  {
    group: 'Distribution',
    charts: [
      { key: 'histogram', label: 'Histogram', group: 'Distribution', icon: <HistogramIcon /> },
      { key: 'ecdf', label: 'ECDF', group: 'Distribution', icon: <ECDFIcon /> },
      { key: 'qq_plot', label: 'Q-Q Plot', group: 'Distribution', icon: <QQIcon /> },
      { key: 'column_stats', label: 'Col Statistics', group: 'Distribution', icon: <ColumnStatsIcon /> },
    ],
  },
  {
    group: 'Survival',
    charts: [
      { key: 'kaplan_meier', label: 'Survival', group: 'Survival', icon: <KaplanMeierIcon /> },
    ],
  },
  {
    group: 'Correlation',
    charts: [
      { key: 'heatmap', label: 'Heatmap', group: 'Correlation', icon: <HeatmapIcon /> },
      { key: 'forest_plot', label: 'Forest Plot', group: 'Correlation', icon: <ForestPlotIcon /> },
      { key: 'contingency', label: 'Contingency', group: 'Correlation', icon: <ContingencyIcon /> },
      { key: 'chi_square_gof', label: 'Chi-Sq GoF', group: 'Correlation', icon: <ChiSquareIcon /> },
    ],
  },
  {
    group: 'Other',
    charts: [
      { key: 'waterfall', label: 'Waterfall', group: 'Other', icon: <WaterfallIcon /> },
      { key: 'lollipop', label: 'Lollipop', group: 'Other', icon: <LollipopIcon /> },
      { key: 'pyramid', label: 'Pyramid', group: 'Other', icon: <PyramidIcon /> },
      { key: 'raincloud', label: 'Raincloud', group: 'Other', icon: <RaincloudIcon /> },
    ],
  },
];

interface SidebarProps {
  activeChart: string;
  onSelectChart: (key: string) => void;
}

export default function Sidebar({ activeChart, onSelectChart }: SidebarProps) {
  return (
    <div className="sidebar">
      {CHART_GROUPS.map((g) => (
        <div key={g.group}>
          <div className="sidebar-group-label">{g.group}</div>
          {g.charts.map((c) => (
            <div
              key={c.key}
              className={`chart-btn${activeChart === c.key ? ' active' : ''}`}
              onClick={() => onSelectChart(c.key)}
            >
              {c.icon}
              <span className="chart-btn-label">{c.label}</span>
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}
