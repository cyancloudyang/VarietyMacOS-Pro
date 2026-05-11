//
//  SidebarView.swift
//  VarietyMacOS
//
//  Sidebar navigation for the main NavigationSplitView
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedSection: AppNavigationView.AppSection?
    @StateObject private var preferences = Preferences.shared
    @StateObject private var collectionManager = CollectionManager.shared
    @State private var isShowingNewCollectionSheet = false

    var body: some View {
        List {
            Section {
                ForEach(AppNavigationView.AppSection.allCases, id: \.self) { section in
                    Label(section.rawValue, systemImage: section.iconName)
                        .tag(section as AppNavigationView.AppSection?)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }
            }

            Section("Collections") {
                ForEach(collectionManager.collections) { collection in
                    Button {
                        print("Navigate to collection: \(collection.name)")
                    } label: {
                        Label {
                            Text(collection.name)
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                        }
                        .help("\(collection.wallpapers.count) wallpapers")
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .onDelete { indices in
                    let idsToDelete = indices.map { collectionManager.collections[$0].id }
                    for id in idsToDelete {
                        if let collection = collectionManager.collections.first(where: { $0.id == id }) {
                            collectionManager.delete(collection)
                        }
                    }
                }

                Button {
                    isShowingNewCollectionSheet = true
                } label: {
                    Label("New Collection", systemImage: "plus")
                        .foregroundColor(.accentColor)
                }
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Variety Pro")
        .sheet(isPresented: $isShowingNewCollectionSheet) {
            NewCollectionSheet { name, description in
                collectionManager.create(name: name, description: description)
            }
        }
    }
}

struct NewCollectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    private let onConfirm: (String, String?) -> Void

    init(onConfirm: @escaping (String, String?) -> Void) {
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Collection Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                TextField("Description (optional)", text: $description)
                    .textFieldStyle(.roundedBorder)
            }
            .navigationTitle("New Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onConfirm(name, description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
