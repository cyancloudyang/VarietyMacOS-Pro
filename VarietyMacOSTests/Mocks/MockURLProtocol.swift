//
//  MockURLProtocol.swift
//  VarietyMacOSTests
//
//  Created for testing purposes
//

import Foundation

/// Mock URLProtocol for testing network requests
class MockURLProtocol: URLProtocol {
    /// Static storage for mock responses keyed by URL string
    static var mockData: [String: (Data, HTTPURLResponse)] = [:]
    
    /// Static flag to enable/disable mock responses
    static var isEnabled = false
    
    private var task: URLSessionDataTask?
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard isEnabled else { return false }
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let urlString = url.absoluteString.components(separatedBy: "?").first else {
            failWithError(URLError(.badURL))
            return
        }
        
        // Check for exact match first
        if let (data, response) = Self.mockData[urlString] {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Check for pattern match
        for (pattern, (data, response)) in Self.mockData {
            if urlString.contains(pattern) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
                return
            }
        }
        
        // Return 404 if no mock data found
        let notFoundResponse = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: notFoundResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        task?.cancel()
    }
    
    private func failWithError(_ error: Error) {
        client?.urlProtocol(self, didFailWithError: error)
    }
}

// MARK: - URL Session Configuration

extension MockURLProtocol {
    /// Create a URLSession configuration with the mock protocol
    static func createConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        return configuration
    }
    
    /// Create a URLSession with the mock protocol
    static func createSession() -> URLSession {
        URLSession(configuration: createConfiguration())
    }
    
    /// Register mock data for a URL
    static func register(
        url: URL,
        data: Data,
        statusCode: Int = 200,
        mimeType: String = "image/jpeg"
    ) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": mimeType]
        )!
        mockData[url.absoluteString] = (data, response)
    }
    
    /// Register mock data for a URL string
    static func register(
        urlString: String,
        data: Data,
        statusCode: Int = 200,
        mimeType: String = "image/jpeg"
    ) {
        guard let url = URL(string: urlString) else { return }
        register(url: url, data: data, statusCode: statusCode, mimeType: mimeType)
    }
    
    /// Clear all registered mock data
    static func clearMockData() {
        mockData.removeAll()
    }
    
    /// Enable mock mode
    static func enable() {
        isEnabled = true
    }
    
    /// Disable mock mode
    static func disable() {
        isEnabled = false
        clearMockData()
    }
}

// MARK: - Image Data Helpers

extension MockURLProtocol {
    /// Register a solid color image for testing
    static func registerColorImage(
        urlString: String,
        color: NSColor,
        size: NSSize
    ) {
        guard let imageData = color.image(ofSize: size)?.tiffRepresentation else {
            return
        }
        register(urlString: urlString, data: imageData)
    }
}

// MARK: - NSColor Extension for Test Images

extension NSColor {
    func image(ofSize size: NSSize) -> NSImage? {
        guard let cgColor = cgColor else { return nil }
        
        let imageRect = NSRect(origin: .zero, size: size)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        context.setFillColor(cgColor)
        context.fill(CGRect(origin: .zero, size: CGSize(size)))
        
        guard let cgImage = context.makeImage() else { return nil }
        
        return NSImage(cgImage: cgImage, size: size)
    }
}
