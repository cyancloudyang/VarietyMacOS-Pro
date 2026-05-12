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
    @State private var showingWallhavenConfig = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(WallpaperSourceType.allCases, id: \.self) { sourceType in
                    sourceRow(for: sourceType)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .listStyle(.inset)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: WallpaperSourceType.allCases)

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
                .animation(.easeInOut(duration: 0.2), value: showingAddSource)
            }
            .padding()
        }
        .navigationTitle("Sources")
        .sheet(isPresented: $showingAddSource) {
            AddSourceView()
        }
        .sheet(isPresented: $showingWallhavenConfig) {
            WallhavenSettingsView()
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
                .animation(.easeInOut(duration: 0.2), value: preferences.isSourceEnabled(sourceType))

            VStack(alignment: .leading, spacing: 2) {
                Text(sourceType.displayName)
                    .font(.body)
                    .fontWeight(preferences.isSourceEnabled(sourceType) ? .semibold : .regular)
                    .animation(.easeInOut(duration: 0.2), value: preferences.isSourceEnabled(sourceType))
                Text(sourceType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if sourceType == .wallhaven {
                Button("Configure...") {
                    showingWallhavenConfig = true
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
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: sourceType)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
