//
// KeyboardShortcutsHelpView.swift
// VarietyMacOS
//
// Displays available keyboard shortcuts in a help overlay
//

import SwiftUI

struct KeyboardShortcutsHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Shortcuts list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(KeyboardShortcuts.allShortcuts, id: \.rawValue) { shortcut in
                        ShortcutRow(shortcut: shortcut)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            Text("Press ⌘/ to toggle this help")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(width: 400, height: 500)
    }
}

struct ShortcutRow: View {
    let shortcut: AppShortcut
    
    var body: some View {
        HStack {
            Text(shortcut.displayName)
                .font(.body)
            
            Spacer()
            
            Text(shortcut.description)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial)
                .cornerRadius(4)
        }
    }
}

#Preview {
    KeyboardShortcutsHelpView()
}
