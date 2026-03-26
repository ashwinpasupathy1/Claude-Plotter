// NewGraphDialog.swift — Dialog for creating a new graph.
// Step 1: Pick the data table. Step 2: Pick the chart type. Step 3: Name it.
// Duplicate names within an experiment are rejected.

import SwiftUI

struct NewGraphDialog: View {

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTableID: UUID?
    @State private var selectedChartType: ChartType?
    @State private var name: String = ""
    @State private var nameError: String?

    private var experiment: Experiment? { appState.activeExperiment }

    private var tablesWithData: [DataTable] {
        experiment?.dataTables.filter { $0.hasData } ?? []
    }

    private var validChartTypes: [ChartType] {
        guard let tableID = selectedTableID,
              let experiment else { return [] }
        return experiment.validChartTypes(for: tableID)
    }

    private var effectiveName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? (selectedChartType?.label ?? "Graph") : trimmed
    }

    private var isNameDuplicate: Bool {
        experiment?.hasGraphNamed(effectiveName) ?? false
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("New Graph")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()

            HStack(spacing: 0) {
                // Left: data table picker
                VStack(alignment: .leading, spacing: 0) {
                    Text("Data Table")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    Divider()

                    List(tablesWithData, selection: $selectedTableID) { table in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(table.label)
                                Text(table.tableType.label)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        } icon: {
                            Image(systemName: table.sfSymbol)
                                .foregroundStyle(.secondary)
                        }
                        .tag(table.id)
                    }
                    .listStyle(.sidebar)
                }
                .frame(width: 180)

                Divider()

                // Right: chart type picker
                VStack(alignment: .leading, spacing: 0) {
                    Text("Chart Type")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    Divider()

                    if selectedTableID != nil {
                        List(validChartTypes, selection: $selectedChartType) { chartType in
                            Label(chartType.label, systemImage: chartType.sfSymbol)
                                .tag(chartType)
                        }
                        .listStyle(.sidebar)
                    } else {
                        VStack {
                            Spacer()
                            Text("Select a data table")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 280)

            Divider()

            // Name field
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField(selectedChartType?.label ?? "Graph", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: name) { _, _ in nameError = nil }
                }
                if let nameError {
                    Text(nameError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Create") { create() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedTableID == nil || selectedChartType == nil)
            }
            .padding(16)
        }
        .frame(width: 500)
        .onAppear {
            selectedTableID = tablesWithData.first?.id
        }
        .onChange(of: selectedTableID) { _, _ in
            if let first = validChartTypes.first {
                selectedChartType = first
            } else {
                selectedChartType = nil
            }
            name = ""
            nameError = nil
        }
        .onChange(of: selectedChartType) { _, _ in
            // Reset name to default when chart type changes
            name = ""
            nameError = nil
        }
    }

    private func create() {
        guard let tableID = selectedTableID,
              let chartType = selectedChartType else { return }

        // Check for duplicate name
        if isNameDuplicate {
            nameError = "A graph named \"\(effectiveName)\" already exists. Choose a different name."
            return
        }

        appState.addGraph(chartType: chartType, dataTableID: tableID, label: effectiveName)
        dismiss()
    }
}
