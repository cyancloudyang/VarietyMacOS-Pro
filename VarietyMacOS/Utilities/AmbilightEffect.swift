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
    
    @ObservedObject private var geometry = DetailViewGeometry.shared
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                dominantColor
                    .opacity(0.15 * intensity)
                    .ignoresSafeArea()
                
                if geometry.frame != .zero {
                    edgeBasedGlows(containerSize: geo.size)
                }
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
        .animation(.easeInOut(duration: 0.5), value: topColor)
        .animation(.easeInOut(duration: 0.5), value: bottomColor)
        .animation(.easeInOut(duration: 0.5), value: leftColor)
        .animation(.easeInOut(duration: 0.5), value: rightColor)
    }
    
    @ViewBuilder
    private func edgeBasedGlows(containerSize: CGSize) -> some View {
        let rightEdgeX = geometry.frame.minX
        let topEdgeY = geometry.frame.minY
        let bottomEdgeY = geometry.frame.maxY
        let leftEdgeX = geometry.frame.maxX
        let viewHeight = geometry.frame.height
        
        ZStack {
            HStack {
                rightColor
                    .opacity(0.8 * intensity)
                    .frame(width: containerSize.width * 0.5, height: viewHeight * 1.2)
                    .blur(radius: 150)
                Spacer()
            }
            .position(x: rightEdgeX, y: geometry.frame.midY)
            .ignoresSafeArea()
            
            VStack {
                topColor
                    .opacity(0.5 * intensity)
                    .frame(width: geometry.frame.width * 1.3, height: containerSize.height * 0.4)
                    .blur(radius: 120)
                Spacer()
            }
            .position(x: geometry.frame.midX, y: topEdgeY)
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                bottomColor
                    .opacity(0.5 * intensity)
                    .frame(width: geometry.frame.width * 1.3, height: containerSize.height * 0.4)
                    .blur(radius: 120)
            }
            .position(x: geometry.frame.midX, y: bottomEdgeY)
            .ignoresSafeArea()
            
            HStack {
                Spacer()
                leftColor
                    .opacity(0.3 * intensity)
                    .frame(width: containerSize.width * 0.3, height: viewHeight * 0.8)
                    .blur(radius: 100)
            }
            .position(x: leftEdgeX, y: geometry.frame.midY)
            .ignoresSafeArea()
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

    // MARK: - Public API

    func extractDominantColor(from image: NSImage) -> NSColor {
        guard let pixelData = downsampleAndExtractPixels(from: image, rect: nil) else {
            return .windowBackgroundColor
        }
        return dominantColorFromPixels(pixelData)
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

        guard let pixelData = downsampleAndExtractPixels(from: image, rect: rect) else {
            return .windowBackgroundColor
        }
        return edgeColorFromPixels(pixelData)
    }

    // MARK: - Downsampling

    private func downsampleAndExtractPixels(from image: NSImage, rect: CGRect? = nil) -> [(r: Float, g: Float, b: Float)]? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)
        let fullExtent = ciImage.extent
        let cropRect = rect ?? fullExtent

        let cropped = ciImage.cropped(to: cropRect)

        let targetSize = 64
        let scaleX = CGFloat(targetSize) / cropped.extent.width
        let scaleY = CGFloat(targetSize) / cropped.extent.height
        let scale = min(scaleX, scaleY)

        guard let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }
        filter.setValue(cropped, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard let output = filter.outputImage else { return nil }

        let context = CIContext(options: [.useSoftwareRenderer: false])
        let outputRect = output.extent
        let width = Int(outputRect.width.rounded())
        let height = Int(outputRect.height.rounded())

        guard width > 0, height > 0 else { return nil }

        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 4,
            bitsPerPixel: 32
        )!

        guard let data = bitmapRep.bitmapData else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        let nsOutput = NSImage(cgImage: context.createCGImage(output, from: outputRect)!, size: NSSize(width: width, height: height))
        nsOutput.draw(in: NSRect(x: 0, y: 0, width: width, height: height), from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        var pixels: [(r: Float, g: Float, b: Float)] = []
        pixels.reserveCapacity(width * height)
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = Float(data[offset]) / 255.0
                let g = Float(data[offset + 1]) / 255.0
                let b = Float(data[offset + 2]) / 255.0
                let a = Float(data[offset + 3]) / 255.0

                guard a > 0.5, luminance(r, g, b) > 0.05, luminance(r, g, b) < 0.95 else { continue }
                pixels.append((r, g, b))
            }
        }

        guard !pixels.isEmpty else { return nil }
        return pixels
    }

    // MARK: - Edge Color

    private func edgeColorFromPixels(_ pixels: [(r: Float, g: Float, b: Float)]) -> NSColor {
        let totalPixels = Float(pixels.count)
        let threshold = totalPixels * 0.05

        var hueBins: [Int: [(r: Float, g: Float, b: Float, s: Float, l: Float)]] = [:]

        for pixel in pixels {
            let (h, s, l) = rgbToHsl(pixel.r, pixel.g, pixel.b)
        guard s > 0.15 else { continue }
        let bin = Int(h * 36) % 36
            hueBins[bin, default: []].append((pixel.r, pixel.g, pixel.b, s, l))
        }

        // Find bins that meet the 5% threshold, sorted by average saturation (descending)
        let candidates = hueBins
            .filter { Float($0.value.count) >= threshold }
            .map { (bin, pxs) -> (bin: Int, avgSat: Float, avgR: Float, avgG: Float, avgB: Float, count: Int) in
                let count = pxs.count
                let avgSat = pxs.map(\.s).reduce(0, +) / Float(count)
                let avgR = pxs.map(\.r).reduce(0, +) / Float(count)
                let avgG = pxs.map(\.g).reduce(0, +) / Float(count)
                let avgB = pxs.map(\.b).reduce(0, +) / Float(count)
                return (bin, avgSat, avgR, avgG, avgB, count)
            }
            .sorted { $0.avgSat > $1.avgSat }

        if let best = candidates.first, best.avgSat > 0.2 {
            let boostedR = min(1.0, best.avgR * 1.15)
            let boostedG = min(1.0, best.avgG * 1.15)
            let boostedB = min(1.0, best.avgB * 1.15)
            return NSColor(red: CGFloat(boostedR), green: CGFloat(boostedG), blue: CGFloat(boostedB), alpha: 1.0)
        }

        let allBins = hueBins
            .map { (bin, pxs) -> (avgSat: Float, avgR: Float, avgG: Float, avgB: Float, count: Int) in
                let count = pxs.count
                let avgSat = pxs.map(\.s).reduce(0, +) / Float(count)
                let avgR = pxs.map(\.r).reduce(0, +) / Float(count)
                let avgG = pxs.map(\.g).reduce(0, +) / Float(count)
                let avgB = pxs.map(\.b).reduce(0, +) / Float(count)
                return (avgSat, avgR, avgG, avgB, count)
            }
            .sorted { $0.count > $1.count }

        if let best = allBins.first {
            return NSColor(red: CGFloat(best.avgR), green: CGFloat(best.avgG), blue: CGFloat(best.avgB), alpha: 1.0)
        }

        return simpleAverage(pixels)
    }

    // MARK: - Dominant Color

    private func dominantColorFromPixels(_ pixels: [(r: Float, g: Float, b: Float)]) -> NSColor {
        var hueBins: [Int: [(r: Float, g: Float, b: Float)]] = [:]

        for pixel in pixels {
            let (h, _, _) = rgbToHsl(pixel.r, pixel.g, pixel.b)
            let bin = Int(h * 18) % 18
            hueBins[bin, default: []].append(pixel)
        }

        let sortedBins = hueBins.sorted { $0.value.count > $1.value.count }

        if let best = sortedBins.first {
            let pxs = best.value
            let count = pxs.count
            let avgR = pxs.map(\.r).reduce(0, +) / Float(count)
            let avgG = pxs.map(\.g).reduce(0, +) / Float(count)
            let avgB = pxs.map(\.b).reduce(0, +) / Float(count)
            return NSColor(red: CGFloat(avgR), green: CGFloat(avgG), blue: CGFloat(avgB), alpha: 1.0)
        }

        return simpleAverage(pixels)
    }

    // MARK: - Utilities

    private func simpleAverage(_ pixels: [(r: Float, g: Float, b: Float)]) -> NSColor {
        let count = Float(pixels.count)
        let avgR = pixels.map(\.r).reduce(0, +) / count
        let avgG = pixels.map(\.g).reduce(0, +) / count
        let avgB = pixels.map(\.b).reduce(0, +) / count
        return NSColor(red: CGFloat(avgR), green: CGFloat(avgG), blue: CGFloat(avgB), alpha: 1.0)
    }

    private func luminance(_ r: Float, _ g: Float, _ b: Float) -> Float {
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    private func rgbToHsl(_ r: Float, _ g: Float, _ b: Float) -> (h: Float, s: Float, l: Float) {
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let l = (max + min) / 2

        if max == min {
            return (0, 0, l)
        }

        let d = max - min
        let s = l > 0.5 ? d / (2 - max - min) : d / (max + min)

        let h: Float
        switch max {
        case r:
            h = ((g - b) / d) + (g < b ? 6 : 0)
        case g:
            h = ((b - r) / d) + 2
        default: // b
            h = ((r - g) / d) + 4
        }
        return (h / 6, s, l)
    }
}

// MARK: - Detail View Geometry

@MainActor
final class DetailViewGeometry: ObservableObject {
    static let shared = DetailViewGeometry()
    
    @Published var frame: CGRect = .zero
    @Published var isPresented: Bool = false
}
