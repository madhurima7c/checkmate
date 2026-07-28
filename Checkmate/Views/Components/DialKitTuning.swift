import SwiftUI

/// Session-only Home tuning. Defaults reproduce the shipped UI exactly.
struct HomePageTuning: Codable, Equatable {
    // Bottom navigation
    var navItemSpacing: Double = 16
    var navControlSize: Double = 56
    var navIconSize: Double = 30
    var fabIconSize: Double = 27

    // Progressive edge treatment
    var topFadeHeight: Double = 56
    var bottomFadeHeight: Double = 268
    var edgeBlurOpacity: Double = 0

    // Sticky grid
    var gridSpacing: Double = 10
    var cardAspectRatio: Double = 1
    var cardTextSize: Double = 15
    var checkboxSize: Double = 20
    var avatarSize: Double = 24

    // Completion burst (legacy shape burst; still drives CheckBurstView previews)
    var burstScale: Double = 1
    var burstSpread: Double = 1
    var burstResponseMultiplier: Double = 1
    var burstDampingOffset: Double = 0

    // Check-off confetti (Lottie burst + iMessage sound/haptics)
    var confettiScale: Double = 1.8
    var confettiSpeed: Double = 1.5
    var confettiXOffset: Double = 0
    var confettiYOffset: Double = 0
    var confettiDoneDelay: Double = 1.1
    var confettiSoundEnabled: Bool = true
    var confettiVolume: Double = 0.8
    var confettiHapticsEnabled: Bool = true
    var confettiHapticIntensity: Double = 1

    static let `default` = HomePageTuning()
}

@MainActor
final class HomePageTuningStore: ObservableObject {
    static let shared = HomePageTuningStore()
    @Published var values: HomePageTuning = .default
}

private struct HomePageTuningKey: EnvironmentKey {
    static let defaultValue = HomePageTuning.default
}

extension EnvironmentValues {
    var homePageTuning: HomePageTuning {
        get { self[HomePageTuningKey.self] }
        set { self[HomePageTuningKey.self] = newValue }
    }
}

/// Session-only Add/Edit Todo tuning. Defaults reproduce the shipped sheet.
struct TodoSheetTuning: Codable, Equatable {
    // Layout
    var previewToColorsSpacing: Double = 20
    var colorsToDetailsSpacing: Double = 29
    var sectionSpacing: Double = 16

    // Preview shadow
    var shadowEnabled: Bool = true
    var shadowOpacity: Double = 0.07
    var shadowRadius: Double = 4.5
    var shadowYOffset: Double = 2

    // Details separator
    var separatorVisible: Bool = true
    var separatorThickness: Double = 1
    var separatorHex: String = "#EDEDED"

    // Sheet palette
    var canvasHex: String = "#F6F6F6"
    var panelHex: String = "#FFFFFF"
    var selectionHex: String = "#0088FF"
    var yellowPaperHex: String = "#FFEEAE"
    var pinkPaperHex: String = "#FFC7EC"
    var bluePaperHex: String = "#C7F0FF"
    var orangePaperHex: String = "#FFDEC7"

    // Color-change motion
    var colorPopScale: Double = 1.025
    var colorLift: Double = 2
    var colorTilt: Double = 1
    var colorResponse: Double = 0.36
    var colorDamping: Double = 0.78

    static let `default` = TodoSheetTuning()

    func paperColor(for color: StickyColor) -> Color {
        switch color {
        case .yellow: Color(dialHex: yellowPaperHex)
        case .pink: Color(dialHex: pinkPaperHex)
        case .blue: Color(dialHex: bluePaperHex)
        case .orange: Color(dialHex: orangePaperHex)
        }
    }
}

@MainActor
final class TodoSheetTuningStore: ObservableObject {
    static let shared = TodoSheetTuningStore()
    @Published var values: TodoSheetTuning = .default
}

private struct TodoSheetTuningKey: EnvironmentKey {
    static let defaultValue = TodoSheetTuning.default
}

extension EnvironmentValues {
    var todoSheetTuning: TodoSheetTuning {
        get { self[TodoSheetTuningKey.self] }
        set { self[TodoSheetTuningKey.self] = newValue }
    }
}
