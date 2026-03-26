// KaplanMeierRenderer.swift — Draws Kaplan-Meier survival curves.
// Step functions with censored observation markers and optional legend.

import SwiftUI

public enum KaplanMeierRenderer {

    /// Draw KM survival curves from the spec's data payload.
    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        spec: ChartSpec,
        style: StyleSpec
    ) {
        guard let curvesJSON = spec.data?["curves"]?.arrayValue else {
            // Fallback placeholder
            let text = Text("No survival data")
                .font(.callout)
                .foregroundStyle(Color.secondary)
            context.draw(text, at: CGPoint(x: plotRect.midX, y: plotRect.midY))
            return
        }

        let curves = parseCurves(curvesJSON, style: style)
        guard !curves.isEmpty else { return }

        // Y range: 0 to 1.05 (standard for survival)
        let yRange: (min: Double, max: Double) = (0, 1.05)

        // X range: 0 to max time across all curves
        let xMax = curves.flatMap(\.times).max() ?? 1
        let xRange: (min: Double, max: Double) = (0, xMax * 1.05)

        // Draw each curve
        for curve in curves {
            let color = Color(hex: curve.color)
            drawStepFunction(in: context, plotRect: plotRect,
                             times: curve.times, survival: curve.survival,
                             xRange: xRange, yRange: yRange, color: color)

            // Draw censored markers (small + signs)
            drawCensoredMarkers(in: context, plotRect: plotRect,
                                times: curve.censoredTimes, survival: curve.censoredSurvival,
                                xRange: xRange, yRange: yRange, color: color)
        }

        // Draw X axis ticks
        let xTicks = prettyTicks(lo: xRange.min, hi: xRange.max)
        let fontSize: CGFloat = 10
        for tickVal in xTicks {
            let x = xToCanvas(tickVal, plotRect: plotRect, xRange: xRange)
            guard x >= plotRect.minX && x <= plotRect.maxX else { continue }

            // Tick mark
            drawLine(in: context,
                     from: CGPoint(x: x, y: plotRect.maxY),
                     to: CGPoint(x: x, y: plotRect.maxY + 5),
                     color: Color(hex: "#222222"), width: 0.8)

            // Tick label
            let label = Text(formatTickValue(tickVal))
                .font(.system(size: fontSize - 1))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(label, at: CGPoint(x: x, y: plotRect.maxY + 16), anchor: .top)
        }

        // Draw Y axis ticks (0.0, 0.2, 0.4, 0.6, 0.8, 1.0)
        let yTicks: [Double] = [0, 0.2, 0.4, 0.6, 0.8, 1.0]
        for tickVal in yTicks {
            let y = yToCanvas(tickVal, plotRect: plotRect, yRange: yRange)
            guard y >= plotRect.minY && y <= plotRect.maxY else { continue }

            drawLine(in: context,
                     from: CGPoint(x: plotRect.minX, y: y),
                     to: CGPoint(x: plotRect.minX - 5, y: y),
                     color: Color(hex: "#222222"), width: 0.8)

            let label = Text(String(format: "%.1f", tickVal))
                .font(.system(size: fontSize - 1))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(label, at: CGPoint(x: plotRect.minX - 8, y: y), anchor: .trailing)
        }

        // Draw legend
        drawLegend(in: context, plotRect: plotRect, curves: curves)
    }

    // MARK: - Step Function Drawing

    private static func drawStepFunction(
        in context: GraphicsContext,
        plotRect: CGRect,
        times: [Double],
        survival: [Double],
        xRange: (min: Double, max: Double),
        yRange: (min: Double, max: Double),
        color: Color
    ) {
        guard times.count == survival.count, times.count >= 2 else { return }

        var path = Path()
        let firstX = xToCanvas(times[0], plotRect: plotRect, xRange: xRange)
        let firstY = yToCanvas(survival[0], plotRect: plotRect, yRange: yRange)
        path.move(to: CGPoint(x: firstX, y: firstY))

        for i in 1..<times.count {
            let prevY = yToCanvas(survival[i - 1], plotRect: plotRect, yRange: yRange)
            let newX = xToCanvas(times[i], plotRect: plotRect, xRange: xRange)
            let newY = yToCanvas(survival[i], plotRect: plotRect, yRange: yRange)

            // Horizontal step to new time at old survival
            path.addLine(to: CGPoint(x: newX, y: prevY))
            // Vertical drop to new survival
            path.addLine(to: CGPoint(x: newX, y: newY))
        }

        // Extend to the right edge
        if let lastT = times.last, let lastS = survival.last {
            let rightX = plotRect.maxX
            let lastY = yToCanvas(lastS, plotRect: plotRect, yRange: yRange)
            let lastX = xToCanvas(lastT, plotRect: plotRect, xRange: xRange)
            if rightX > lastX {
                path.addLine(to: CGPoint(x: rightX, y: lastY))
            }
        }

        context.stroke(path, with: .color(color), lineWidth: 2.0)
    }

    // MARK: - Censored Markers

    private static func drawCensoredMarkers(
        in context: GraphicsContext,
        plotRect: CGRect,
        times: [Double],
        survival: [Double],
        xRange: (min: Double, max: Double),
        yRange: (min: Double, max: Double),
        color: Color
    ) {
        guard times.count == survival.count else { return }

        let markSize: CGFloat = 5
        for i in 0..<times.count {
            let x = xToCanvas(times[i], plotRect: plotRect, xRange: xRange)
            let y = yToCanvas(survival[i], plotRect: plotRect, yRange: yRange)

            // Draw a small + mark
            var vLine = Path()
            vLine.move(to: CGPoint(x: x, y: y - markSize))
            vLine.addLine(to: CGPoint(x: x, y: y + markSize))
            context.stroke(vLine, with: .color(color), lineWidth: 1.5)

            var hLine = Path()
            hLine.move(to: CGPoint(x: x - markSize, y: y))
            hLine.addLine(to: CGPoint(x: x + markSize, y: y))
            context.stroke(hLine, with: .color(color), lineWidth: 1.5)
        }
    }

    // MARK: - Legend

    private static func drawLegend(
        in context: GraphicsContext,
        plotRect: CGRect,
        curves: [KMCurve]
    ) {
        guard curves.count >= 2 else { return }

        let legendX = plotRect.maxX - 10
        var legendY = plotRect.minY + 10

        for curve in curves {
            let color = Color(hex: curve.color)

            // Color swatch
            var line = Path()
            line.move(to: CGPoint(x: legendX - 40, y: legendY + 6))
            line.addLine(to: CGPoint(x: legendX - 15, y: legendY + 6))
            context.stroke(line, with: .color(color), lineWidth: 2.0)

            // Label
            let label = Text("\(curve.name) (n=\(curve.n))")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(label, at: CGPoint(x: legendX - 44, y: legendY + 6), anchor: .trailing)

            legendY += 16
        }
    }

    // MARK: - Hit Regions

    public static func hitRegions(
        plotRect: CGRect, spec: ChartSpec, style: StyleSpec
    ) -> [ChartHitRegion] {
        guard let curvesJSON = spec.data?["curves"]?.arrayValue else { return [] }
        let curves = parseCurves(curvesJSON, style: style)
        guard !curves.isEmpty else { return [] }

        // One region per curve (full width, divided vertically)
        let height = plotRect.height / CGFloat(curves.count)
        return curves.enumerated().map { i, curve in
            let rect = CGRect(x: plotRect.minX, y: plotRect.minY + height * CGFloat(i),
                              width: plotRect.width, height: height)
            return ChartHitRegion(
                kind: .line, rect: rect, groupIndex: i, groupName: curve.name,
                label: curve.name, metadata: ["n": "\(curve.n)"]
            )
        }
    }

    // MARK: - Parsing

    private struct KMCurve {
        let name: String
        let times: [Double]
        let survival: [Double]
        let censoredTimes: [Double]
        let censoredSurvival: [Double]
        let n: Int
        let color: String
    }

    private static func parseCurves(_ json: [JSONValue], style: StyleSpec) -> [KMCurve] {
        var curves: [KMCurve] = []
        for (i, item) in json.enumerated() {
            guard let obj = item.objectValue else { continue }
            curves.append(KMCurve(
                name: obj["name"]?.stringValue ?? "Group \(i + 1)",
                times: obj["times"]?.doubleArray ?? [],
                survival: obj["survival"]?.doubleArray ?? [],
                censoredTimes: obj["censored_times"]?.doubleArray ?? [],
                censoredSurvival: obj["censored_survival"]?.doubleArray ?? [],
                n: obj["n"]?.doubleValue.map(Int.init) ?? 0,
                color: obj["color"]?.stringValue ?? colorForIndex(i, style: style)
            ))
        }
        return curves
    }
}
