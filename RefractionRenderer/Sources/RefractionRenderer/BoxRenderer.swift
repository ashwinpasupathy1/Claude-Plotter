// BoxRenderer.swift — Draws box plots with median, quartiles, whiskers, and outliers.
// Prefers precomputed box stats from spec.data when available; falls back to
// client-side computation from raw values.

import SwiftUI

public enum BoxRenderer {

    // MARK: - Precomputed box stats from the Python engine

    private struct BoxStats {
        let q1: Double
        let median: Double
        let q3: Double
        let whiskerLo: Double
        let whiskerHi: Double
        let outliers: [Double]
    }

    /// Try to read precomputed box stats for group at `index` from `spec.data["box_stats"]`.
    private static func precomputedStats(spec: ChartSpec, index: Int) -> BoxStats? {
        guard let data = spec.data,
              let boxStatsArr = data["box_stats"]?.arrayValue,
              index < boxStatsArr.count,
              let entry = boxStatsArr[index].objectValue,
              let q1 = entry["q1"]?.doubleValue,
              let median = entry["median"]?.doubleValue,
              let q3 = entry["q3"]?.doubleValue,
              let wLo = entry["whisker_lo"]?.doubleValue,
              let wHi = entry["whisker_hi"]?.doubleValue else {
            return nil
        }
        let outliers = entry["outliers"]?.doubleArray ?? []
        return BoxStats(q1: q1, median: median, q3: q3,
                        whiskerLo: wLo, whiskerHi: wHi, outliers: outliers)
    }

    /// Compute box stats client-side from raw values (fallback).
    private static func computeStats(sorted: [Double]) -> BoxStats {
        let q1 = percentile(sorted, p: 0.25)
        let median = percentile(sorted, p: 0.50)
        let q3 = percentile(sorted, p: 0.75)
        let iqr = q3 - q1
        let whiskerLo = sorted.first { $0 >= q1 - 1.5 * iqr } ?? sorted.first!
        let whiskerHi = sorted.last { $0 <= q3 + 1.5 * iqr } ?? sorted.last!
        let outliers = sorted.filter { $0 < whiskerLo || $0 > whiskerHi }
        return BoxStats(q1: q1, median: median, q3: q3,
                        whiskerLo: whiskerLo, whiskerHi: whiskerHi, outliers: outliers)
    }

    // MARK: - Draw

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        spec: ChartSpec,
        groups: [GroupData],
        style: StyleSpec
    ) {
        guard !groups.isEmpty else { return }

        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)
        let boxFraction: CGFloat = 0.5

        for (i, group) in groups.enumerated() {
            let color = Color(hex: colorForIndex(i, style: style))
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let boxW = groupWidth * boxFraction

            // Prefer precomputed stats; fall back to client-side
            let stats: BoxStats
            if let precomputed = precomputedStats(spec: spec, index: i) {
                stats = precomputed
            } else {
                let sorted = group.values.raw.sorted()
                guard sorted.count >= 4 else {
                    drawPoints(in: context, values: sorted, centerX: centerX,
                               plotRect: plotRect, yRange: yRange, color: color)
                    continue
                }
                stats = computeStats(sorted: sorted)
            }

            let y_q1 = yToCanvas(stats.q1, plotRect: plotRect, yRange: yRange)
            let y_q3 = yToCanvas(stats.q3, plotRect: plotRect, yRange: yRange)
            let y_med = yToCanvas(stats.median, plotRect: plotRect, yRange: yRange)
            let y_wLo = yToCanvas(stats.whiskerLo, plotRect: plotRect, yRange: yRange)
            let y_wHi = yToCanvas(stats.whiskerHi, plotRect: plotRect, yRange: yRange)

            // Box (Q1 to Q3)
            let boxRect = CGRect(
                x: centerX - boxW / 2,
                y: min(y_q1, y_q3),
                width: boxW,
                height: abs(y_q1 - y_q3)
            )
            context.fill(Path(boxRect), with: .color(color.opacity(0.3)))
            context.stroke(Path(boxRect), with: .color(color), lineWidth: 1.0)

            // Median line
            drawLine(in: context,
                     from: CGPoint(x: centerX - boxW / 2, y: y_med),
                     to: CGPoint(x: centerX + boxW / 2, y: y_med),
                     color: color, width: 2.0)

            // Whiskers
            let capW = boxW * 0.4
            // Lower whisker
            drawLine(in: context,
                     from: CGPoint(x: centerX, y: y_q1),
                     to: CGPoint(x: centerX, y: y_wLo),
                     color: Color(hex: "#222222"), width: 1.0)
            drawLine(in: context,
                     from: CGPoint(x: centerX - capW / 2, y: y_wLo),
                     to: CGPoint(x: centerX + capW / 2, y: y_wLo),
                     color: Color(hex: "#222222"), width: 1.0)
            // Upper whisker
            drawLine(in: context,
                     from: CGPoint(x: centerX, y: y_q3),
                     to: CGPoint(x: centerX, y: y_wHi),
                     color: Color(hex: "#222222"), width: 1.0)
            drawLine(in: context,
                     from: CGPoint(x: centerX - capW / 2, y: y_wHi),
                     to: CGPoint(x: centerX + capW / 2, y: y_wHi),
                     color: Color(hex: "#222222"), width: 1.0)

            // Outliers
            for val in stats.outliers {
                let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)
                let r: CGFloat = 3
                let pt = CGRect(x: centerX - r, y: y - r, width: r * 2, height: r * 2)
                context.stroke(Path(ellipseIn: pt), with: .color(color), lineWidth: 1.0)
            }
        }
    }

    // MARK: - Legacy draw (without spec)

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        let emptySpec = ChartSpec(chartType: "box", groups: groups, style: style)
        draw(in: context, plotRect: plotRect, spec: emptySpec, groups: groups, style: style)
    }

    // MARK: - Hit Regions

    public static func hitRegions(
        plotRect: CGRect, groups: [GroupData], style: StyleSpec
    ) -> [ChartHitRegion] {
        guard !groups.isEmpty else { return [] }
        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)
        let boxFraction: CGFloat = 0.5

        var regions: [ChartHitRegion] = []
        for (i, group) in groups.enumerated() {
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let boxW = groupWidth * boxFraction
            let sorted = group.values.raw.sorted()
            guard sorted.count >= 2 else { continue }
            let lo = yToCanvas(sorted.last!, plotRect: plotRect, yRange: yRange)
            let hi = yToCanvas(sorted.first!, plotRect: plotRect, yRange: yRange)
            let rect = CGRect(x: centerX - boxW/2, y: min(lo, hi), width: boxW, height: abs(hi - lo))
            let median = percentile(sorted, p: 0.5)
            regions.append(ChartHitRegion(
                kind: .box, rect: rect, groupIndex: i, groupName: group.name,
                label: group.name,
                metadata: ["median": String(format: "%.4f", median), "n": "\(group.values.n)"]
            ))
        }
        return regions
    }

    private static func percentile(_ sorted: [Double], p: Double) -> Double {
        let n = Double(sorted.count)
        let idx = p * (n - 1)
        let lo = Int(idx)
        let hi = min(lo + 1, sorted.count - 1)
        let frac = idx - Double(lo)
        return sorted[lo] * (1 - frac) + sorted[hi] * frac
    }

    private static func drawPoints(
        in context: GraphicsContext, values: [Double], centerX: CGFloat,
        plotRect: CGRect, yRange: (min: Double, max: Double), color: Color
    ) {
        for (idx, val) in values.enumerated() {
            let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)
            let jitter = jitterForIndex(idx, count: values.count, width: 10)
            let r: CGFloat = 4
            let pt = CGRect(x: centerX + jitter - r, y: y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: pt), with: .color(color.opacity(0.8)))
        }
    }
}
