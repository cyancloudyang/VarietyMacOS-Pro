import Foundation

/// Manages wallpaper downloads with queuing and progress tracking
@available(macOS 13.0, *)
final actor DownloadManager {
    static let shared = DownloadManager()

    private var downloadQueue: [DownloadTask] = []
    private var activeDownloads: [String: DownloadTask] = [:]
    private let maxConcurrentDownloads = 3
    private var downloadCompletionHandlers: [String: (Result<URL, Error>) -> Void] = [:]

    private var downloadsDirectory: URL {
        let downloadsFolder = Preferences.shared.downloadFolder
        if downloadsFolder.isEmpty {
            return FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Variety")
        }
        return URL(fileURLWithPath: downloadsFolder)
    }

    private init() {
        // Create downloads directory if needed
        Task {
            self.createDownloadsDirectory()
        }
    }

    nonisolated private func createDownloadsDirectory() {
        let downloadsFolder = Preferences.shared.downloadFolder
        let downloadsDir: URL
        if downloadsFolder.isEmpty {
            downloadsDir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
                .appendingPathComponent("Variety")
        } else {
            downloadsDir = URL(fileURLWithPath: downloadsFolder)
        }
        try? FileManager.default.createDirectory(
            at: downloadsDir,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Public Methods
    
    /// Download a wallpaper
    func download(wallpaper: Wallpaper, priority: DownloadPriority = .normal) async throws -> URL {
        let task = DownloadTask(wallpaper: wallpaper, priority: priority)
        
        // Check if already downloading
        if let existingTask = activeDownloads[task.id] {
            return try await existingTask.result()
        }
        
        // Check if already exists
        if let localURL = wallpaper.localURL, FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        
        // Start download
        return try await performDownload(task: task)
    }
    
    /// Queue a download
    func queueDownload(wallpaper: Wallpaper, priority: DownloadPriority = .normal) {
        let task = DownloadTask(wallpaper: wallpaper, priority: priority)
        downloadQueue.append(task)
        downloadQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
        processQueue()
    }
    
    /// Cancel a download
    func cancelDownload(for wallpaperId: String) {
        if let task = activeDownloads[wallpaperId] {
            task.cancel()
            activeDownloads.removeValue(forKey: wallpaperId)
        }
        
        downloadQueue.removeAll { $0.id == wallpaperId }
    }
    
    /// Get download progress
    func progress(for wallpaperId: String) -> Double {
        activeDownloads[wallpaperId]?.progress ?? 0
    }
    
    /// Get all active downloads
    func activeDownloadIds() -> [String] {
        Array(activeDownloads.keys)
    }
    
    /// Clear completed downloads
    func clearCompletedDownloads() {
        downloadQueue.removeAll { $0.isCompleted }
    }
    
    // MARK: - Private Methods
    
    private func performDownload(task: DownloadTask) async throws -> URL {
        guard let remoteURL = task.wallpaper.remoteURL else {
            throw DownloadError.noRemoteURL
        }
        
        activeDownloads[task.id] = task
        defer { activeDownloads.removeValue(forKey: task.id) }
        
        do {
            let destinationURL = destinationURL(for: task.wallpaper)
            
            // Download with progress
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw DownloadError.downloadFailed
            }
            
            // Save to destination
            try data.write(to: destinationURL)
            
            // Update wallpaper
            task.wallpaper.localURL = destinationURL
            task.complete()
            
            Logger.info("Downloaded wallpaper: \(task.wallpaper.id)")
            return destinationURL
            
        } catch {
            Task { @MainActor in task.fail(error: error) }
            throw error
        }
    }
    
    private func processQueue() {
        guard activeDownloads.count < maxConcurrentDownloads else { return }
        guard !downloadQueue.isEmpty else { return }
        
        let nextTask = downloadQueue.removeFirst()
        
        Task {
            do {
                _ = try await performDownload(task: nextTask)
            } catch {
                Logger.error("Download failed: \(error.localizedDescription)")
            }
            processQueue()
        }
    }
    
    private func destinationURL(for wallpaper: Wallpaper) -> URL {
        let filename = "\(wallpaper.id).jpg"
        return downloadsDirectory.appendingPathComponent(filename)
    }
    

}

// MARK: - Download Task

@available(macOS 13.0, *)
final class DownloadTask {
    let id: String
    let wallpaper: Wallpaper
    let priority: DownloadPriority
    private(set) var progress: Double = 0
    private(set) var isCompleted = false
    private(set) var error: Error?
    private var continuation: CheckedContinuation<URL, Error>?
    private var isCancelled = false
    
    init(wallpaper: Wallpaper, priority: DownloadPriority) {
        self.id = wallpaper.id
        self.wallpaper = wallpaper
        self.priority = priority
    }
    
    func updateProgress(_ newProgress: Double) {
        progress = min(1.0, max(0.0, newProgress))
    }
    
    func complete() {
        isCompleted = true
    }
    
    func fail(error: Error) {
        self.error = error
        isCompleted = true
    }
    
    func cancel() {
        isCancelled = true
        continuation?.resume(throwing: DownloadError.cancelled)
    }
    
    func result() async throws -> URL {
        if isCancelled {
            throw DownloadError.cancelled
        }
        if let error = error {
            throw error
        }
        if isCompleted, let localURL = wallpaper.localURL {
            return localURL
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
}

// MARK: - Download Priority

enum DownloadPriority: Int {
    case low = 0
    case normal = 1
    case high = 2
}
