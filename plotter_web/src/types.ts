// Shared TypeScript types for Spectra
import type React from 'react';

export interface ChartTypeInfo {
  key: string;
  label: string;
  group: string;
  icon: React.ReactNode;
}

export interface PlotKw {
  excel_path: string;
  sheet: number | string;
  color: string | null;
  title: string;
  xlabel: string;
  ytitle: string;
  yscale: string;
  ylim: [number, number] | null;
  figsize: [number, number];
  font_size: number;
  bar_width: number;
  error_type: string;
  show_points: boolean;
  jitter: boolean;
  point_size: number;
  point_alpha: number;
  axis_style: string;
  tick_dir: string;
  minor_ticks: boolean;
  gridlines: boolean;
  grid_style: string;
  spine_width: number;
  fig_bg: string;
  cap_size: number;
  ref_line: number | null;
  ref_line_label: string;
  stats_test: string;
  posthoc: string;
  show_brackets: boolean;
  show_pvalues: boolean;
  correction: string;
  control_group: string;
  permutations: number;
  alpha: number;
  palette: string;
  preset: string;
  [k: string]: unknown;
}

export interface StatsResult {
  test_name?: string;
  statistic?: string;
  p_value?: number;
  pairwise?: PairwiseResult[];
  summary?: string;
}

export interface PairwiseResult {
  group1: string;
  group2: string;
  p_value: number;
  significance: string;
}

export interface RenderResponse {
  ok: boolean;
  spec?: {
    data: Record<string, unknown>[];
    layout: Record<string, unknown>;
  };
  image?: string;
  stats?: StatsResult;
  error?: string;
  brackets?: BracketData[];
}

export interface BracketData {
  x0: number;
  x1: number;
  y: number;
  text: string;
}

export interface WikiSection {
  title: string;
  content: string;
}

export type TabName = 'Data' | 'Axes' | 'Style' | 'Stats';

export const DEFAULT_KW: PlotKw = {
  excel_path: '',
  sheet: 0,
  color: null,
  title: '',
  xlabel: '',
  ytitle: '',
  yscale: 'linear',
  ylim: null,
  figsize: [5, 5],
  font_size: 12,
  bar_width: 0.6,
  error_type: 'SEM',
  show_points: true,
  jitter: true,
  point_size: 6,
  point_alpha: 0.8,
  axis_style: 'open',
  tick_dir: 'out',
  minor_ticks: false,
  gridlines: false,
  grid_style: 'none',
  spine_width: 0.8,
  fig_bg: 'white',
  cap_size: 4,
  ref_line: null,
  ref_line_label: '',
  stats_test: 'parametric',
  posthoc: 'tukey',
  show_brackets: true,
  show_pvalues: true,
  correction: 'holm',
  control_group: '',
  permutations: 5000,
  alpha: 0.05,
  palette: 'prism',
  preset: 'Prism Classic',
};

export const API_BASE = import.meta.env.VITE_API_BASE ?? 'http://127.0.0.1:7331';
