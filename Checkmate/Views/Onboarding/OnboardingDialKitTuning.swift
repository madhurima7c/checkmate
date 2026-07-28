import SwiftUI

// MARK: - Screen 1 — Stickies

struct OnboardingStickiesTuning: Codable, Equatable {
    // Chrome
    var titleSize: Double = 26
    var subtitleSize: Double = 20
    var titleSubtitleSpacing: Double = 8
    var subtitleWidth: Double = 292
    var titleHex: String = "#0E0E0E"
    var subtitleHex: String = "#A9A9A9"
    var canvasHex: String = "#F6F6F6"
    var glowStartHex: String = "#FF25B6"
    var glowEndHex: String = "#FFCE1F"
    var glowOpacity: Double = 0.08
    var glowHeight: Double = 463
    var glowFadeHeight: Double = 305
    var glowFadeOffsetY: Double = 184
    var copyHorizontalPadding: Double = 33
    var copyToButtonsSpacing: Double = 44
    var buttonsTrailingPadding: Double = 30
    var buttonsSpacing: Double = 75
    var buttonsBottomInsetMin: Double = 24
    var buttonsBottomInsetFraction: Double = 0.037
    var skipSize: Double = 20
    var skipWidth: Double = 80
    var skipHex: String = "#999999"
    var ctaSize: Double = 20
    var ctaWidth: Double = 180
    var ctaHeight: Double = 62
    var ctaCornerRadius: Double = 19
    var ctaFillHex: String = "#2F3231"
    var ctaTextHex: String = "#FFFFFF"
    var ctaShadowOpacity: Double = 0.07
    var ctaShadowRadius: Double = 4.5
    var ctaShadowY: Double = 2
    var pageSpringResponse: Double = 0.34
    var pageSpringDamping: Double = 0.78

    // Card chrome
    var cardWidth: Double = 164.5
    var cardHeight: Double = 168.3
    var cardCornerRadius: Double = 22.95
    var cardBorderWidth: Double = 4
    var cardPaddingX: Double = 17
    var cardPaddingY: Double = 16
    var cardTextSize: Double = 15.3
    var checkboxSize: Double = 19.1
    var checkboxStrokeWidth: Double = 1.8
    var shadowOpacity: Double = 0.07
    var shadowRadius: Double = 4.5
    var shadowY: Double = 2

    // Per-card layout (Figma 2050:2976)
    var card0X: Double = 0.3505
    var card0Y: Double = 195
    var card0Rotation: Double = -19.78
    var card1X: Double = 0.733
    var card1Y: Double = 228
    var card1Rotation: Double = 6.12
    var card2X: Double = 0.259
    var card2Y: Double = 332
    var card2Rotation: Double = 20.63
    var card3X: Double = 0.68
    var card3Y: Double = 364
    var card3Rotation: Double = -5.89
    var card4X: Double = 0.465
    var card4Y: Double = 471
    var card4Rotation: Double = -19.78

    // Drag / check motion
    var dragLiftScale: Double = 1.06
    var checkResponse: Double = 0.32
    var checkDamping: Double = 0.62

    // Confetti
    var confettiCount: Double = 44
    var confettiMinSize: Double = 7
    var confettiMaxSize: Double = 11
    var confettiMaxDelay: Double = 0.35
    var confettiMinDuration: Double = 1.7
    var confettiMaxDuration: Double = 2.7
    var confettiDrift: Double = 70
    var confettiSpin: Double = 320
    var confettiTumbleMin: Double = 380
    var confettiTumbleMax: Double = 720

    // Auto-dial demo (screen 2)
    var autoDialStepDelay: Double = 1.15
    var autoDialPauseDuration: Double = 0.9
    var centerSnapTolerance: Double = 0.28

    // Deal animation (screen 1)
    var dealSpringResponse: Double = 0.88
    var dealSpringDamping: Double = 0.86
    var dealPileHold: Double = 0.6
    var dealStagger: Double = 0.1
    var dealPileX: Double = 0.5
    var dealPileY: Double = 310

    static let `default` = OnboardingStickiesTuning()

    func layout(for index: Int) -> (x: Double, y: Double, rotation: Double) {
        switch index {
        case 0: (card0X, card0Y, card0Rotation)
        case 1: (card1X, card1Y, card1Rotation)
        case 2: (card2X, card2Y, card2Rotation)
        case 3: (card3X, card3Y, card3Rotation)
        default: (card4X, card4Y, card4Rotation)
        }
    }
}

@MainActor
final class OnboardingStickiesTuningStore: ObservableObject {
    static let shared = OnboardingStickiesTuningStore()
    @Published var values: OnboardingStickiesTuning = .default
}

private struct OnboardingStickiesTuningKey: EnvironmentKey {
    static let defaultValue = OnboardingStickiesTuning.default
}

extension EnvironmentValues {
    var onboardingStickiesTuning: OnboardingStickiesTuning {
        get { self[OnboardingStickiesTuningKey.self] }
        set { self[OnboardingStickiesTuningKey.self] = newValue }
    }
}

// MARK: - Screen 2 — Assign

struct OnboardingAssignTuning: Codable, Equatable {
    // Chrome
    var titleSize: Double = 26
    var subtitleSize: Double = 20
    var titleSubtitleSpacing: Double = 8
    var subtitleWidth: Double = 292
    var titleHex: String = "#0E0E0E"
    var subtitleHex: String = "#A9A9A9"
    var canvasHex: String = "#F6F6F6"
    var glowStartHex: String = "#FF25B6"
    var glowEndHex: String = "#FFCE1F"
    var glowOpacity: Double = 0.08
    var glowHeight: Double = 463
    var glowFadeHeight: Double = 305
    var glowFadeOffsetY: Double = 184
    var copyHorizontalPadding: Double = 33
    var copyToButtonsSpacing: Double = 44
    var buttonsTrailingPadding: Double = 30
    var buttonsSpacing: Double = 75
    var buttonsBottomInsetMin: Double = 24
    var buttonsBottomInsetFraction: Double = 0.037
    var skipSize: Double = 20
    var skipWidth: Double = 80
    var skipHex: String = "#999999"
    var ctaSize: Double = 20
    var ctaWidth: Double = 180
    var ctaHeight: Double = 62
    var ctaCornerRadius: Double = 19
    var ctaFillHex: String = "#2F3231"
    var ctaTextHex: String = "#FFFFFF"
    var ctaShadowOpacity: Double = 0.07
    var ctaShadowRadius: Double = 4.5
    var ctaShadowY: Double = 2
    var pageSpringResponse: Double = 0.34
    var pageSpringDamping: Double = 0.78

    // Dial geometry
    var dialCenterY: Double = -68
    var outerArcRadius: Double = 253.25
    var innerArcRadius: Double = 176.25
    var orbitRadius: Double = 252
    var avatarSpacing: Double = 41
    var restAngle: Double = 90
    var arcStrokeOpacity: Double = 0.17
    var arcStrokeWidth: Double = 1.5

    // Avatar selection
    var avatarSize: Double = 53.739
    var selectionGap: Double = 1.119
    var selectionStroke: Double = 1.8
    var badgeSize: Double = 15.674
    var nameSize: Double = 14
    var nameOffsetY: Double = 22
    var selectionHex: String = "#0088FF"

    // Sticky preview card
    var stickyCardY: Double = 385
    var stickyCardWidth: Double = 205.2
    var stickyCardHeight: Double = 210
    var stickyCornerRadius: Double = 28.64
    var stickyBorderWidth: Double = 4
    var stickyTextSize: Double = 19.09
    var stickyCheckboxSize: Double = 23.86
    var stickyAvatarSize: Double = 28
    var stickyPaperHex: String = "#FFEEAE"

    // Dial motion
    var rubberBand: Double = 0.25
    var snapResponse: Double = 0.34
    var snapDamping: Double = 0.78
    var selectResponse: Double = 0.26
    var selectDamping: Double = 0.86
    var avatarTransitionScale: Double = 0.6

    var autoDialStepDelay: Double = 1.15
    var autoDialPauseDuration: Double = 0.9
    var centerSnapTolerance: Double = 0.28

    static let `default` = OnboardingAssignTuning()
}

@MainActor
final class OnboardingAssignTuningStore: ObservableObject {
    static let shared = OnboardingAssignTuningStore()
    @Published var values: OnboardingAssignTuning = .default
}

private struct OnboardingAssignTuningKey: EnvironmentKey {
    static let defaultValue = OnboardingAssignTuning.default
}

extension EnvironmentValues {
    var onboardingAssignTuning: OnboardingAssignTuning {
        get { self[OnboardingAssignTuningKey.self] }
        set { self[OnboardingAssignTuningKey.self] = newValue }
    }
}

// MARK: - Screen 3 — Widget

struct OnboardingWidgetTuning: Codable, Equatable {
    // Chrome
    var titleSize: Double = 26
    var subtitleSize: Double = 20
    var titleSubtitleSpacing: Double = 8
    var subtitleWidth: Double = 292
    var titleHex: String = "#0E0E0E"
    var subtitleHex: String = "#A9A9A9"
    var canvasHex: String = "#F6F6F6"
    var glowStartHex: String = "#FF25B6"
    var glowEndHex: String = "#FFCE1F"
    var glowOpacity: Double = 0.08
    var glowHeight: Double = 463
    var glowFadeHeight: Double = 305
    var glowFadeOffsetY: Double = 184
    var copyHorizontalPadding: Double = 33
    var copyToButtonsSpacing: Double = 44
    var buttonsTrailingPadding: Double = 30
    var buttonsSpacing: Double = 75
    var buttonsBottomInsetMin: Double = 24
    var buttonsBottomInsetFraction: Double = 0.037
    var skipSize: Double = 20
    var skipWidth: Double = 80
    var skipHex: String = "#999999"
    var ctaSize: Double = 20
    var ctaWidth: Double = 180
    var ctaHeight: Double = 62
    var ctaCornerRadius: Double = 19
    var ctaFillHex: String = "#2F3231"
    var ctaTextHex: String = "#FFFFFF"
    var ctaShadowOpacity: Double = 0.07
    var ctaShadowRadius: Double = 4.5
    var ctaShadowY: Double = 2
    var pageSpringResponse: Double = 0.34
    var pageSpringDamping: Double = 0.78

    // Hero
    var heroWidth: Double = 338
    var heroHeight: Double = 376
    var heroTop: Double = 97
    var heroCornerRadius: Double = 50
    var heroFadeHeight: Double = 305
    var heroFadeOffsetY: Double = 242
    var heroFadeStop: Double = 0.586

    // Friend avatar pin
    var friendAvatarSize: Double = 16.24
    var friendAvatarX: Double = 280
    var friendAvatarY: Double = 169
    var friendRingOpacity: Double = 0.91
    var friendRingWidth: Double = 0.81
    var friendShadowOpacity: Double = 0.1
    var friendShadowRadius: Double = 0.4

    // Optional entrance (0 = current static presentation)
    var heroEntranceScale: Double = 1
    var heroEntranceOffsetY: Double = 0
    var heroEntranceResponse: Double = 0.34
    var heroEntranceDamping: Double = 0.78

    static let `default` = OnboardingWidgetTuning()
}

@MainActor
final class OnboardingWidgetTuningStore: ObservableObject {
    static let shared = OnboardingWidgetTuningStore()
    @Published var values: OnboardingWidgetTuning = .default
}

private struct OnboardingWidgetTuningKey: EnvironmentKey {
    static let defaultValue = OnboardingWidgetTuning.default
}

extension EnvironmentValues {
    var onboardingWidgetTuning: OnboardingWidgetTuning {
        get { self[OnboardingWidgetTuningKey.self] }
        set { self[OnboardingWidgetTuningKey.self] = newValue }
    }
}

// MARK: - Chrome projection for OnboardingView

protocol OnboardingChromeReadable {
    var titleSize: Double { get }
    var subtitleSize: Double { get }
    var titleSubtitleSpacing: Double { get }
    var subtitleWidth: Double { get }
    var titleHex: String { get }
    var subtitleHex: String { get }
    var canvasHex: String { get }
    var glowStartHex: String { get }
    var glowEndHex: String { get }
    var glowOpacity: Double { get }
    var glowHeight: Double { get }
    var glowFadeHeight: Double { get }
    var glowFadeOffsetY: Double { get }
    var copyHorizontalPadding: Double { get }
    var copyToButtonsSpacing: Double { get }
    var buttonsTrailingPadding: Double { get }
    var buttonsSpacing: Double { get }
    var buttonsBottomInsetMin: Double { get }
    var buttonsBottomInsetFraction: Double { get }
    var skipSize: Double { get }
    var skipWidth: Double { get }
    var skipHex: String { get }
    var ctaSize: Double { get }
    var ctaWidth: Double { get }
    var ctaHeight: Double { get }
    var ctaCornerRadius: Double { get }
    var ctaFillHex: String { get }
    var ctaTextHex: String { get }
    var ctaShadowOpacity: Double { get }
    var ctaShadowRadius: Double { get }
    var ctaShadowY: Double { get }
    var pageSpringResponse: Double { get }
    var pageSpringDamping: Double { get }
}

extension OnboardingStickiesTuning: OnboardingChromeReadable {}
extension OnboardingAssignTuning: OnboardingChromeReadable {}
extension OnboardingWidgetTuning: OnboardingChromeReadable {}

/// Defaults used when DialKit onboarding is off.
struct OnboardingChromeDefaults: OnboardingChromeReadable {
    static let shared = OnboardingChromeDefaults()
    let titleSize: Double = 26
    let subtitleSize: Double = 20
    let titleSubtitleSpacing: Double = 8
    let subtitleWidth: Double = 292
    let titleHex: String = "#0E0E0E"
    let subtitleHex: String = "#A9A9A9"
    let canvasHex: String = "#F6F6F6"
    let glowStartHex: String = "#FF25B6"
    let glowEndHex: String = "#FFCE1F"
    let glowOpacity: Double = 0.08
    let glowHeight: Double = 463
    let glowFadeHeight: Double = 305
    let glowFadeOffsetY: Double = 184
    let copyHorizontalPadding: Double = 33
    let copyToButtonsSpacing: Double = 44
    let buttonsTrailingPadding: Double = 30
    let buttonsSpacing: Double = 75
    let buttonsBottomInsetMin: Double = 24
    let buttonsBottomInsetFraction: Double = 0.037
    let skipSize: Double = 20
    let skipWidth: Double = 80
    let skipHex: String = "#999999"
    let ctaSize: Double = 20
    let ctaWidth: Double = 180
    let ctaHeight: Double = 62
    let ctaCornerRadius: Double = 19
    let ctaFillHex: String = "#2F3231"
    let ctaTextHex: String = "#FFFFFF"
    let ctaShadowOpacity: Double = 0.07
    let ctaShadowRadius: Double = 4.5
    let ctaShadowY: Double = 2
    let pageSpringResponse: Double = 0.34
    let pageSpringDamping: Double = 0.78
}
