import SwiftUI
import Combine

/// Settings view for configuring wallpaper sources and preferences
struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var preferences = Preferences.shared
  @State private var selectedTab: SettingsTab = .general

  enum SettingsTab: String, CaseIterable {
    case general = "General"
    case sources = "Sources"
    case download = "Download"
    case about = "About"
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header with Done button
      HStack {
        Spacer()
        Button("Done") {
          dismiss()
        }
        .buttonStyle(.bordered)
        .padding(.trailing, 8)
        .padding(.top, 8)
      }

      TabView(selection: $selectedTab) {
        GeneralSettingsView()
          .tabItem {
            Label("General", systemImage: "gear")
          }
          .tag(SettingsTab.general)

        SourcesSettingsView()
          .tabItem {
            Label("Sources", systemImage: "photo.stack")
          }
          .tag(SettingsTab.sources)

        DownloadSettingsView()
          .tabItem {
            Label("Download", systemImage: "arrow.down.circle")
          }
          .tag(SettingsTab.download)

        AboutSettingsView()
          .tabItem {
            Label("About", systemImage: "info.circle")
          }
          .tag(SettingsTab.about)
      }
      .frame(width: 500, height: 400)
    }
    .onExitCommand {
      dismiss()
    }
  }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @StateObject private var preferences = Preferences.shared
    
    var body: some View {
        Form {
            Section("Wallpaper Change") {
                Picker("Change interval:", selection: $preferences.changeInterval) {
                    Text("5 minutes").tag(300.0)
                    Text("15 minutes").tag(900.0)
                    Text("30 minutes").tag(1800.0)
                    Text("1 hour").tag(3600.0)
                    Text("3 hours").tag(10800.0)
                    Text("Daily").tag(86400.0)
                }
                .pickerStyle(DefaultPickerStyle())
                
                Toggle("Change on start", isOn: $preferences.changeOnStart)
                Toggle("Show notifications", isOn: $preferences.showNotifications)
            }
            
            Section("Display") {
                Picker("Fill mode:", selection: $preferences.fillMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                
                Toggle("Change on all screens", isOn: $preferences.changeAllScreens)
            }
        }
        .padding()
    }
}

// MARK: - Sources Settings
struct SourcesSettingsView: View {
    @StateObject private var preferences = Preferences.shared
    @State private var showingAddSource = false
    
    var body: some View {
        VStack {
            List {
                    ForEach(preferences.enabledSources, id: \.self) { sourceType in
                        SourceConfigRow(sourceType: sourceType)
                    }
                    .onMove { from, to in
                        preferences.enabledSources.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { indexSet in
                        preferences.enabledSources.remove(atOffsets: indexSet)
                    }
            }
            
            HStack {
                Button("Add Source...") {
                    showingAddSource = true
                }
                
                Spacer()
                
                Button("Configure Selected") {
                    // Open configuration for selected source
                }
                    .disabled(preferences.enabledSources.isEmpty)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddSource) {
            AddSourceView()
        }
    }
}

/// Row for source configuration
struct SourceConfigRow: View {
  let sourceType: WallpaperSourceType
  @StateObject private var preferences = Preferences.shared
  @State private var showingConfig = false
  
  var body: some View {
    HStack {
      Image(systemName: sourceType.iconName)
        .frame(width: 24)
      
      VStack(alignment: .leading) {
        Text(sourceType.displayName)
          .font(.body)
        Text(sourceType.description)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      Spacer()
      
      if sourceType == .wallhaven {
        Button("Configure...") {
          showingConfig = true
        }
        .buttonStyle(.bordered)
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
      .toggleStyle(SwitchToggleStyle())
    }
    .padding(.vertical, 4)
    .sheet(isPresented: $showingConfig) {
      WallhavenSettingsView()
    }
  }
}

// MARK: - Download Settings
struct DownloadSettingsView: View {
    @StateObject private var preferences = Preferences.shared
    
    var body: some View {
        Form {
            Section("Download Options") {
                Toggle("Enable downloads", isOn: $preferences.downloadEnabled)
                
                if preferences.downloadEnabled {
                    TextField("Download folder:", text: $preferences.downloadFolder)
                    
                    HStack {
                        Slider(value: $preferences.maxDownloadSize, in: 1...50, step: 1)
                        Text("\(Int(preferences.maxDownloadSize)) MB max")
                            .frame(width: 80)
                    }
                    
                    Picker("Image quality:", selection: $preferences.imageQuality) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                        Text("Original").tag("original")
                    }
                }
            }
            
            Section("Bandwidth") {
                Toggle("Limit download speed", isOn: $preferences.limitDownloadSpeed)
                
                if preferences.limitDownloadSpeed {
                    HStack {
                        Slider(value: $preferences.maxDownloadSpeed, in: 100...10000, step: 100)
                        Text("\(Int(preferences.maxDownloadSpeed)) KB/s")
                            .frame(width: 100)
                    }
                }
            }
        }
        .padding()
        .disabled(!preferences.downloadEnabled)
    }
}

// MARK: - About Settings
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("VarietyMacOS Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .foregroundColor(.secondary)

            Text("Pro wallpaper management for your Mac")
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical)

            HStack(spacing: 20) {
                Link("Website", destination: URL(string: "https://github.com/cyancloudyang/VarietyMacOS-Pro")!)
                Link("GitHub", destination: URL(string: "https://github.com/cyancloudyang/VarietyMacOS-Pro")!)
                Link("Report Issue", destination: URL(string: "https://github.com/cyancloudyang/VarietyMacOS-Pro/issues")!)
            }

            Spacer()

            Text("© 2025 cyancloudyang")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Add Source View
struct AddSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var preferences = Preferences.shared
    @State private var selectedSourceType: WallpaperSourceType? = nil
    @State private var showError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Source")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()

            Divider()

            // Source list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(WallpaperSourceType.allCases, id: \.self) { sourceType in
                        SourceSelectionButton(
                            sourceType: sourceType,
                            isSelected: selectedSourceType == sourceType,
                            isEnabled: preferences.isSourceEnabled(sourceType),
                            action: {
                                toggleSource(sourceType)
                            }
                        )
                    }
                }
                .padding()
            }

            Divider()

            // Footer with info
            HStack {
                Text("Tap a source to enable/disable it")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .alert("Error", isPresented: .constant(showError != nil)) {
            Button("OK", role: .cancel) {
                showError = nil
            }
        } message: {
            Text(showError ?? "")
        }
    }

    private func toggleSource(_ sourceType: WallpaperSourceType) {
        if preferences.isSourceEnabled(sourceType) {
            preferences.disableSource(sourceType)
        } else {
            preferences.enableSource(sourceType)
        }
        selectedSourceType = sourceType
    }
}

/// Button for source selection
struct SourceSelectionButton: View {
    let sourceType: WallpaperSourceType
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: sourceType.iconName)
                    .frame(width: 30, height: 30)
                    .foregroundColor(isEnabled ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sourceType.displayName)
                        .font(.body)
                        .fontWeight(isEnabled ? .semibold : .regular)
                    Text(sourceType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isEnabled ? .accentColor : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preferences Extension
extension Preferences {
    func isSourceEnabled(_ sourceType: WallpaperSourceType) -> Bool {
        switch sourceType {
        case .unsplash:
            return unsplashEnabled
        case .bing:
            return bingEnabled
        case .wallhaven:
            return wallhavenEnabled
        case .artstation:
            return artstationEnabled
        case .reddit:
            return redditEnabled
        case .local:
            return localEnabled
        }
    }

    func enableSource(_ sourceType: WallpaperSourceType) {
        switch sourceType {
        case .unsplash:
            unsplashEnabled = true
        case .bing:
            bingEnabled = true
        case .wallhaven:
            wallhavenEnabled = true
        case .artstation:
            artstationEnabled = true
        case .reddit:
            redditEnabled = true
        case .local:
            localEnabled = true
        }
        if !enabledSources.contains(sourceType) {
            enabledSources.append(sourceType)
        }
    }

    func disableSource(_ sourceType: WallpaperSourceType) -> Void {
        switch sourceType {
        case .unsplash:
            unsplashEnabled = false
        case .bing:
            bingEnabled = false
        case .wallhaven:
            wallhavenEnabled = false
        case .artstation:
            artstationEnabled = false
        case .reddit:
            redditEnabled = false
        case .local:
            localEnabled = false
        }
        enabledSources.removeAll { $0 == sourceType }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
