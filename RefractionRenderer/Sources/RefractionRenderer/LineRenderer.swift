// LineRenderer.swift — Draws line graphs connecting data points.
// Supports XY data (from dedicated analyzer) and category data (from groups).

import SwiftUI

public enum LineRenderer {

    public static func draw(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec,
        data: [String: JSONValue]? = nil
    ) {
        // Prefer XY data payload from dedicated analyzer
        if let data = data, let seriesJSON = data["series"]?.arrayValue {
            drawXY(in: context, plotRect: plotRect, data: data, series: seriesJSON, style: style)
            return
        }

        // Fallback: category line from generic groups
        drawCategory(in: context, plotRect: plotRect, groups: groups, style: style)
    }

    // MARK: - Line stroke style helper

    private static func lineStrokeStyle(_ style: StyleSpec) -> StrokeStyle {
        let lw = CGFloat(style.lineThickness)
        switch style.lineStyle {
        case "dashed": return StrokeStyle(lineWidth: lw, dash: [8, 5])
        case "dotted": return StrokeStyle(lineWidth: lw, dash: [2, 4])
        default:       return StrokeStyle(lineWidth: lw)
        }
    }

    // MARK: - XY line (dedicated analyzer)

    private static func drawXY(
        in context: GraphicsContext,
        plotRect: CGRect,
        data: [String: JSONValue],
        series: [JSONValue],
        style: StyleSpec
    ) {
        // Compute ranges
        var xMin = Double.infinity, xMax = -Double.infinity
        var yMin = Double.infinity, yMax = -Double.infinity

        struct ParsedPoint { let x: Double; let y: Double; let yError: Double }
        struct ParsedSeries { let name: String; let points: [ParsedPoint]; let color: String }

        var parsedSeries: [ParsedSeries] = []

        for (si, seriesVal) in series.enumerated() {
            guard let obj = seriesVal.objectValue,
                  let name = obj["name"]?.stringValue,
                  let pointsJSON = obj["points"]?.arrayValue else { continue }

            let color = obj["color"]?.stringValue ?? StyleSpec.defaultColors[si % StyleSpec.defaultColors.count]
            var points: [ParsedPoint] = []

            for pVal in pointsJSON {
                guard let pObj = pVal.objectValue,
                      let x = pObj["x"]?.doubleValue,
                      let yMean = pObj["y_mean"]?.doubleValue else { continue }

                let yErr = pObj["y_error"]?.doubleValue ?? 0

                xMin = min(xMin, x); xMax = max(xMax, x)
                yMin = min(yMin, yMean - yErr); yMax = max(yMax, yMean + yErr)

                points.append(ParsedPoint(x: x, y: yMean, yError: yErr))
            }

            parsedSeries.append(ParsedSeries(name: name, points: points, color: color))
        }

        guard xMax > xMin else { return }
        if yMax <= yMin { yMax = yMin + 1 }

        let xPad = (xMax - xMin) * 0.05
        let yPad = (yMax - yMin) * 0.1
        let xRange = (min: xMin - xPad, max: xMax + xPad)
        let yRange = (min: min(yMin - yPad, 0), max: yMax + yPad)

        let strokeStyle = lineStrokeStyle(style)

        for s in parsedSeries {
            let seriesColor: Color
            if style.lineColor != "auto" && style.lineColor != "#000000" {
                seriesColor = Color(hex: style.lineColor)
            } else {
                seriesColor = Color(hex: s.color)
            }
            let sorted = s.points.sorted { $0.x < $1.x }

            // Draw area fill
            if style.showAreaFill && sorted.count >= 2 {
                var areaPath = Path()
                let firstX = xToCanvas(sorted[0].x, plotRect: plotRect, xRange: xRange)
                let baselineY: CGFloat = style.areaFillPosition == "above" ? plotRect.minY : plotRect.maxY

                areaPath.move(to: CGPoint(x: firstX, y: baselineY))
                for pt in sorted {
                    let cx = xToCanvas(pt.x, plotRect: plotRect, xRange: xRange)
                    let cy = yToCanvas(pt.y, plotRect: plotRect, yRange: yRange)
                    areaPath.addLine(to: CGPoint(x: cx, y: cy))
                }
                let lastX = xToCanvas(sorted.last!.x, plotRect: plotRect, xRange: xRange)
                areaPath.addLine(to: CGPoint(x: lastX, y: baselineY))
                areaPath.closeSubpath()

                let fillColor = style.areaFillColor == "#000000"
                    ? seriesColor
                    : Color(hex: style.areaFillColor)
                context.fill(areaPath, with: .color(fillColor.opacity(style.areaFillAlpha)))
            }

            // Draw connecting line
            if sorted.count >= 2 {
                var path = Path()
                for (i, pt) in sorted.enumerated() {
                    let cx = xToCanvas(pt.x, plotRect: plotRect, xRange: xRange)
                    let cy = yToCanvas(pt.y, plotRect: plotRect, yRange: yRange)
                    if i == 0 { path.move(to: CGPoint(x: cx, y: cy)) }
                    else { path.addLine(to: CGPoint(x: cx, y: cy)) }
                }
                context.stroke(path, with: .color(seriesColor), style: strokeStyle)
            }

            // Draw markers + error bars
            if style.showPoints {
                for pt in sorted {
                    let cx = xToCanvas(pt.x, plotRect: plotRect, xRange: xRange)
                    let cy = yToCanvas(pt.y, plotRect: plotRect, yRange: yRange)

                    // Error bars
                    if style.errorType != "none" && pt.yError > 0 {
                        let errColor = Color(hex: style.errorBarColor)
                        let errThick = CGFloat(style.errorBarThickness)
                        let top = yToCanvas(pt.y + pt.yError, plotRect: plotRect, yRange: yRange)
                        let bot = yToCanvas(pt.y - pt.yError, plotRect: plotRect, yRange: yRange)
                        let capW: CGFloat = 4
                        drawLine(in: context, from: CGPoint(x: cx, y: top), to: CGPoint(x: cx, y: bot),
                                 color: errColor, width: errThick)
                        if style.errorBarStyle == "t_cap" {
                            drawLine(in: context, from: CGPoint(x: cx - capW, y: top), to: CGPoint(x: cx + capW, y: top),
                                     color: errColor, width: errThick)
                            drawLine(in: context, from: CGPoint(x: cx - capW, y: bot), to: CGPoint(x: cx + capW, y: bot),
                                     color: errColor, width: errThick)
                        }
                    }

                    // Marker
                    let r = CGFloat(style.pointSize) / 2
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(seriesColor))
                    context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 1.0)
                }
            }
        }

        // X axis tick labels
        let nXTicks = min(Int(xMax - xMin) + 1, 10)
        let xStep = (xMax - xMin) / Double(max(nXTicks - 1, 1))
        for i in 0..<nXTicks {
            let val = xMin + Double(i) * xStep
            let cx = xToCanvas(val, plotRect: plotRect, xRange: xRange)
            let label = Text(formatNum(val))
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#222222"))
            context.draw(label, at: CGPoint(x: cx, y: plotRect.maxY + 14), anchor: .top)
        }
    }

    // MARK: - Category line (fallback for groups)

    private static func drawCategory(
        in context: GraphicsContext,
        plotRect: CGRect,
        groups: [GroupData],
        style: StyleSpec
    ) {
        guard !groups.isEmpty else { return }

        let yRange = computeYRange(groups: groups, errorType: style.errorType)
        let groupWidth = plotRect.width / CGFloat(groups.count)

        var points: [(x: CGFloat, y: CGFloat, color: Color)] = []
        for (i, group) in groups.enumerated() {
            guard let mean = group.values.mean else { continue }
            let x = plotRect.minX + (CGFloat(i) + 0.5) * groupWidth
            let y = yToCanvas(mean, plotRect: plotRect, yRange: yRange)
            let color = Color(hex: colorForIndex(i, style: style))
            points.append((x, y, color))
        }

        guard points.count >= 2 else { return }

        let strokeStyle = lineStrokeStyle(style)
        let lineColor: Color
        if style.lineColor != "auto" && style.lineColor != "#000000" {
            lineColor = Color(hex: style.lineColor)
        } else {
            lineColor = Color(hex: colorForIndex(0, style: style))
        }

        // Area fill
        if style.showAreaFill {
            var areaPath = Path()
            let baselineY: CGFloat = style.areaFillPosition == "above" ? plotRect.minY : plotRect.maxY
            areaPath.move(to: CGPoint(x: points[0].x, y: baselineY))
            for p in points {
                areaPath.addLine(to: CGPoint(x: p.x, y: p.y))
            }
            areaPath.addLine(to: CGPoint(x: points.last!.x, y: baselineY))
            areaPath.closeSubpath()

            let fillColor = style.areaFillColor == "#000000" ? lineColor : Color(hex: style.areaFillColor)
            context.fill(areaPath, with: .color(fillColor.opacity(style.areaFillAlpha)))
        }

        // Line
        var path = Path()
        path.move(to: CGPoint(x: points[0].x, y: points[0].y))
        for i in 1..<points.count {
            path.addLine(to: CGPoint(x: points[i].x, y: points[i].y))
        }
        context.stroke(path, with: .color(lineColor), style: strokeStyle)

        // Points
        if style.showPoints {
            for p in points {
                let r = CGFloat(style.pointSize) / 2
                let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(p.color))
                context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 1.0)
            }
        }
    }

    private static func formatNum(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e6 { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
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
                kind: .line, rect: CGRect(x: x, y: plotRect.minY, width: groupWidth, height: plotRect.height),
                groupIndex: i, groupName: group.name, label: group.name,
                metadata: ["n": "\(group.values.n)"]
            )
        }
    }
}
