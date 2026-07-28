import SwiftUI

/// Live-tunable values for press-and-hold edit/delete. Defaults match shipped Figma specs.
struct CardFocusTuning: Codable, Equatable {
    // MARK: Hold gesture

    var holdDuration: Double = 0.42
    var holdMoveLimit: Double = 16
    var pressScale: Double = 0.94
    var liftStartScale: Double = 0.94

    // MARK: Focus overlay

    var overlayOpacity: Double = 0.86
    var holdTilt: Double = 3.34
    var focusTimeout: Double = 4.0

    // MARK: Magnetic selection

    var magneticRadius: Double = 28

    // MARK: Action bubbles

    var bubbleSize: Double = 52
    var bubbleOffsetX: Double = 26
    var bubbleOffsetY: Double = -22
    var editDeltaX: Double = 54
    var editDeltaY: Double = 42
    var selectedScale: Double = 1.1
    var iconSize: Double = 24
    var deleteHighlightHex: String = "#FA3E3E"
    var editHighlightHex: String = "#393834"

    static let `default` = CardFocusTuning()

    func editDelta(for edge: StickyNoteGridCell.ActionEdge) -> CGSize {
        let x = edge == .trailing ? editDeltaX : -editDeltaX
        return CGSize(width: x, height: editDeltaY)
    }

    func bubbleOffset(for edge: StickyNoteGridCell.ActionEdge) -> CGSize {
        let x = edge == .trailing ? bubbleOffsetX : -bubbleOffsetX
        return CGSize(width: x, height: bubbleOffsetY)
    }
}

@MainActor
final class CardFocusTuningStore: ObservableObject {
    static let shared = CardFocusTuningStore()

    @Published var values: CardFocusTuning = .default
}

private struct CardFocusTuningKey: EnvironmentKey {
    static let defaultValue = CardFocusTuning.default
}

extension EnvironmentValues {
    var cardFocusTuning: CardFocusTuning {
        get { self[CardFocusTuningKey.self] }
        set { self[CardFocusTuningKey.self] = newValue }
    }
}

extension Color {
    init(dialHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt32(cleaned, radix: 16) ?? 0
        self.init(hex: value)
    }
}
