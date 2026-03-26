// NewExperimentDialog.swift — Dialog for creating a new experiment.
// User enters a name (default "Experiment N") and clicks Create or Cancel.
// Duplicate names are rejected with inline feedback.

import SwiftUI

struct NewExperimentDialog: View {

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""

    /// Default name: "Experiment N" where N = current count + 1.
    private var defaultName: String {
        "Experiment \(appState.experiments.count + 1)"
    }

    /// Whether the entered name (or default) conflicts with an existing experiment.
    private var isDuplicate: Bool {
        let trimmed = effectiveName
        return appState.experiments.contains { $0.label.trimmingCharacters(in: .whitespaces) == trimmed }
    }

    /// The name that will be used — typed name if non-empty, otherwise the default.
    private var effectiveName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultName : trimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("New Experiment")
                .font(.headline)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField(defaultName, text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { createIfValid() }

                if isDuplicate {
                    Label("An experiment named \"\(effectiveName)\" already exists.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            Divider()

            // Buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createIfValid()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isDuplicate)
            }
            .padding(16)
        }
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func createIfValid() {
        guard !isDuplicate else { return }
        appState.addExperiment(label: effectiveName)
        dismiss()
    }
}
