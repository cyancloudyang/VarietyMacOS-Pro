import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a: Double
        let r: Double
        let g: Double
        let b: Double

        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
            a = 1.0
        case 8:
            a = Double((int >> 24) & 0xFF) / 255.0
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0.5
            g = 0.5
            b = 0.5
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

func hexColor(hex: String) -> Color {
    Color(hex: hex.hasPrefix("#") ? hex : "#\(hex)")
}
