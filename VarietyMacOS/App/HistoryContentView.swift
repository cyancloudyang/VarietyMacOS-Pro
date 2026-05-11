//
//  HistoryContentView.swift
//  VarietyMacOS
//
//  Displays wallpaper change history grouped by date
//

import SwiftUI
import SwiftData

/// Displays wallpaper change history grouped by date
struct HistoryContentView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedWallpaper: Wallpaper?
    @Query(sort: \HistoryEntry.timestamp, order: .reverse) private var entries: [HistoryEntry]
    @State private var searchText = ""

    private var filteredEntries: [HistoryEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { entry in
            entry.wallpaper?.displayTitle.localizedCaseInsensitiveContains(searchText) ?? false
                || entry.wallpaper?.displayAuthor.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    private var groupedSections: [(String, [HistoryEntry])] {
        groupedByDate(filteredEntries)
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyStateView
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                historyList
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: entries.isEmpty)
        .navigationTitle("History")
        .searchable(text: $searchText, prompt: "Search history...")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No history yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Wallpapers will appear here as they change")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            ForEach(groupedSections, id: \.0) { section in
                Section(header: Text(section.0)) {
                    ForEach(section.1) { entry in
                        historyRow(entry: entry)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - History Row

    private func historyRow(entry: HistoryEntry) -> some View {
        Button(action: {
            if let wallpaper = entry.wallpaper {
                selectedWallpaper = wallpaper
            }
        }) {
            HStack(spacing: 12) {
                if let wallpaper = entry.wallpaper {
                    ThumbnailImageView(wallpaper: wallpaper)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.wallpaper?.displayTitle ?? "Untitled")
                        .font(.body)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Image(systemName: entry.source.iconName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(entry.source.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .cornerRadius(3)
                }

                Spacer()

                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }

    // MARK: - Date Grouping

    private func groupedByDate(_ entries: [HistoryEntry]) -> [(String, [HistoryEntry])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        let weekAgo = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date())

        var sections: [(String, [HistoryEntry])] = []

        let todayEntries = entries.filter { $0.timestamp >= today }
        let yesterdayEntries = entries.filter { $0.timestamp >= yesterday && $0.timestamp < today }
        let weekEntries = entries.filter { $0.timestamp >= weekAgo && $0.timestamp < yesterday }
        let olderEntries = entries.filter { $0.timestamp < weekAgo }

        if !todayEntries.isEmpty {
            sections.append(("Today", todayEntries))
        }
        if !yesterdayEntries.isEmpty {
            sections.append(("Yesterday", yesterdayEntries))
        }
        if !weekEntries.isEmpty {
            sections.append(("This Week", weekEntries))
        }
        if !olderEntries.isEmpty {
            sections.append(("Older", olderEntries))
        }

        return sections
    }
}
