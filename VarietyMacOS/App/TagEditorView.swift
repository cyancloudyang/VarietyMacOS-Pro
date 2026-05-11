import SwiftUI

/// Chip-based tag editor for adding/removing custom tags
@MainActor
struct TagEditorView: View {
    @Binding var tags: [String]
    @State private var newTagText: String = ""
    @State private var showingInput: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tag chips
        if !tags.isEmpty {
            FlowLayout {
                ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                    TagChipView(tag: tag) {
                        removeTag(at: index)
                    }
                }
            }
        }
            
            // Add tag button or input
            if showingInput {
                HStack(spacing: 8) {
                    TextField("Enter tag...", text: $newTagText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onSubmit {
                            addTag()
                        }
                    
Button("Add") {
    addTag()
}
.buttonStyle(.borderedProminent)
.disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Button("Cancel") {
                        cancelInput()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(action: { showingInput = true }) {
                    Label("Add Tag", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else {
            cancelInput()
            return
        }
        tags.append(trimmed)
        newTagText = ""
        showingInput = false
    }
    
    private func removeTag(at index: Int) {
        guard index >= 0 && index < tags.count else { return }
        tags.remove(at: index)
    }
    
    private func cancelInput() {
        newTagText = ""
        showingInput = false
    }
}

/// Individual tag chip with remove button
@MainActor
struct TagChipView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct TagEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TagEditorView(tags: .constant(["nature", "landscape", "4k"]))
            .frame(width: 300)
            .padding()
            .previewDisplayName("With tags")
        
        TagEditorView(tags: .constant([]))
            .frame(width: 300)
            .padding()
            .previewDisplayName("Empty")
    }
}
