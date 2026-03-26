// ArchitectureGuideDialog.swift — Searchable developer reference for the Refraction codebase.
// Shows architecture entries organized by category with expandable details, method signatures,
// and related file paths. Modeled after StatsWikiDialog.

import SwiftUI

struct ArchitectureGuideDialog: View {

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: ArchitectureCategory? = nil
    @State private var expandedEntryIDs: Set<String> = []

    private var filteredEntries: [ArchitectureEntry] {
        let entries: [ArchitectureEntry]
        if let cat = selectedCategory {
            entries = ArchitectureGuideCatalog.entries(in: cat)
        } else {
            entries = ArchitectureGuideCatalog.all
        }

        guard !searchText.isEmpty else { return entries }

        let query = searchText.lowercased()
        return entries.filter { entry in
            entry.title.lowercased().contains(query) ||
            entry.summary.lowercased().contains(query) ||
            entry.methods.contains { $0.signature.lowercased().contains(query) ||
                                     $0.description.lowercased().contains(query) } ||
            entry.relatedFiles.contains { $0.lowercased().contains(query) }
        }
    }

    /// Entries grouped by category, preserving category order.
    private var groupedEntries: [(ArchitectureCategory, [ArchitectureEntry])] {
        let entries = filteredEntries
        var result: [(ArchitectureCategory, [ArchitectureEntry])] = []
        for cat in ArchitectureCategory.allCases {
            let inCat = entries.filter { $0.category == cat }
            if !inCat.isEmpty {
                result.append((cat, inCat))
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(.indigo)
                Text("Architecture Guide")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            HSplitView {
                // MARK: - Left Sidebar: Categories
                VStack(alignment: .leading, spacing: 0) {
                    // "All" button
                    sidebarButton(
                        label: "All",
                        icon: "square.grid.2x2",
                        isSelected: selectedCategory == nil,
                        count: ArchitectureGuideCatalog.all.count
                    ) {
                        selectedCategory = nil
                    }

                    Divider()
                        .padding(.vertical, 4)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(ArchitectureCategory.allCases) { cat in
                                sidebarButton(
                                    label: cat.rawValue,
                                    icon: cat.icon,
                                    isSelected: selectedCategory == cat,
                                    count: ArchitectureGuideCatalog.entries(in: cat).count
                                ) {
                                    selectedCategory = cat
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 170, idealWidth: 190, maxWidth: 220)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)

                // MARK: - Main Content
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search entries, methods, files...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Results count
                    HStack {
                        Text("\(filteredEntries.count) entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Expand All") {
                            expandedEntryIDs = Set(filteredEntries.map(\.id))
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                        Text("/")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                        Button("Collapse All") {
                            expandedEntryIDs.removeAll()
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                    Divider()

                    // Entry list
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(groupedEntries, id: \.0) { category, entries in
                                // Category header
                                if selectedCategory == nil {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(category.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.top, 8)
                                }

                                ForEach(entries) { entry in
                                    entryCard(entry)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 900, height: 720)
    }

    // MARK: - Sidebar Button

    private func sidebarButton(
        label: String,
        icon: String,
        isSelected: Bool,
        count: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .frame(width: 16)
                Text(label)
                    .font(.callout)
                    .lineLimit(1)
                Spacer()
                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }

    // MARK: - Entry Card

    private func entryCard(_ entry: ArchitectureEntry) -> some View {
        let isExpanded = expandedEntryIDs.contains(entry.id)

        return GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title)
                            .font(.callout)
                            .fontWeight(.semibold)
                        Text(entry.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        if !entry.methods.isEmpty {
                            Label("\(entry.methods.count)", systemImage: "function")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.purple.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        if !entry.relatedFiles.isEmpty {
                            Label("\(entry.relatedFiles.count)", systemImage: "doc")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedEntryIDs.remove(entry.id)
                        } else {
                            expandedEntryIDs.insert(entry.id)
                        }
                    }
                }

                // Expanded content
                if isExpanded {
                    Divider()

                    // Details
                    Text(entry.details)
                        .font(.system(.caption, design: .default))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)

                    // Related files
                    if !entry.relatedFiles.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Related Files", systemImage: "folder")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ForEach(entry.relatedFiles, id: \.self) { file in
                                Text(file)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Methods
                    if !entry.methods.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Methods & Signatures", systemImage: "function")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)

                            ForEach(entry.methods) { method in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(method.signature)
                                        .font(.system(.caption2, design: .monospaced))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.purple)
                                    Text(method.description)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.purple.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
