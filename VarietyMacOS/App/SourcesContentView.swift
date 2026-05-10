//
//  SourcesContentView.swift
//  VarietyMacOS
//
//  Displays and manages wallpaper sources
//

import SwiftUI

/// Displays and manages wallpaper sources
struct SourcesContentView: View {
    @StateObject private var preferences = Preferences.shared
    @State private var showingAddSource = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(WallpaperSourceType.allCases, id: \.self) { sourceType in
                    sourceRow(for: sourceType)
                }
            }
            .listStyle(.inset)

            Divider()

            HStack {
                Text("\(preferences.enabledSources.count) of \(WallpaperSourceType.allCases.count) sources active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Add Source...") {
                    showingAddSource = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Sources")
        .sheet(isPresented: $showingAddSource) {
            AddSourceView()
        }
    }

    // MARK: - Source Row

    @ViewBuilder
    private func sourceRow(for sourceType: WallpaperSourceType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: sourceType.iconName)
                .frame(width: 28, height: 28)
                .foregroundColor(preferences.isSourceEnabled(sourceType) ? .accentColor : .secondary)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(preferences.isSourceEnabled(sourceType) ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(sourceType.displayName)
                    .font(.body)
                    .fontWeight(preferences.isSourceEnabled(sourceType) ? .semibold : .regular)
                Text(sourceType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if sourceType == .wallhaven {
                Button("Configure...") {
                    showingAddSource = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Toggle("", isOn: Binding(
                get: { preferences.isSourceEnabled(sourceType) },
                set: { _ in
                    if preferences.isSourceEnabled(sourceType) {
                        preferences.disableSource(sourceType)
                    } else {
                        preferences.enableSource(sourceType)
                    }
                }
            ))
            .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }
}
