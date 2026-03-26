// RenderStyle.swift — Predefined rendering style presets.
// Each preset configures FormatGraphSettings and FormatAxesSettings
// to mimic the visual style of popular plotting libraries.
// Purely client-side — no engine calls.

import Foundation

enum RenderStyle: String, CaseIterable, Identifiable, Codable {
    case `default` = "default"
    case prism = "prism"
    case ggplot2 = "ggplot2"
    case matplotlib = "matplotlib"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .default:    return "Default"
        case .prism:      return "Prism"
        case .ggplot2:    return "ggplot2"
        case .matplotlib: return "Matplotlib"
        }
    }

    var description: String {
        switch self {
        case .default:    return "Clean default style with light grid"
        case .prism:      return "GraphPad Prism: L-shaped axes, no grid, bold"
        case .ggplot2:    return "R ggplot2: gray background, white grid lines"
        case .matplotlib: return "Python matplotlib: full frame, dashed grid"
        }
    }

    // MARK: - Color Palettes

    var palette: [String] {
        switch self {
        case .default, .prism:
            // Prism 10-color palette
            return [
                "#E8453C", "#2274A5", "#32936F", "#F18F01", "#A846A0",
                "#6B4226", "#048A81", "#D4AC0D", "#3B1F2B", "#44BBA4",
            ]
        case .ggplot2:
            // ggplot2 default (hue_pal) approximation
            return [
                "#F8766D", "#A3A500", "#00BF7D", "#00B0F6", "#E76BF3",
                "#D89000", "#39B600", "#00BFC4", "#9590FF", "#FF62BC",
            ]
        case .matplotlib:
            // matplotlib tab10
            return [
                "#1F77B4", "#FF7F0E", "#2CA02C", "#D62728", "#9467BD",
                "#8C564B", "#E377C2", "#7F7F7F", "#BCBD22", "#17BECF",
            ]
        }
    }

    // MARK: - Apply Preset

    /// Apply this render style to the given format settings.
    /// Preserves user-specific data (like axis titles) but sets all visual properties.
    func apply(to graph: FormatGraphSettings, axes: FormatAxesSettings) {
        switch self {
        case .default:
            applyDefault(graph: graph, axes: axes)
        case .prism:
            applyPrism(graph: graph, axes: axes)
        case .ggplot2:
            applyGgplot2(graph: graph, axes: axes)
        case .matplotlib:
            applyMatplotlib(graph: graph, axes: axes)
        }
    }

    // MARK: - Default

    private func applyDefault(graph: FormatGraphSettings, axes: FormatAxesSettings) {
        // Graph settings
        graph.barBorderThickness = 0.8
        graph.barBorderColor = "#000000"
        graph.barWidth = 0.6
        graph.errorBarColor = "#222222"
        graph.errorBarThickness = 1.0
        graph.errorBarStyle = .tCap
        graph.lineThickness = 1.5
        graph.symbolSize = 6.0

        // Axes settings
        axes.axisThickness = 1.0
        axes.axisColor = "#000000"
        axes.plotAreaColor = "clear"
        axes.pageBackground = "clear"
        axes.frameStyle = .noFrame
        axes.hideAxes = .showBoth
        axes.majorGrid = .solid
        axes.majorGridColor = "#E5E5E5"
        axes.majorGridThickness = 0.5
        axes.minorGrid = .none
        axes.xAxisTickDirection = .out
        axes.yAxisTickDirection = .out
        axes.xAxisTickLength = 5
        axes.yAxisTickLength = 5
        axes.globalFontName = "Helvetica"
        axes.chartTitleFontSize = 14
        axes.xAxisTitleFontSize = 12
        axes.yAxisTitleFontSize = 12
        axes.xAxisLabelFontSize = 10
        axes.yAxisLabelFontSize = 10
    }

    // MARK: - Prism

    private func applyPrism(graph: FormatGraphSettings, axes: FormatAxesSettings) {
        // Graph settings — clean, bold
        graph.barBorderThickness = 0.0
        graph.barWidth = 0.65
        graph.errorBarColor = "#000000"
        graph.errorBarThickness = 1.2
        graph.errorBarStyle = .tCap
        graph.lineThickness = 2.0
        graph.symbolSize = 7.0
        graph.symbolBorderThickness = 0.0

        // Axes settings — L-shaped (left + bottom only), no grid
        axes.axisThickness = 1.5
        axes.axisColor = "#000000"
        axes.plotAreaColor = "clear"
        axes.pageBackground = "clear"
        axes.frameStyle = .noFrame
        axes.hideAxes = .showBoth
        axes.majorGrid = .none
        axes.minorGrid = .none
        axes.xAxisTickDirection = .out
        axes.yAxisTickDirection = .out
        axes.xAxisTickLength = 6
        axes.yAxisTickLength = 6
        axes.globalFontName = "Arial"
        axes.chartTitleFontSize = 16
        axes.xAxisTitleFontSize = 13
        axes.yAxisTitleFontSize = 13
        axes.xAxisLabelFontSize = 11
        axes.yAxisLabelFontSize = 11
    }

    // MARK: - ggplot2

    private func applyGgplot2(graph: FormatGraphSettings, axes: FormatAxesSettings) {
        // Graph settings — softer, wider bars
        graph.barBorderThickness = 0.0
        graph.barWidth = 0.7
        graph.errorBarColor = "#333333"
        graph.errorBarThickness = 0.8
        graph.errorBarStyle = .tCap
        graph.lineThickness = 1.0
        graph.symbolSize = 5.0
        graph.symbolBorderThickness = 0.0

        // Axes settings — gray background, white grid, no axis lines
        axes.axisThickness = 0.0
        axes.axisColor = "#636363"
        axes.plotAreaColor = "#EBEBEB"
        axes.pageBackground = "clear"
        axes.frameStyle = .noFrame
        axes.hideAxes = .showBoth
        axes.majorGrid = .solid
        axes.majorGridColor = "#FFFFFF"
        axes.majorGridThickness = 0.8
        axes.minorGrid = .none
        axes.xAxisTickDirection = .none
        axes.yAxisTickDirection = .none
        axes.xAxisTickLength = 0
        axes.yAxisTickLength = 0
        axes.globalFontName = "Helvetica"
        axes.chartTitleFontSize = 13
        axes.xAxisTitleFontSize = 11
        axes.yAxisTitleFontSize = 11
        axes.xAxisLabelFontSize = 9
        axes.yAxisLabelFontSize = 9
    }

    // MARK: - Matplotlib

    private func applyMatplotlib(graph: FormatGraphSettings, axes: FormatAxesSettings) {
        // Graph settings
        graph.barBorderThickness = 0.5
        graph.barBorderColor = "#000000"
        graph.barWidth = 0.6
        graph.errorBarColor = "#000000"
        graph.errorBarThickness = 1.0
        graph.errorBarStyle = .line
        graph.lineThickness = 1.5
        graph.symbolSize = 6.0
        graph.symbolBorderThickness = 0.5

        // Axes settings — full frame, dashed grid
        axes.axisThickness = 1.0
        axes.axisColor = "#000000"
        axes.plotAreaColor = "clear"
        axes.pageBackground = "clear"
        axes.frameStyle = .plain
        axes.hideAxes = .showBoth
        axes.majorGrid = .dashed
        axes.majorGridColor = "#CCCCCC"
        axes.majorGridThickness = 0.5
        axes.minorGrid = .none
        axes.xAxisTickDirection = .out
        axes.yAxisTickDirection = .out
        axes.xAxisTickLength = 4
        axes.yAxisTickLength = 4
        axes.globalFontName = "Helvetica"  // DejaVu Sans not available, Helvetica close
        axes.chartTitleFontSize = 14
        axes.xAxisTitleFontSize = 12
        axes.yAxisTitleFontSize = 12
        axes.xAxisLabelFontSize = 10
        axes.yAxisLabelFontSize = 10
    }
}
