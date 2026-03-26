// ExportChartDialog.swift — Export chart with format, resolution, and dimension controls.

import SwiftUI
import UniformTypeIdentifiers
import RefractionRenderer

struct ExportChartDialog: View {

    @Environment(\.dismiss) private var dismiss

    let spec: ChartSpec
    let graphLabel: String

    // Export settings
    @State private var format: ExportFormat = .png
    @State private var widthPt: Double = 800
    @State private var heightPt: Double = 600
    @State private var scale: Double = 2.0   // 1x, 2x, 3x
    @State private var preset: DimensionPreset = .custom
    @State private var isExporting = false
    @State private var exportError: String?

    enum ExportFormat: String, CaseIterable, Identifiable {
        case png = "PNG"
        case pdf = "PDF"
        case tiff = "TIFF"
        case jpeg = "JPEG"

        var id: String { rawValue }

        var utType: UTType {
            switch self {
            case .png:  return .png
            case .pdf:  return .pdf
            case .tiff: return .tiff
            case .jpeg: return .jpeg
            }
        }

        var fileExtension: String {
            switch self {
            case .png:  return "png"
            case .pdf:  return "pdf"
            case .tiff: return "tiff"
            case .jpeg: return "jpg"
            }
        }
    }

    enum DimensionPreset: String, CaseIterable, Identifiable {
        case custom = "Custom"
        case nature = "Nature (89mm)"
        case natureFull = "Nature Full (183mm)"
        case science = "Science (90mm)"
        case scienceFull = "Science Full (180mm)"
        case cell = "Cell (85mm)"
        case cellFull = "Cell Full (174mm)"
        case presentation = "Presentation (16:9)"
        case square = "Square (1:1)"

        var id: String { rawValue }

        /// Returns (width, height) in points. nil = keep current.
        var dimensions: (Double, Double)? {
            switch self {
            case .custom:           return nil
            case .nature:           return (252, 189)     // 89mm @ 72dpi ≈ 252pt, 3:4
            case .natureFull:       return (519, 389)     // 183mm
            case .science:          return (255, 191)     // 90mm
            case .scienceFull:      return (510, 383)     // 180mm
            case .cell:             return (241, 181)     // 85mm
            case .cellFull:         return (493, 370)     // 174mm
            case .presentation:     return (960, 540)     // 16:9
            case .square:           return (600, 600)     // 1:1
            }
        }
    }

    private var pixelWidth: Int { Int(widthPt * scale) }
    private var pixelHeight: Int { Int(heightPt * scale) }

    private var dpiLabel: String {
        let dpi = Int(scale * 72)
        return "\(dpi) DPI"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Export Chart")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Format
                LabeledContent("Format") {
                    Picker("", selection: $format) {
                        ForEach(ExportFormat.allCases) { fmt in
                            Text(fmt.rawValue).tag(fmt)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                }

                Divider()

                // Preset
                LabeledContent("Preset") {
                    Picker("", selection: $preset) {
                        ForEach(DimensionPreset.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                    .onChange(of: preset) { _, newPreset in
                        if let dims = newPreset.dimensions {
                            widthPt = dims.0
                            heightPt = dims.1
                        }
                    }
                }

                // Dimensions
                HStack(spacing: 16) {
                    LabeledContent("Width") {
                        TextField("", value: $widthPt, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                        Text("pt")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Height") {
                        TextField("", value: $heightPt, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                        Text("pt")
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: widthPt) { _, _ in preset = .custom }
                .onChange(of: heightPt) { _, _ in preset = .custom }

                // Scale / Resolution
                LabeledContent("Resolution") {
                    HStack {
                        Picker("", selection: $scale) {
                            Text("1x (72 DPI)").tag(1.0)
                            Text("2x (144 DPI)").tag(2.0)
                            Text("3x (216 DPI)").tag(3.0)
                            Text("4x (288 DPI)").tag(4.0)
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }

                // Output info
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Output: \(pixelWidth) × \(pixelHeight) px  ·  \(dpiLabel)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                if let exportError {
                    Text(exportError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(20)

            Divider()

            // Buttons
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Export...") { doExport() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(isExporting)
            }
            .padding(16)
        }
        .frame(width: 460)
    }

    // MARK: - Export

    private func doExport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.utType]
        panel.nameFieldStringValue = "\(graphLabel).\(format.fileExtension)"
        panel.title = "Save Chart"
        panel.prompt = "Save"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        isExporting = true
        exportError = nil

        let renderer = ImageRenderer(content:
            ChartCanvasView(spec: spec)
                .frame(width: widthPt, height: heightPt)
        )
        renderer.scale = scale

        switch format {
        case .pdf:
            renderer.render { size, render in
                var box = CGRect(origin: .zero, size: size)
                guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else {
                    exportError = "Failed to create PDF context"
                    return
                }
                context.beginPDFPage(nil)
                render(context)
                context.endPDFPage()
                context.closePDF()
            }

        case .png:
            guard let image = renderer.nsImage,
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let data = bitmap.representation(using: .png, properties: [:]) else {
                exportError = "Failed to render PNG"
                isExporting = false
                return
            }
            do { try data.write(to: url) }
            catch { exportError = "Save failed: \(error.localizedDescription)" }

        case .tiff:
            guard let image = renderer.nsImage,
                  let data = image.tiffRepresentation else {
                exportError = "Failed to render TIFF"
                isExporting = false
                return
            }
            do { try data.write(to: url) }
            catch { exportError = "Save failed: \(error.localizedDescription)" }

        case .jpeg:
            guard let image = renderer.nsImage,
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
                exportError = "Failed to render JPEG"
                isExporting = false
                return
            }
            do { try data.write(to: url) }
            catch { exportError = "Save failed: \(error.localizedDescription)" }
        }

        isExporting = false
        if exportError == nil {
            DebugLog.shared.logAppEvent("exportChart(\(format.rawValue))", detail: "\(pixelWidth)x\(pixelHeight) → \(url.lastPathComponent)")
            dismiss()
        }
    }
}
