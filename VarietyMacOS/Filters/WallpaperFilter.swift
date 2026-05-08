import Foundation
import AppKit
import CoreImage

/// Wallpaper filter effects using Core Image (GPU-accelerated)
@available(macOS 13.0, *)
enum WallpaperFilter: String, CaseIterable, Identifiable, Codable {
    case none = "none"
    case blur = "blur"
    case sharpen = "sharpen"
    case oilPaint = "oil_paint"
    case vignette = "vignette"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .blur: return "Blur"
        case .sharpen: return "Sharpen"
        case .oilPaint: return "Oil Paint"
        case .vignette: return "Vignette"
        }
    }
    
    func apply(to image: NSImage, intensity: Double = 0.5) -> NSImage? {
        guard self != .none else { return image }
        
        let context = CIContext(options: nil)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        
        var outputImage: CIImage
        
        switch self {
        case .blur:
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(intensity * 20, forKey: kCIInputRadiusKey)
            outputImage = filter?.outputImage ?? ciImage
            
        case .sharpen:
            let filter = CIFilter(name: "CIUnsharpMask")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(intensity * 2, forKey: kCIInputRadiusKey)
            filter?.setValue(intensity * 0.5, forKey: kCIInputIntensityKey)
            outputImage = filter?.outputImage ?? ciImage
            
        case .oilPaint:
            let filter = CIFilter(name: "CIOilPaint")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(intensity * 10, forKey: kCIInputScaleKey)
            outputImage = filter?.outputImage ?? ciImage
            
        case .vignette:
            let filter = CIFilter(name: "CIVignette")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(x: image.size.width / 2, y: image.size.height / 2), forKey: kCIInputCenterKey)
            filter?.setValue(intensity * 2, forKey: kCIInputRadiusKey)
            outputImage = filter?.outputImage ?? ciImage
            
        case .none:
            outputImage = ciImage
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
}
