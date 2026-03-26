// HistogramRenderer.swift — Draws histograms with auto-binned adjacent bars.
// Prefers precomputed bin edges and counts from spec.data when available;
// falls back to client-side Sturges-rule binning from raw values.

import SwiftUI

public enum HistogramRenderer {

    // MARK: - Precomputed histogram from the Python engine

    private struct HistogramData {
        let binEdges: [Double]   // n+1 values
        let counts: [Int]        // n values
    }

    /// Try to read precomputed histogram data for group at `index` from `spec.data["histograms"]`.
    private static func precomputedHistogram(spec: ChartSpec, index: Int) -> HistogramData? {
        guard let data = spec.data,
              let histArr = data["histograms"]?.arrayValue,
              index < histArr.count,
              let entry = histArr[index].objectValue,
              let edges = entry["bin_edges"]?.doubleArray,
              let countsRaw = entry["counts"]?.doubleArray,
              edges.count >= 2 else {
            return nil
        }
        let counts = countsRaw.map { Int($0) }
        return HistogramData(binEdges: edges, counts: counts)
    }

    // MARK: - Draw

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        spec: ChartSpec,
        groups: [GroupData],
        style: StyleSpec
    ) {
        // Try precomputed histograms first
        if let data = spec.data, data["histograms"] != nil {
            drawFromPrecomputed(in: context, plotRect: plotRect, spec: spec, groups: groups, style: style)
            return
        }

        // Fallback: compute bins client-side
        drawClientSide(in: context, plotRect: plotRect, groups: groups, style: style)
    }

    /// Draw using precomputed bin edges and counts from the engine.
    private static func drawFromPrecomputed(
        in context: GraphicsContext,
        plotRect: CGRect,
        spec: ChartSpec,
        groups: [GroupData],
        style: StyleSpec
    ) {
        // For histogram, we draw each group's bins (overlay mode by default)
        for (gi, group) in groups.enumerated() {
            guard let hist = precomputedHistogram(spec: spec, index: gi) else { continue }
            guard !hist.counts.isEmpty else { continue }

            let color = Color(hex: colorForIndex(gi, style: style))
            let maxCount = hist.counts.max() ?? 1
            guard maxCount > 0 else { continue }

            let lo = hist.binEdges.first!
            let hi = hist.binEdges.last!
            let dataRange = hi - lo
            guard dataRange > 0 else { continue }

            for (bi, count) in hist.counts.enumerated() {
                let edgeLo = hist.binEdges[bi]
                let edgeHi = hist.binEdges[bi + 1]

                // Map bin edges to x positions within plotRect
                let x0 = plotRect.minX + CGFloat((edgeLo - lo) / dataRange) * plotRect.width
                let x1 = plotRect.minX + CGFloat((edgeHi - lo) / dataRange) * plotRect.width

                let fraction = CGFloat(count) / CGFloat(maxCount)
                let barHeight = fraction * plotRect.height
                let y = plotRect.maxY - barHeight

                let rect = CGRect(x: x0, y: y, width: x1 - x0, height: barHeight)
                context.fill(Path(rect), with: .color(color.opacity(0.7)))
                context.stroke(Path(rect), with: .color(color), lineWidth: 0.5)
            }
        }
    }

    /// Client-side binning fallback (Sturges rule).
    private static func drawClientSide(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        let allValues = groups.flatMap { $0.values.raw }
        guard allValues.count >= 2 else { return }

        let sorted = allValues.sorted()
        let lo = sorted.first!
        let hi = sorted.last!
        guard hi > lo else { return }

        // Sturges rule for bin count
        let nBins = max(Int(ceil(log2(Double(allValues.count)))) + 1, 5)
        let binWidth = (hi - lo) / Double(nBins)

        // Count values per bin
        var counts = [Int](repeating: 0, count: nBins)
        for v in allValues {
            var bin = Int((v - lo) / binWidth)
            if bin >= nBins { bin = nBins - 1 }
            counts[bin] += 1
        }

        let maxCount = counts.max() ?? 1
        let barW = plotRect.width / CGFloat(nBins)
        let color = Color(hex: colorForIndex(0, style: style))

        for (i, count) in counts.enumerated() {
            let fraction = CGFloat(count) / CGFloat(maxCount)
            let barHeight = fraction * plotRect.height
            let x = plotRect.minX + CGFloat(i) * barW
            let y = plotRect.maxY - barHeight

            let rect = CGRect(x: x, y: y, width: barW, height: barHeight)
            context.fill(Path(rect), with: .color(color.opacity(0.7)))
            context.stroke(Path(rect), with: .color(color), lineWidth: 0.5)
        }
    }

    // MARK: - Legacy draw (without spec)

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        let emptySpec = ChartSpec(chartType: "histogram", groups: groups, style: style)
        draw(in: context, plotRect: plotRect, spec: emptySpec, groups: groups, style: style)
    }

    // MARK: - Hit Regions

    public static func hitRegions(
        plotRect: CGRect, groups: [GroupData], style: StyleSpec
    ) -> [ChartHitRegion] {
        guard !groups.isEmpty else { return [] }
        let groupWidth = plotRect.width / CGFloat(groups.count)
        return groups.enumerated().map { i, group in
            let x = plotRect.minX + groupWidth * CGFloat(i)
            return ChartHitRegion(
                kind: .histogram, rect: CGRect(x: x, y: plotRect.minY, width: groupWidth, height: plotRect.height),
                groupIndex: i, groupName: group.name, label: group.name,
                metadata: ["n": "\(group.values.n)"]
            )
        }
    }
}
