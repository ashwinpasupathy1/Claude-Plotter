// Analysis.swift — A statistical analysis within an experiment, linked to a specific DataTable.
// Contains analysis type, results, and notes.

import Foundation
import RefractionRenderer

@Observable
final class Analysis: Identifiable {
    let id: UUID
    var label: String
    var dataTableID: UUID          // which DataTable this analysis reads from
    var analysisType: String
    var statsResults: StatsResult?
    var notes: String = ""
    var rawJSON: String = ""

    init(
        id: UUID = UUID(),
        label: String,
        dataTableID: UUID,
        analysisType: String = ""
    ) {
        self.id = id
        self.label = label
        self.dataTableID = dataTableID
        self.analysisType = analysisType
    }

    var sfSymbol: String { "list.clipboard" }
}
