import SwiftUI

// Central design tokens. Values pulled from the Figma file
// UQufnoBL4RZ5imvjq323AO via the Figma MCP.
enum Theme {
    // Springs — fluid + playful. Reuse these everywhere so the motion has
    // a consistent rhythm.
    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.78)
    static let boop = Animation.spring(response: 0.22, dampingFraction: 0.72)
    static let snappy = Animation.spring(response: 0.26, dampingFraction: 0.86)
    static let instant = Animation.easeOut(duration: 0.14)

    enum Radius {
        static let card: CGFloat = 16
        static let cardLarge: CGFloat = 24
        static let pill: CGFloat = 19
        static let chip: CGFloat = 6
        static let panel: CGFloat = 20
    }

    enum Palette {
        // App canvas.
        static let canvas = Color(hex: 0xF6F6F6)
        // Primary text.
        static let ink = Color(hex: 0x0E0E0E)
        // Body sticky text.
        static let body = Color(hex: 0x2F2F2F)
        // Header date label (muted).
        static let subtitle = Color(white: 0.706, opacity: 0.76)  // rgba(180,180,180,0.76)
        // "1 of 6 done" pill text.
        static let dim = Color(hex: 0xA9A9A9)
        // Strikethrough body.
        static let strike = Color(white: 0, opacity: 0.38)
        // Checkbox stroke.
        static let checkboxStroke = Color(white: 0, opacity: 0.39)
        // Done check + progress dial.
        static let blue = Color(hex: 0x4A8FFF)
        // NEW badge.
        static let newRed = Color(hex: 0xF83A00)
        // Bottom bar dark button (+ FAB).
        static let dark = Color(hex: 0x2F3231)
        // Card / panel surface.
        static let surface = Color.white
    }

    enum Stroke {
        static let cardBorder: CGFloat = 4
        static let cardBorderLarge: CGFloat = 6
    }
}

// Replaces the old orange accent that lived on TaskRowView.
extension Color {
    static let checkmateBlue = Theme.Palette.blue
}

// Sticky-style soft shadow used on every card / floating element.
extension View {
    func stickyShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.07), radius: 4.5, x: 0, y: 2)
            .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 0)
    }
}

struct BoopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Theme.snappy, value: configuration.isPressed)
    }
}
