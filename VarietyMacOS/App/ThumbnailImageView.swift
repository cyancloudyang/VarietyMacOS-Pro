import SwiftUI
@preconcurrency import AppKit

struct ThumbnailImageView: View {
    let wallpaper: Wallpaper
    @State private var thumbnail: NSImage? = nil
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else if let image = thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 40, height: 40)
        .cornerRadius(4)
        .clipped()
        .task {
            do {
                let pipeline = ThumbnailPipeline()
                let result = try await pipeline.thumbnail(for: wallpaper)
                thumbnail = result.image
            } catch {
                // Leave as photo placeholder
            }
            isLoading = false
        }
    }
}
