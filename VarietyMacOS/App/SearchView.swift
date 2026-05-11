import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var searchResults: [Wallpaper] = []
    @State private var isLoading = false
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchField(searchText: $searchText)
                    .padding()
                
                if isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No wallpapers found",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(searchResults) { wallpaper in
                                WallpaperGridItem(wallpaper: wallpaper)
                                    .environment(\.modelContext, context)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
        .onChange(of: searchText) { _, _ in
            performSearch()
        }
        .task {
            performSearch()
        }
        }
    }
    
    private func performSearch() {
        isLoading = true
        defer { isLoading = false }

        do {
            let service = WallpaperSearchService.shared
            searchResults = try service.search(query: searchText, context: context)
        } catch {
            searchResults = []
        }
    }
}

struct SearchField: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search wallpapers...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct WallpaperGridItem: View {
    let wallpaper: Wallpaper
    @Environment(\.modelContext) private var context
    @State private var image: NSImage?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .center) {
                    if let image = image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if isLoading {
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.width / wallpaper.aspectRatio)
                    } else {
                        Text(wallpaper.displayTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height / wallpaper.aspectRatio)
                .clipped()
            }
            .frame(height: 200)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Title
            Text(wallpaper.displayTitle)
                .font(.headline)
                .lineLimit(2)
                .truncationMode(.tail)
            
            // Metadata
            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(wallpaper.source.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let rating = wallpaper.userRating {
                    Divider()
                    ForEach(1...rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            image = try await wallpaper.loadThumbnail()
        } catch {
            do {
                image = try await wallpaper.loadImage()
            } catch {
                image = nil
            }
        }
    }
}

#Preview {
    SearchView()
}