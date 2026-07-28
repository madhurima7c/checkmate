import DialKit
import SwiftUI

enum HomePageDialKit {
    static func makePanel() -> DialPanelState<HomePageTuning> {
        DialPanelState(
            name: "Home Page",
            initial: .default,
            controls: [
                .group("bottomNav", children: [
                    .slider("itemSpacing", keyPath: \.navItemSpacing, range: 8...32, step: 1, unit: "pt"),
                    .slider("controlSize", keyPath: \.navControlSize, range: 48...68, step: 1, unit: "pt"),
                    .slider("tabIconSize", keyPath: \.navIconSize, range: 22...38, step: 1, unit: "pt"),
                    .slider("addIconSize", keyPath: \.fabIconSize, range: 20...36, step: 1, unit: "pt"),
                ]),
                .group("edgeEffects", children: [
                    .slider("topFadeHeight", keyPath: \.topFadeHeight, range: 32...96, step: 1, unit: "pt"),
                    .slider("bottomFadeHeight", keyPath: \.bottomFadeHeight, range: 180...340, step: 2, unit: "pt"),
                    .slider("progressiveBlur", keyPath: \.edgeBlurOpacity, range: 0...1, step: 0.05),
                ]),
                .group("cards", children: [
                    .slider("gridSpacing", keyPath: \.gridSpacing, range: 4...24, step: 1, unit: "pt"),
                    .slider("aspectRatio", keyPath: \.cardAspectRatio, range: 0.8...1.2, step: 0.01),
                    .slider("textSize", keyPath: \.cardTextSize, range: 12...20, step: 0.5, unit: "pt"),
                    .slider("checkboxSize", keyPath: \.checkboxSize, range: 16...28, step: 1, unit: "pt"),
                    .slider("avatarSize", keyPath: \.avatarSize, range: 18...32, step: 1, unit: "pt"),
                ]),
                .group("checkConfetti", children: [
                    .slider("scale", keyPath: \.confettiScale, range: 0.8...3.5, step: 0.05),
                    .slider("speed", keyPath: \.confettiSpeed, range: 0.5...3, step: 0.05),
                    .slider("xOffset", keyPath: \.confettiXOffset, range: -100...100, step: 1, unit: "pt"),
                    .slider("yOffset", keyPath: \.confettiYOffset, range: -100...100, step: 1, unit: "pt"),
                    .slider("doneDelay", keyPath: \.confettiDoneDelay, range: 0.3...2.5, step: 0.05, unit: "s"),
                    .toggle("sound", keyPath: \.confettiSoundEnabled),
                    .slider("volume", keyPath: \.confettiVolume, range: 0...1, step: 0.05),
                    .toggle("haptics", keyPath: \.confettiHapticsEnabled),
                    .slider("hapticPunch", keyPath: \.confettiHapticIntensity, range: 0.2...1, step: 0.05),
                ]),
            ]
        )
    }
}

enum TodoSheetDialKit {
    static func makePanel() -> DialPanelState<TodoSheetTuning> {
        DialPanelState(
            name: "To-Do Sheet",
            initial: .default,
            controls: [
                .group("layout", children: [
                    .slider("previewToColors", keyPath: \.previewToColorsSpacing, range: 8...40, step: 1, unit: "pt"),
                    .slider("colorsToDetails", keyPath: \.colorsToDetailsSpacing, range: 8...48, step: 1, unit: "pt"),
                    .slider("sectionSpacing", keyPath: \.sectionSpacing, range: 8...28, step: 1, unit: "pt"),
                ]),
                .group("shadow", children: [
                    .toggle("enabled", keyPath: \.shadowEnabled),
                    .slider("opacity", keyPath: \.shadowOpacity, range: 0...0.2, step: 0.01),
                    .slider("radius", keyPath: \.shadowRadius, range: 0...16, step: 0.5, unit: "pt"),
                    .slider("yOffset", keyPath: \.shadowYOffset, range: -4...12, step: 0.5, unit: "pt"),
                ]),
                .group("separator", children: [
                    .toggle("visible", keyPath: \.separatorVisible),
                    .slider("thickness", keyPath: \.separatorThickness, range: 0.5...4, step: 0.5, unit: "pt"),
                    .color("color", keyPath: \.separatorHex),
                ]),
                .group("colors", children: [
                    .color("canvas", keyPath: \.canvasHex),
                    .color("panel", keyPath: \.panelHex),
                    .color("selection", keyPath: \.selectionHex),
                    .color("yellowPaper", keyPath: \.yellowPaperHex),
                    .color("pinkPaper", keyPath: \.pinkPaperHex),
                    .color("bluePaper", keyPath: \.bluePaperHex),
                    .color("orangePaper", keyPath: \.orangePaperHex),
                ]),
                .group("colorMotion", children: [
                    .slider("popScale", keyPath: \.colorPopScale, range: 1...1.12, step: 0.005),
                    .slider("lift", keyPath: \.colorLift, range: 0...12, step: 0.5, unit: "pt"),
                    .slider("tilt", keyPath: \.colorTilt, range: 0...6, step: 0.25, unit: "°"),
                    .slider("response", keyPath: \.colorResponse, range: 0.15...0.8, step: 0.01, unit: "s"),
                    .slider("damping", keyPath: \.colorDamping, range: 0.35...1, step: 0.01),
                ]),
            ]
        )
    }
}

private struct HomePageDialRegistrar: View {
    @ObservedObject var store: HomePageTuningStore
    @StateObject private var dial = HomePageDialKit.makePanel()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: dial.values) { _, values in store.values = values }
            .onAppear { store.values = dial.values }
    }
}

private struct TodoSheetDialRegistrar: View {
    @ObservedObject var store: TodoSheetTuningStore
    @StateObject private var dial = TodoSheetDialKit.makePanel()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: dial.values) { _, values in store.values = values }
            .onAppear { store.values = dial.values }
    }
}

/// Registers enabled panels once and renders DialKit's shared multi-panel drawer.
struct CheckmateDialKitHost: View {
    let homePageEnabled: Bool
    let todoSheetEnabled: Bool
    let cardFocusEnabled: Bool
    @ObservedObject var homeStore: HomePageTuningStore
    @ObservedObject var todoSheetStore: TodoSheetTuningStore
    @ObservedObject var cardFocusStore: CardFocusTuningStore

    private var hasEnabledPanel: Bool {
        homePageEnabled || todoSheetEnabled || cardFocusEnabled
    }

    var body: some View {
        ZStack {
            if homePageEnabled {
                HomePageDialRegistrar(store: homeStore)
            }
            if todoSheetEnabled {
                TodoSheetDialRegistrar(store: todoSheetStore)
            }
            if cardFocusEnabled {
                CardFocusDialRegistrar(store: cardFocusStore)
            }
            if hasEnabledPanel {
                // Sit below the header so Settings remains reachable.
                DialRoot(position: .topRight, storageID: "checkmate-dialkit")
                    .padding(.top, 72)
            }
        }
    }
}

/// A second root is required above a presented SwiftUI sheet. Panel registration
/// remains owned by `CheckmateDialKitHost`, so this is still one shared drawer.
struct PresentedDialKitRoot: View {
    var body: some View {
        DialRoot(position: .topRight, storageID: "checkmate-dialkit")
            .padding(.top, 72)
    }
}
