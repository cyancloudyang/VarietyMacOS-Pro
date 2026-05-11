//
// OnboardingView.swift
// VarietyMacOS
//
// First-launch onboarding wizard
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var preferences = Preferences.shared
    @State private var currentStep = 0
    @State private var selectedSources: Set<WallpaperSourceType> = [.unsplash]
    @State private var selectedInterval: TimeInterval = 1800 // 30 minutes
    
    let totalSteps = 4
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                .progressViewStyle(.linear)
                .padding()
            
            // Content
            VStack(spacing: 24) {
                switch currentStep {
                case 0:
                    WelcomeStepView()
                case 1:
                    SourceSelectionStepView(selectedSources: $selectedSources)
                case 2:
                    IntervalSelectionStepView(selectedInterval: $selectedInterval)
                case 3:
                    CompletionStepView()
                default:
                    EmptyView()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }
                
                Spacer()
                
                if currentStep < totalSteps - 1 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .keyboardShortcut(.return, modifiers: [])
                } else {
                    Button("Start Enjoying") {
                        saveOnboarding()
                        dismiss()
                    }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .onKeyPress { key in
            handleKeyPress(key)
        }
    }
    
    private func handleKeyPress(_ key: KeyPress) -> EventBindingResult {
        switch key {
        case .escape:
            // Show confirmation dialog
            return .handled
        default:
            return .unhandled
        }
    }
    
    private func saveOnboarding() {
        // Save selected sources
        for source in WallpaperSourceType.allCases {
            preferences.setEnabled(source, to: selectedSources.contains(source))
        }
        
        // Save interval
        preferences.timerInterval = selectedInterval
        
        // Mark onboarding as completed
        preferences.hasCompletedOnboarding = true
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Welcome to VarietyMacOS Pro")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("Enjoy beautiful wallpapers that change automatically.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Let's set up your preferences in just a few steps.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Source Selection Step

struct SourceSelectionStepView: View {
    @Binding var selectedSources: Set<WallpaperSourceType>
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Sources")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select where you want to get wallpapers from")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(WallpaperSourceType.allCases, id: \.self) { source in
                    SourceSelectionRow(
                        source: source,
                        isSelected: selectedSources.contains(source),
                        toggleSelection: {
                            if selectedSources.contains(source) {
                                selectedSources.remove(source)
                            } else {
                                selectedSources.insert(source)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct SourceSelectionRow: View {
    let source: WallpaperSourceType
    let isSelected: Bool
    let toggleSelection: () -> Void
    
    var body: some View {
        HStack {
            Toggle(isOn: toggleSelection) {
                HStack {
                    Image(systemName: source.iconName)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text(source.displayName)
                            .font(.body)
                        Text(source.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Interval Selection Step

struct IntervalSelectionStepView: View {
    @Binding var selectedInterval: TimeInterval
    
    let intervals: [(label: String, value: TimeInterval)] = [
        ("5 minutes", 300),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200),
        ("6 hours", 43200),
        ("12 hours", 86400)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Change Wallpaper Every")
                .font(.title2)
                .fontWeight(.semibold)
            
            Picker("Interval", selection: $selectedInterval) {
                ForEach(intervals, id: \.value) { interval in
                    Text(interval.label).tag(interval.value)
                }
            }
            .pickerStyle(.radioGroup)
        }
    }
}

// MARK: - Completion Step

struct CompletionStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("VarietyMacOS Pro will now automatically change your wallpaper.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("You can always change settings later in Preferences.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OnboardingView()
}
