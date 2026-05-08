import Foundation

/// Manages bandwidth throttling for downloads
@available(macOS 13.0, *)
actor ThrottlingManager {
    static let shared = ThrottlingManager()
    
    private var isThrottlingEnabled: Bool {
        Preferences.shared.limitDownloadSpeed
    }
    
    private var maxBytesPerSecond: Double {
        Double(Preferences.shared.maxDownloadSpeed) * 1024 // Convert KB/s to bytes/s
    }
    
    private var tokenBuckets: [String: TokenBucket] = [:]
    private let defaultBucket = TokenBucket(rate: 1024 * 1024, capacity: 1024 * 1024) // 1 MB/s default
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get a token bucket for a download
    func bucket(for downloadId: String) -> TokenBucket {
        if isThrottlingEnabled {
            if let bucket = tokenBuckets[downloadId] {
                return bucket
            }
            let bucket = TokenBucket(rate: maxBytesPerSecond, capacity: maxBytesPerSecond * 2)
            tokenBuckets[downloadId] = bucket
            return bucket
        }
        return defaultBucket
    }
    
    /// Wait for tokens before downloading
    func waitForTokens(downloadId: String, count: Int) async {
        guard isThrottlingEnabled else { return }
        
        let bucket = bucket(for: downloadId)
        await bucket.consume(count)
    }
    
    /// Throttle a data stream
    func throttle(downloadId: String, data: Data, chunkSize: Int = 8192) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var offset = 0
                while offset < data.count {
                    let remaining = data.count - offset
                    let currentChunkSize = min(chunkSize, remaining)
                    
                    if isThrottlingEnabled {
                        await waitForTokens(downloadId: downloadId, count: currentChunkSize)
                    }
                    
                    let chunk = data.subdata(in: offset..<offset + currentChunkSize)
                    continuation.yield(chunk)
                    
                    offset += currentChunkSize
                }
                continuation.finish()
            }
        }
    }
    
    /// Remove a bucket when download completes
    func removeBucket(for downloadId: String) {
        tokenBuckets.removeValue(forKey: downloadId)
    }
    
    /// Update throttling settings
    func updateSettings(enabled: Bool, maxSpeedKBps: Double) async {
        Preferences.shared.limitDownloadSpeed = enabled
        Task { @MainActor in Preferences.shared.maxDownloadSpeed = maxSpeedKBps }
        
        // Update all existing buckets
        if enabled {
            let newRate = maxSpeedKBps * 1024
            for (_, bucket) in tokenBuckets {
                await bucket.updateRate(newRate)
            }
        }
    }
    
    /// Get current download speed limit
    func currentSpeedLimit() -> Double {
        isThrottlingEnabled ? maxBytesPerSecond / 1024 : 0
    }
}

// MARK: - Token Bucket

/// Token bucket for rate limiting
@available(macOS 13.0, *)
actor TokenBucket {
    private var tokens: Double
    private var rate: Double
    private let capacity: Double
    private var lastUpdateTime: Date
    
    init(rate: Double, capacity: Double) {
        self.rate = rate
        self.capacity = capacity
        self.tokens = capacity
        self.lastUpdateTime = Date()
    }
    
    /// Consume tokens, waiting if necessary
    func consume(_ count: Int) async {
        let needed = Double(count)
        
        while true {
            addTokens()
            
            if tokens >= needed {
                tokens -= needed
                return
            }
            
            // Calculate wait time
            let deficit = needed - tokens
            let waitTime = deficit / rate
            
            // Wait for tokens
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }
    
    /// Try to consume tokens without waiting
    func tryConsume(_ count: Int) -> Bool {
        addTokens()
        
        if tokens >= Double(count) {
            tokens -= Double(count)
            return true
        }
        return false
    }
    
    /// Get current available tokens
    func availableTokens() -> Double {
        addTokens()
        return tokens
    }
    
    /// Update the rate
    func updateRate(_ newRate: Double) async {
        rate = newRate
    }
    
    private func addTokens() {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastUpdateTime)
        lastUpdateTime = now
        
        let newTokens = timeDelta * rate
        tokens = min(capacity, tokens + newTokens)
    }
}

// MARK: - Throttled URLSession

extension ThrottlingManager {
    /// Create a throttled download task
    func throttledDownload(from url: URL, downloadId: String) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ThrottlingError.downloadFailed
        }
        
        // If throttling is enabled, throttle the data
        if isThrottlingEnabled {
            var throttledData = Data()
            for try await chunk in throttle(downloadId: downloadId, data: data) {
                throttledData.append(chunk)
            }
            removeBucket(for: downloadId)
            return throttledData
        }
        
        return data
    }
}

// MARK: - Throttling Errors

enum ThrottlingError: LocalizedError {
    case downloadFailed
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Download failed during throttling"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        }
    }
}
