// Graph.swift — A graph within an experiment, linked to a specific DataTable.
// Contains chart type, config, cached spec, and format settings.

import Foundation
import RefractionRenderer

@Observable
final class Graph: Identifiable {
    let id: UUID
    var label: String
    var dataTableID: UUID          // which DataTable this graph reads from
    var chartType: ChartType
    var chartConfig: ChartConfig
    var chartSpec: ChartSpec?      // cached engine result
    var formatSettings: FormatGraphSettings = FormatGraphSettings()
    var formatAxesSettings: FormatAxesSettings = FormatAxesSettings()
    var renderStyle: RenderStyle = .default
    var isLoading: Bool = false
    var rawJSON: String = ""

    /// Zoom level for the chart canvas (0.25x to 4.0x, default 1.0).
    var zoomLevel: Double = 1.0

    /// Apply a render style preset, updating format settings in place.
    func applyRenderStyle(_ style: RenderStyle) {
        renderStyle = style
        style.apply(to: formatSettings, axes: formatAxesSettings)
    }

    init(
        id: UUID = UUID(),
        label: String,
        dataTableID: UUID,
        chartType: ChartType
    ) {
        self.id = id
        self.label = label
        self.dataTableID = dataTableID
        self.chartType = chartType
        self.chartConfig = ChartConfig()
    }

    var sfSymbol: String { "chart.bar.fill" }
}
