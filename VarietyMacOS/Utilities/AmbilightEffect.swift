//
// AmbilightEffect.swift
// VarietyMacOS
//
// Philips Ambilight (流光溢彩) effect for macOS
// Extracts edge colors from wallpaper image and projects them outward
// like LED lights behind a TV screen
//

import SwiftUI
import CoreImage

struct AmbilightEffect: View {
  let wallpaper: Wallpaper?
  let intensity: CGFloat

  @State private var topColor: Color = .clear
  @State private var bottomColor: Color = .clear
  @State private var leftColor: Color = .clear
  @State private var rightColor: Color = .clear
  @State private var dominantColor: Color = .clear
  @State private var imageHash: Int = 0

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // Base: dominant color wash (very subtle)
        dominantColor
          .opacity(0.15 * intensity)
          .ignoresSafeArea()

        // Right edge glow — the primary radiation source
        // Simulates LEDs on the right side of the "screen"
        HStack {
          Spacer()
          rightColor
            .opacity(0.6 * intensity)
            .frame(width: geo.size.width * 0.4)
            .blur(radius: 120)
        }
        .ignoresSafeArea()

        // Top-right corner glow
        VStack {
          HStack {
            Spacer()
            topColor
              .opacity(0.4 * intensity)
              .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.3)
              .blur(radius: 100)
          }
          Spacer()
        }
        .ignoresSafeArea()

        // Bottom-right corner glow
        VStack {
          Spacer()
          HStack {
            Spacer()
            bottomColor
              .opacity(0.4 * intensity)
              .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.3)
              .blur(radius: 100)
          }
        }
        .ignoresSafeArea()

        // Left radiation — the "spillover" from right to left
        // This is the key Ambilight effect: colors reaching the opposite side
        HStack {
          leftColor
            .opacity(0.2 * intensity)
            .frame(width: geo.size.width * 0.15)
            .blur(radius: 80)
          Spacer()
        }
        .ignoresSafeArea()

        // Top edge subtle glow
        VStack {
          topColor
            .opacity(0.15 * intensity)
            .frame(height: geo.size.height * 0.1)
            .blur(radius: 60)
          Spacer()
        }
        .ignoresSafeArea()

        // Bottom edge subtle glow
        VStack {
          Spacer()
          bottomColor
            .opacity(0.15 * intensity)
            .frame(height: geo.size.height * 0.1)
            .blur(radius: 60)
        }
.ignoresSafeArea()
        }
    }
    .onAppear {
      extractColors()
      setupImageObservation()
    }
    .onChange(of: wallpaper) { _, _ in
      extractColors()
      setupImageObservation()
    }
    .onChange(of: imageHash) { _, _ in
      extractColors()
    }
  }

private func extractColors() {
  guard let wallpaper = wallpaper else {
    topColor = .clear
    bottomColor = .clear
    leftColor = .clear
    rightColor = .clear
    dominantColor = .clear
    return
  }

  if let image = wallpaper.cachedImage {
    extractColorsFromImage(image)
  } else {
    Task {
      if let image = try? await wallpaper.loadImage() {
        extractColorsFromImage(image)
      }
    }
  }
}

private func setupImageObservation() {
  guard let wallpaper = wallpaper else { return }
  
  if let image = wallpaper.cachedImage {
    imageHash = image.hashValue
  } else {
    Task {
      if let image = try? await wallpaper.loadImage() {
        imageHash = image.hashValue
      }
    }
  }
}

  private func extractColorsFromImage(_ image: NSImage) {
    let extractor = AmbilightColorExtractor()
    dominantColor = Color(extractor.extractDominantColor(from: image))
    rightColor = Color(extractor.extractEdgeColor(from: image, edge: .right))
    leftColor = Color(extractor.extractEdgeColor(from: image, edge: .left))
    topColor = Color(extractor.extractEdgeColor(from: image, edge: .top))
    bottomColor = Color(extractor.extractEdgeColor(from: image, edge: .bottom))

    print("🎨 Ambilight colors extracted:")
    print("   dominant: \(dominantColor)")
    print("   right: \(rightColor)")
    print("   left: \(leftColor)")
    print("   top: \(topColor)")
    print("   bottom: \(bottomColor)")
  }
}

// MARK: - Ambilight Color Extractor

enum ImageEdge {
  case top, bottom, left, right
}

@MainActor final class AmbilightColorExtractor {

  func extractDominantColor(from image: NSImage) -> NSColor {
    return extractAreaColor(from: image, rect: nil)
  }

  func extractEdgeColor(from image: NSImage, edge: ImageEdge) -> NSColor {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return .windowBackgroundColor
    }

    let ciImage = CIImage(cgImage: cgImage)
    let width = ciImage.extent.width
    let height = ciImage.extent.height
    let sampleRatio: CGFloat = 0.1

    let rect: CGRect
    switch edge {
    case .right:
      rect = CGRect(x: width * (1 - sampleRatio), y: 0, width: width * sampleRatio, height: height)
    case .left:
      rect = CGRect(x: 0, y: 0, width: width * sampleRatio, height: height)
    case .top:
      rect = CGRect(x: 0, y: height * (1 - sampleRatio), width: width, height: height * sampleRatio)
    case .bottom:
      rect = CGRect(x: 0, y: 0, width: width, height: height * sampleRatio)
    }

    return extractAreaColor(from: image, rect: rect)
  }

  private func extractAreaColor(from image: NSImage, rect: CGRect? = nil) -> NSColor {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return .windowBackgroundColor
    }

    let ciImage = CIImage(cgImage: cgImage)

    guard let filter = CIFilter(name: "CIAreaAverage") else {
      return .windowBackgroundColor
    }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(rect ?? ciImage.extent, forKey: kCIInputExtentKey)

    guard let output = filter.outputImage else {
      return .windowBackgroundColor
    }

    let context = CIContext(options: nil)
    guard let outputCGImage = context.createCGImage(output, from: output.extent) else {
      return .windowBackgroundColor
    }

    let resultImage = NSImage(cgImage: outputCGImage, size: NSSize(width: 1, height: 1))

    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    resultImage.draw(in: NSRect(x: 0, y: 0, width: 1, height: 1), from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    return bitmap.colorAt(x: 0, y: 0) ?? .windowBackgroundColor
  }
}
