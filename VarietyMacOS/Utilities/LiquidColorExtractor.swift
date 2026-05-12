//
//  LiquidColorExtractor.swift
//  VarietyMacOS
//
//  Liquid Glass color extraction and adjustment utilities
//  Extracts dominant colors from images and applies Liquid Glass adjustments
//

import SwiftUI
import CoreImage
import Accelerate

/// Liquid Glass color extraction utility
final class LiquidColorExtractor {
    static let shared = LiquidColorExtractor()
    
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    /// Extract dominant color from image
    /// - Parameter image: Source image
    /// - Returns: Dominant color adjusted for Liquid Glass
    func extractDominantColor(from image: NSImage) -> NSColor {
        // Resize to 64x64 for fast processing
        let resized = image.resized(to: NSSize(width: 64, height: 64))
        
        guard let cgImage = resized.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .windowBackgroundColor
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Use CIAreaAverage to get average color
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(ciImage.extent, forKey: kCIInputExtentKey)
        
        guard let output = filter.outputImage else {
            return .windowBackgroundColor
        }
        
        // Render to bitmap
        var pixel = [UInt32](repeating: 0, count: 1)
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            componentFormat: .RGBA8,
            colorSpace: .sRGB
        )
        
        // Extract RGBA components
        let r = CGFloat((pixel[0] & 0xFF)) / 255.0
        let g = CGFloat((pixel[0] & 0xFF00) >> 8) / 255.0
        let b = CGFloat((pixel[0] & 0xFF0000) >> 16) / 255.0
        
        let originalColor = NSColor(red: r, green: g, blue: b, alpha: 1.0)
        
        // Apply Liquid Glass adjustment
        return originalColor.liquidGlassAdjusted()
    }
    
    /// Extract edge color from image (for halo effects)
    /// - Parameter image: Source image
    /// - Returns: Edge color adjusted for Liquid Glass
    func extractEdgeColor(from image: NSImage) -> NSColor {
        // Crop edge region (10% border)
        let edgeSize = NSSize(
            width: image.size.width * 0.2,
            height: image.size.height * 0.2
        )
        
        let resized = image.resized(to: NSSize(width: 100, height: 100))
        
        guard let cgImage = resized.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .windowBackgroundColor
        }
        
        // Extract corner regions
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        
        // Sample from four corners
        let cornerExtent = CGRect(
            x: extent.minX,
            y: extent.minY,
            width: extent.width * 0.3,
            height: extent.height * 0.3
        )
        
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(cornerExtent, forKey: kCIInputExtentKey)
        
        guard let output = filter.outputImage else {
            return .windowBackgroundColor
        }
        
        var pixel = [UInt32](repeating: 0, count: 1)
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            componentFormat: .RGBA8,
            colorSpace: .sRGB
        )
        
        let r = CGFloat((pixel[0] & 0xFF)) / 255.0
        let g = CGFloat((pixel[0] & 0xFF00) >> 8) / 255.0
        let b = CGFloat((pixel[0] & 0xFF0000) >> 16) / 255.0
        
        let originalColor = NSColor(red: r, green: g, blue: b, alpha: 1.0)
        
        // Apply Liquid Glass adjustment
        return originalColor.liquidGlassAdjusted()
    }
}

// MARK: - NSColor Extension for Liquid Glass

extension NSColor {
    /// Apply Liquid Glass color adjustments
    /// - Saturation: reduced by 40%
    /// - Brightness: increased by 20%
    /// - Alpha: reduced by 30%
    func liquidGlassAdjusted() -> NSColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // Liquid Glass adjustments:
        // 1. Reduce saturation by 40% (multiply by 0.6)
        // 2. Increase brightness by 20% (multiply by 1.2, max 1.0)
        // 3. Reduce alpha by 30% (multiply by 0.7)
        
        return NSColor(
            hue: h,
            saturation: s * 0.6,           // -40% saturation
            brightness: min(b * 1.2, 1.0), // +20% brightness, capped at 1.0
            alpha: a * 0.7                  // -30% alpha
        )
    }
}

// MARK: - NSImage Extension

extension NSImage {
    /// Resize image to specified size
    func resized(to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
}
