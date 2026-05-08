import Foundation
import AppKit

/// Display mode for wallpaper rendering
@available(macOS 13.0, *)
enum DisplayMode: String, CaseIterable, Codable, Identifiable {
    case fill = "fill"
    case fit = "fit"
    case stretch = "stretch"
    case center = "center"
    case tile = "tile"
    
    var id: String { rawValue }
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .fill:
            return NSLocalizedString("Fill Screen", comment: "Display mode")
        case .fit:
            return NSLocalizedString("Fit to Screen", comment: "Display mode")
        case .stretch:
            return NSLocalizedString("Stretch", comment: "Display mode")
        case .center:
            return NSLocalizedString("Center", comment: "Display mode")
        case .tile:
            return NSLocalizedString("Tile", comment: "Display mode")
        }
    }
    
    /// System wallpaper image scaling option
    var imageScaling: NSImageScaling {
        switch self {
        case .fill:
            return .scaleAxesIndependently
        case .fit:
            return .scaleProportionallyUpOrDown
        case .stretch:
            return .scaleAxesIndependently
        case .center:
            return .scaleNone
        case .tile:
            return .scaleNone
        }
    }
    
    /// Whether the image should be clipped to bounds
    var clipsToBounds: Bool {
        switch self {
        case .fill:
            return true
        case .fit, .stretch, .center, .tile:
            return false
        }
    }
    
    /// Whether the image should be tiled
    var isTiled: Bool { self == .tile }
    
    /// Apply this display mode to set the desktop wallpaper
    /// - Parameters:
    /// - image: The image to set as wallpaper
    /// - screen: The target screen
    /// - Returns: Whether the operation succeeded
    @discardableResult
    func apply(to image: NSImage, on screen: NSScreen) -> Bool {
        // Create a temporary file for the wallpaper
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        guard let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            return false
        }

        do {
            try jpegData.write(to: tempURL)
            // Convert NSImageScaling to NSNumber for the options dictionary
            try NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: [
                .imageScaling: NSNumber(value: imageScaling.rawValue)
            ])
            return true
    } catch {
        Logger.error("Failed to apply wallpaper: \(error.localizedDescription)")
        return false
    }
    }
}

// MARK: - RawRepresentable for NSImageScaling

extension NSImageScaling: @retroactive RawRepresentable {
    public typealias RawValue = UInt

    public init?(rawValue: UInt) {
        switch rawValue {
        case 0:
            self = .scaleProportionallyDown
        case 1:
            self = .scaleAxesIndependently
        case 2:
            self = .scaleNone
        case 3:
            self = .scaleProportionallyUpOrDown
        default:
            return nil
        }
    }

    public var rawValue: UInt {
        switch self {
        case .scaleProportionallyDown:
            return 0
        case .scaleAxesIndependently:
            return 1
        case .scaleNone:
            return 2
        case .scaleProportionallyUpOrDown:
            return 3
        @unknown default:
            return 0
        }
    }
}
