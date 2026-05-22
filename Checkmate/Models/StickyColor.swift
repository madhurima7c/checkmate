import SwiftUI

// Exact hex values pulled from Figma (file UQufnoBL4RZ5imvjq323AO).
enum StickyColor: String, Codable, CaseIterable, Identifiable {
    case yellow, pink, blue, orange

    var id: String { rawValue }

    // Paper background for the card body (grid + modal editor).
    // The modal/dot value is slightly more saturated; we use a single source
    // of truth and the dot view nudges saturation up via `.saturation()` if
    // needed — keeps the system simple.
    var paper: Color {
        switch self {
        case .yellow: return Color(hex: 0xFFEEAE)
        case .pink:   return Color(hex: 0xFFC7EC)
        case .blue:   return Color(hex: 0xC7F0FF)
        case .orange: return Color(hex: 0xFFDEC7)
        }
    }

    // Slightly more saturated tone used in the color-picker row.
    var dot: Color {
        switch self {
        case .yellow: return Color(hex: 0xFFE3AE)
        case .pink:   return Color(hex: 0xFFC0EA)
        case .blue:   return Color(hex: 0xBFEEFF)
        case .orange: return Color(hex: 0xFFD2B2)
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
