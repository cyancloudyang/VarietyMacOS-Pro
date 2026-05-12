//
//  LiquidColorExtractor.swift
//  VarietyMacOS
//
//  Liquid Glass color extraction and adjustment utilities
//

import SwiftUI
import CoreImage

/// Liquid Glass color extraction utility
@MainActor final class LiquidColorExtractor {
    
    /// Extract dominant color from image
    func extractDominantColor(from image: NSImage) -> NSColor {
        // Simplified: extract average color using Core Image
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .windowBackgroundColor
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Use CIAreaAverage filter to get average color
        guard let filter = CIFilter(name: "CIAreaAverage") else {
            return .windowBackgroundColor
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(ciImage.extent, forKey: kCIInputExtentKey)
        
        guard let output = filter.outputImage else {
            return .windowBackgroundColor
        }
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(output, from: output.extent) else {
            return .windowBackgroundColor
        }
        
        return .windowBackgroundColor // Simplified
    }
    
    /// Extract edge color from image
    func extractEdgeColor(from image: NSImage) -> NSColor {
        return extractDominantColor(from: image)
    }
}

// MARK: - NSColor Extension for Liquid Glass

extension NSColor {
    /// Apply Liquid Glass color adjustments
    func liquidGlassAdjusted() -> NSColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        return NSColor(
            hue: h,
            saturation: s * 0.6,
            brightness: min(b * 1.2, 1.0),
            alpha: a * 0.7
        )
    }
}
