import DialKit
import SwiftUI

enum CardFocusDialKit {
    static func makePanel() -> DialPanelState<CardFocusTuning> {
        DialPanelState(
            name: "Press & Hold",
            initial: .default,
            controls: controls,
            onAction: { path in
                guard path == "reset" else { return }
            }
        )
    }

    private static var controls: [DialControl<CardFocusTuning>] {
        [
            .group("hold", children: [
                .slider("holdDuration", keyPath: \.holdDuration, range: 0.15...1.0, step: 0.01, unit: "s"),
                .slider("holdMoveLimit", keyPath: \.holdMoveLimit, range: 4...40, step: 1, unit: "pt"),
                .slider("pressScale", keyPath: \.pressScale, range: 0.85...1.0, step: 0.01),
                .slider("liftStartScale", keyPath: \.liftStartScale, range: 0.85...1.0, step: 0.01),
            ]),
            .group("overlay", children: [
                .slider("overlayOpacity", keyPath: \.overlayOpacity, range: 0.4...1.0, step: 0.02),
                .slider("holdTilt", keyPath: \.holdTilt, range: 0...12, step: 0.1, unit: "°"),
                .slider("focusTimeout", keyPath: \.focusTimeout, range: 2...10, step: 0.5, unit: "s"),
                .slider("magneticRadius", keyPath: \.magneticRadius, range: 8...60, step: 1, unit: "pt"),
            ]),
            .group("bubbles", children: [
                .slider("bubbleSize", keyPath: \.bubbleSize, range: 36...72, step: 1, unit: "pt"),
                .slider("bubbleOffsetX", keyPath: \.bubbleOffsetX, range: 0...48, step: 1, unit: "pt"),
                .slider("bubbleOffsetY", keyPath: \.bubbleOffsetY, range: -48...48, step: 1, unit: "pt"),
                .slider("editDeltaX", keyPath: \.editDeltaX, range: 24...80, step: 1, unit: "pt"),
                .slider("editDeltaY", keyPath: \.editDeltaY, range: 16...72, step: 1, unit: "pt"),
                .slider("selectedScale", keyPath: \.selectedScale, range: 1.0...1.3, step: 0.01),
                .slider("iconSize", keyPath: \.iconSize, range: 16...32, step: 1, unit: "pt"),
                .color("deleteHighlight", keyPath: \.deleteHighlightHex),
                .color("editHighlight", keyPath: \.editHighlightHex),
            ]),
            .action("reset"),
        ]
    }
}

/// Keeps the Press & Hold panel registered with DialKit's shared drawer.
struct CardFocusDialRegistrar: View {
    @ObservedObject var store: CardFocusTuningStore
    @StateObject private var dial = CardFocusDialKit.makePanel()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: dial.values) { _, values in
                store.values = values
            }
            .onAppear {
                store.values = dial.values
            }
    }
}
