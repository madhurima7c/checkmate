import SwiftUI

enum Theme {
    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.78)
    static let boop = Animation.spring(response: 0.22, dampingFraction: 0.72)
    static let snappy = Animation.spring(response: 0.26, dampingFraction: 0.86)
    static let instant = Animation.easeOut(duration: 0.14)
    /// Book-page color flip on sticky editor.
    static let colorFlip = Animation.spring(response: 0.36, dampingFraction: 0.78)
    /// Checkbox fill zoom from center.
    static let checkPop = Animation.spring(response: 0.32, dampingFraction: 0.62)

    enum Radius {
        static let card: CGFloat = 16
        static let cardLarge: CGFloat = 24
        static let pill: CGFloat = 19
        static let chip: CGFloat = 6
        static let panel: CGFloat = 20
    }

    enum Palette {
        static let canvas = Color(hex: 0xF6F6F6)
        static let ink = Color(hex: 0x0E0E0E)
        static let body = Color(hex: 0x2F2F2F)
        static let subtitle = Color(white: 0.706, opacity: 0.76)
        static let dim = Color(hex: 0xA9A9A9)
        static let strike = Color(white: 0, opacity: 0.38)
        static let checkboxStroke = Color(white: 0, opacity: 0.39)
        static let blue = Color(hex: 0x4A8FFF)
        /// Figma #08f — modal chips, assign ring, color selector (573:2463, 650:2522).
        static let selectionBlue = Color(hex: 0x0088FF)
        static let selectionFill = Color(hex: 0x0088FF).opacity(0.07)
        static let assignLabelMuted = Color(hex: 0x888888)
        static let newRed = Color(hex: 0xF83A00)
        static let dark = Color(hex: 0x2F3231)
        static let surface = Color.white
        static let chipBorder = Color(hex: 0xE3E3E3)
    }

    enum Stroke {
        static let cardBorder: CGFloat = 4
        static let cardBorderLarge: CGFloat = 6
        /// Progress dial track + arc (same weight; scaled down with 16pt dial).
        static let progressRing: CGFloat = 5
    }
}

extension Color {
    static let checkmateBlue = Theme.Palette.blue
}

extension View {
    /// Figma white panel (573:2469): `box-shadow: 0 0 0 1px rgba(0,0,0,0.03)` — zero blur, no drop shadow.
    func figmaPanelChrome(cornerRadius: CGFloat = Theme.Radius.panel) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(Color.white, in: shape)
            .overlay(shape.stroke(Color.black.opacity(0.03), lineWidth: 1))
    }

    /// Previous sticky-note card shadow: soft 7% lift plus faint 3% outline blur.
    func stickyShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.07), radius: 4.5, x: 0, y: 2)
            .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 0)
    }

    func tabBarShadow() -> some View {
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
