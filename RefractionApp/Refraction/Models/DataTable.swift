// DataTable.swift — A data table within an experiment.
// Each data table has a type (Column, XY, etc.) and an optional file path.
// Graphs and analyses reference data tables by ID.

import Foundation

@Observable
final class DataTable: Identifiable {
    let id: UUID
    var label: String
    var tableType: TableType
    var dataFilePath: String?
    var originalFileName: String?   // original uploaded filename (e.g. "drug_data.xlsx")

    /// Whether data has been loaded into this table.
    var hasData: Bool {
        dataFilePath != nil && !dataFilePath!.isEmpty
    }

    /// Valid chart types based on table type.
    var availableChartTypes: [ChartType] {
        tableType.validChartTypes
    }

    init(
        id: UUID = UUID(),
        label: String,
        tableType: TableType,
        dataFilePath: String? = nil,
        originalFileName: String? = nil
    ) {
        self.id = id
        self.label = label
        self.tableType = tableType
        self.dataFilePath = dataFilePath
        self.originalFileName = originalFileName
    }

    var sfSymbol: String { "tablecells" }
}
