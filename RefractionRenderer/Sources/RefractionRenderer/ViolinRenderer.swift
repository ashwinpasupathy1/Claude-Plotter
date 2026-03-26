// ViolinRenderer.swift — Draws violin plots with KDE shapes and inner box plots.
// Prefers precomputed KDE from spec.data when available; falls back to
// client-side Gaussian kernel computation from raw values.

import SwiftUI

public enum ViolinRenderer {

    // MARK: - Precomputed KDE + box stats from the Python engine

    private struct ViolinStats {
        let q1: Double
        let median: Double
        let q3: Double
        /// KDE density values (symmetric, normalized to max=1 by renderer).
        let kdeX: [Double]
        /// KDE data-value positions corresponding to kdeX.
        let kdeY: [Double]
    }

    /// Try to read precomputed violin stats for group at `index` from `spec.data["violin_stats"]`.
    private static func precomputedStats(spec: ChartSpec, index: Int) -> ViolinStats? {
        guard let data = spec.data,
              let statsArr = data["violin_stats"]?.arrayValue,
              index < statsArr.count,
              let entry = statsArr[index].objectValue,
              let q1 = entry["q1"]?.doubleValue,
              let median = entry["median"]?.doubleValue,
              let q3 = entry["q3"]?.doubleValue,
              let kdeX = entry["kde_x"]?.doubleArray,
              let kdeY = entry["kde_y"]?.doubleArray,
              !kdeX.isEmpty, !kdeY.isEmpty else {
            return nil
        }
        return ViolinStats(q1: q1, median: median, q3: q3, kdeX: kdeX, kdeY: kdeY)
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

        for (i, group) in groups.enumerated() {
            let color = Color(hex: colorForIndex(i, style: style))
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let halfWidth = groupWidth * 0.35

            // Try precomputed KDE first
            if let stats = precomputedStats(spec: spec, index: i) {
                drawFromPrecomputed(
                    in: context, stats: stats, centerX: centerX, halfWidth: halfWidth,
                    plotRect: plotRect, yRange: yRange, color: color
                )
                continue
            }

            // Fallback: compute KDE client-side
            let values = group.values.raw
            guard values.count >= 4 else {
                // Too few: draw as dots
                for (idx, val) in values.enumerated() {
                    let y = yToCanvas(val, plotRect: plotRect, yRange: yRange)
                    let j = jitterForIndex(idx, count: values.count, width: 10)
                    let r: CGFloat = 4
                    let pt = CGRect(x: centerX + j - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: pt), with: .color(color.opacity(0.8)))
                }
                continue
            }

            let sorted = values.sorted()
            let lo = sorted.first!
            let hi = sorted.last!
            let range = hi - lo
            guard range > 0 else { continue }

            // Bandwidth (Silverman's rule)
            let n = Double(values.count)
            let mean = values.reduce(0, +) / n
            let sd = sqrt(values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / n)
            let bw = max(1.06 * sd * pow(n, -0.2), range * 0.05)

            let nPoints = 50
            var kdePoints: [(y: CGFloat, density: CGFloat)] = []
            var maxDensity: CGFloat = 0

            for step in 0..<nPoints {
                let frac = Double(step) / Double(nPoints - 1)
                let val = lo + frac * range
                var density: Double = 0
                for v in values {
                    let z = (val - v) / bw
                    density += exp(-0.5 * z * z)
                }
                density /= (n * bw * sqrt(2 * .pi))
                let cy = yToCanvas(val, plotRect: plotRect, yRange: yRange)
                kdePoints.append((cy, CGFloat(density)))
                maxDensity = max(maxDensity, CGFloat(density))
            }

            guard maxDensity > 0 else { continue }

            drawViolinShape(in: context, kdePoints: kdePoints, maxDensity: maxDensity,
                           centerX: centerX, halfWidth: halfWidth, color: color)

            // Inner mini box plot
            let q1 = percentile(sorted, p: 0.25)
            let median = percentile(sorted, p: 0.50)
            let q3 = percentile(sorted, p: 0.75)
            drawInnerBox(in: context, q1: q1, median: median, q3: q3,
                        centerX: centerX, halfWidth: halfWidth,
                        plotRect: plotRect, yRange: yRange)
        }
    }

    /// Draw a violin from precomputed KDE data.
    private static func drawFromPrecomputed(
        in context: GraphicsContext,
        stats: ViolinStats,
        centerX: CGFloat,
        halfWidth: CGFloat,
        plotRect: CGRect,
        yRange: (min: Double, max: Double),
        color: Color
    ) {
        // Build KDE points for rendering
        var kdePoints: [(y: CGFloat, density: CGFloat)] = []
        var maxDensity: CGFloat = 0

        for idx in 0..<stats.kdeX.count {
            let density = CGFloat(stats.kdeX[idx])
            let cy = yToCanvas(stats.kdeY[idx], plotRect: plotRect, yRange: yRange)
            kdePoints.append((cy, density))
            maxDensity = max(maxDensity, density)
        }

        guard maxDensity > 0 else { return }

        drawViolinShape(in: context, kdePoints: kdePoints, maxDensity: maxDensity,
                       centerX: centerX, halfWidth: halfWidth, color: color)

        drawInnerBox(in: context, q1: stats.q1, median: stats.median, q3: stats.q3,
                    centerX: centerX, halfWidth: halfWidth,
                    plotRect: plotRect, yRange: yRange)
    }

    /// Draw the mirrored KDE violin shape.
    private static func drawViolinShape(
        in context: GraphicsContext,
        kdePoints: [(y: CGFloat, density: CGFloat)],
        maxDensity: CGFloat,
        centerX: CGFloat,
        halfWidth: CGFloat,
        color: Color
    ) {
        var violinPath = Path()
        // Right side
        for (idx, kp) in kdePoints.enumerated() {
            let dx = (kp.density / maxDensity) * halfWidth
            let pt = CGPoint(x: centerX + dx, y: kp.y)
            if idx == 0 { violinPath.move(to: pt) }
            else { violinPath.addLine(to: pt) }
        }
        // Left side (reversed)
        for kp in kdePoints.reversed() {
            let dx = (kp.density / maxDensity) * halfWidth
            violinPath.addLine(to: CGPoint(x: centerX - dx, y: kp.y))
        }
        violinPath.closeSubpath()

        context.fill(violinPath, with: .color(color.opacity(0.3)))
        context.stroke(violinPath, with: .color(color), lineWidth: 1.0)
    }

    /// Draw the inner mini box + median dot.
    private static func drawInnerBox(
        in context: GraphicsContext,
        q1: Double, median: Double, q3: Double,
        centerX: CGFloat, halfWidth: CGFloat,
        plotRect: CGRect, yRange: (min: Double, max: Double)
    ) {
        let boxW: CGFloat = halfWidth * 0.3
        let yq1 = yToCanvas(q1, plotRect: plotRect, yRange: yRange)
        let yq3 = yToCanvas(q3, plotRect: plotRect, yRange: yRange)
        let ymed = yToCanvas(median, plotRect: plotRect, yRange: yRange)

        let boxRect = CGRect(
            x: centerX - boxW / 2,
            y: min(yq1, yq3),
            width: boxW,
            height: abs(yq1 - yq3)
        )
        context.fill(Path(boxRect), with: .color(Color(hex: "#222222").opacity(0.4)))

        // Median dot
        let medR: CGFloat = 3
        let medPt = CGRect(x: centerX - medR, y: ymed - medR, width: medR * 2, height: medR * 2)
        context.fill(Path(ellipseIn: medPt), with: .color(.white))
    }

    // MARK: - Legacy draw (without spec)

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        let emptySpec = ChartSpec(chartType: "violin", groups: groups, style: style)
        draw(in: context, plotRect: plotRect, spec: emptySpec, groups: groups, style: style)
    }

    private static func percentile(_ sorted: [Double], p: Double) -> Double {
        let n = Double(sorted.count)
        let idx = p * (n - 1)
        let lo = Int(idx)
        let hi = min(lo + 1, sorted.count - 1)
        let frac = idx - Double(lo)
        return sorted[lo] * (1 - frac) + sorted[hi] * frac
    }

    // MARK: - Hit Regions

    public static func hitRegions(
        plotRect: CGRect, groups: [GroupData], style: StyleSpec
    ) -> [ChartHitRegion] {
        guard !groups.isEmpty else { return [] }
        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)

        return groups.enumerated().compactMap { i, group in
            let sorted = group.values.raw.sorted()
            guard !sorted.isEmpty else { return nil }
            let centerX = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let w = groupWidth * 0.6
            let top = yToCanvas(sorted.last!, plotRect: plotRect, yRange: yRange)
            let bot = yToCanvas(sorted.first!, plotRect: plotRect, yRange: yRange)
            let rect = CGRect(x: centerX - w/2, y: min(top, bot), width: w, height: abs(bot - top))
            return ChartHitRegion(
                kind: .violin, rect: rect, groupIndex: i, groupName: group.name,
                label: group.name, metadata: ["n": "\(group.values.n)"]
            )
        }
    }
}
