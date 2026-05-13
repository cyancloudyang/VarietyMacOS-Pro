//
// LiquidColorExtractor.swift
// VarietyMacOS
//
// Liquid Glass color extraction and adjustment utilities
//

import SwiftUI
import CoreImage

@MainActor final class LiquidColorExtractor {
  
  func extractDominantColor(from image: NSImage) -> NSColor {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return .windowBackgroundColor
    }
    
    let ciImage = CIImage(cgImage: cgImage)
    
    guard let filter = CIFilter(name: "CIAreaAverage") else {
      return .windowBackgroundColor
    }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(ciImage.extent, forKey: kCIInputExtentKey)
    
    guard let output = filter.outputImage else {
      return .windowBackgroundColor
    }
    
    let context = CIContext(options: nil)
    guard let outputCGImage = context.createCGImage(output, from: output.extent) else {
      return .windowBackgroundColor
    }
    
    let averageImage = NSImage(cgImage: outputCGImage, size: NSSize(width: 1, height: 1))
    guard let rep = averageImage.bestRepresentation(for: NSRect(x: 0, y: 0, width: 1, height: 1), context: nil, hints: nil) else {
      return .windowBackgroundColor
    }
    
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    averageImage.draw(in: NSRect(x: 0, y: 0, width: 1, height: 1), from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    
    let color = bitmap.colorAt(x: 0, y: 0) ?? .windowBackgroundColor
    return color
  }
  
  func extractEdgeColor(from image: NSImage) -> NSColor {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return .windowBackgroundColor
    }
    
    let ciImage = CIImage(cgImage: cgImage)
    let width = ciImage.extent.width
    let height = ciImage.extent.height
    
    let edgeRect = CGRect(x: width * 0.9, y: 0, width: width * 0.1, height: height)
    
    guard let filter = CIFilter(name: "CIAreaAverage") else {
      return .windowBackgroundColor
    }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(edgeRect, forKey: kCIInputExtentKey)
    
    guard let output = filter.outputImage else {
      return .windowBackgroundColor
    }
    
    let context = CIContext(options: nil)
    guard let outputCGImage = context.createCGImage(output, from: output.extent) else {
      return .windowBackgroundColor
    }
    
    let edgeImage = NSImage(cgImage: outputCGImage, size: NSSize(width: 1, height: 1))
    return extractDominantColor(from: edgeImage)
  }
}

extension NSColor {
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
