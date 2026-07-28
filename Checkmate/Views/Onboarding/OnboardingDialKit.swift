import DialKit
import SwiftUI

enum OnboardingStickiesDialKit {
    static func makePanel() -> DialPanelState<OnboardingStickiesTuning> {
        DialPanelState(
            name: "Onboarding 1 — Stickies",
            initial: .default,
            controls: chromeControls() + [
                .group("cardStyle", children: [
                    .slider("width", keyPath: \.cardWidth, range: 120...220, step: 0.5, unit: "pt"),
                    .slider("height", keyPath: \.cardHeight, range: 120...220, step: 0.5, unit: "pt"),
                    .slider("corner", keyPath: \.cardCornerRadius, range: 12...36, step: 0.25, unit: "pt"),
                    .slider("border", keyPath: \.cardBorderWidth, range: 2...10, step: 0.1, unit: "pt"),
                    .slider("padX", keyPath: \.cardPaddingX, range: 8...28, step: 1, unit: "pt"),
                    .slider("padY", keyPath: \.cardPaddingY, range: 8...28, step: 1, unit: "pt"),
                    .slider("textSize", keyPath: \.cardTextSize, range: 12...22, step: 0.1, unit: "pt"),
                    .slider("checkbox", keyPath: \.checkboxSize, range: 14...28, step: 0.1, unit: "pt"),
                    .slider("checkboxStroke", keyPath: \.checkboxStrokeWidth, range: 1...3, step: 0.1, unit: "pt"),
                    .slider("shadowOpacity", keyPath: \.shadowOpacity, range: 0...0.2, step: 0.01),
                    .slider("shadowRadius", keyPath: \.shadowRadius, range: 0...16, step: 0.5, unit: "pt"),
                    .slider("shadowY", keyPath: \.shadowY, range: -4...12, step: 0.5, unit: "pt"),
                ]),
                .group("card0", children: [
                    .slider("x", keyPath: \.card0X, range: 0.05...0.95, step: 0.005),
                    .slider("y", keyPath: \.card0Y, range: 80...560, step: 1, unit: "pt"),
                    .slider("rotation", keyPath: \.card0Rotation, range: -35...35, step: 0.1, unit: "°"),
                ]),
                .group("card1", children: [
                    .slider("x", keyPath: \.card1X, range: 0.05...0.95, step: 0.005),
                    .slider("y", keyPath: \.card1Y, range: 80...560, step: 1, unit: "pt"),
                    .slider("rotation", keyPath: \.card1Rotation, range: -35...35, step: 0.1, unit: "°"),
                ]),
                .group("card2", children: [
                    .slider("x", keyPath: \.card2X, range: 0.05...0.95, step: 0.005),
                    .slider("y", keyPath: \.card2Y, range: 80...560, step: 1, unit: "pt"),
                    .slider("rotation", keyPath: \.card2Rotation, range: -35...35, step: 0.1, unit: "°"),
                ]),
                .group("card3", children: [
                    .slider("x", keyPath: \.card3X, range: 0.05...0.95, step: 0.005),
                    .slider("y", keyPath: \.card3Y, range: 80...560, step: 1, unit: "pt"),
                    .slider("rotation", keyPath: \.card3Rotation, range: -35...35, step: 0.1, unit: "°"),
                ]),
                .group("card4", children: [
                    .slider("x", keyPath: \.card4X, range: 0.05...0.95, step: 0.005),
                    .slider("y", keyPath: \.card4Y, range: 80...560, step: 1, unit: "pt"),
                    .slider("rotation", keyPath: \.card4Rotation, range: -35...35, step: 0.1, unit: "°"),
                ]),
                .group("motion", children: [
                    .slider("dragLift", keyPath: \.dragLiftScale, range: 1...1.2, step: 0.01),
                    .slider("checkResponse", keyPath: \.checkResponse, range: 0.15...0.7, step: 0.01, unit: "s"),
                    .slider("checkDamping", keyPath: \.checkDamping, range: 0.35...1, step: 0.01),
                    .slider("dealResponse", keyPath: \.dealSpringResponse, range: 0.3...1.4, step: 0.01, unit: "s"),
                    .slider("dealDamping", keyPath: \.dealSpringDamping, range: 0.5...1, step: 0.01),
                    .slider("pileHold", keyPath: \.dealPileHold, range: 0...1.5, step: 0.05, unit: "s"),
                    .slider("dealStagger", keyPath: \.dealStagger, range: 0...0.25, step: 0.01, unit: "s"),
                    .slider("pileX", keyPath: \.dealPileX, range: 0.2...0.8, step: 0.005),
                    .slider("pileY", keyPath: \.dealPileY, range: 120...480, step: 1, unit: "pt"),
                ]),
                .group("confetti", children: [
                    .slider("count", keyPath: \.confettiCount, range: 8...80, step: 1),
                    .slider("minSize", keyPath: \.confettiMinSize, range: 4...14, step: 0.5, unit: "pt"),
                    .slider("maxSize", keyPath: \.confettiMaxSize, range: 6...18, step: 0.5, unit: "pt"),
                    .slider("maxDelay", keyPath: \.confettiMaxDelay, range: 0...1, step: 0.05, unit: "s"),
                    .slider("minDuration", keyPath: \.confettiMinDuration, range: 0.8...3, step: 0.05, unit: "s"),
                    .slider("maxDuration", keyPath: \.confettiMaxDuration, range: 1...4, step: 0.05, unit: "s"),
                    .slider("drift", keyPath: \.confettiDrift, range: 0...140, step: 1, unit: "pt"),
                    .slider("spin", keyPath: \.confettiSpin, range: 0...720, step: 10, unit: "°"),
                    .slider("tumbleMin", keyPath: \.confettiTumbleMin, range: 0...900, step: 10, unit: "°"),
                    .slider("tumbleMax", keyPath: \.confettiTumbleMax, range: 0...1080, step: 10, unit: "°"),
                ]),
            ]
        )
    }

    private static func chromeControls() -> [DialControl<OnboardingStickiesTuning>] {
        OnboardingDialChrome.controls(
            titleSize: \.titleSize,
            subtitleSize: \.subtitleSize,
            titleSubtitleSpacing: \.titleSubtitleSpacing,
            subtitleWidth: \.subtitleWidth,
            titleHex: \.titleHex,
            subtitleHex: \.subtitleHex,
            canvasHex: \.canvasHex,
            glowStartHex: \.glowStartHex,
            glowEndHex: \.glowEndHex,
            glowOpacity: \.glowOpacity,
            glowHeight: \.glowHeight,
            glowFadeHeight: \.glowFadeHeight,
            glowFadeOffsetY: \.glowFadeOffsetY,
            copyHorizontalPadding: \.copyHorizontalPadding,
            copyToButtonsSpacing: \.copyToButtonsSpacing,
            buttonsTrailingPadding: \.buttonsTrailingPadding,
            buttonsSpacing: \.buttonsSpacing,
            buttonsBottomInsetMin: \.buttonsBottomInsetMin,
            buttonsBottomInsetFraction: \.buttonsBottomInsetFraction,
            skipSize: \.skipSize,
            skipWidth: \.skipWidth,
            skipHex: \.skipHex,
            ctaSize: \.ctaSize,
            ctaWidth: \.ctaWidth,
            ctaHeight: \.ctaHeight,
            ctaCornerRadius: \.ctaCornerRadius,
            ctaFillHex: \.ctaFillHex,
            ctaTextHex: \.ctaTextHex,
            ctaShadowOpacity: \.ctaShadowOpacity,
            ctaShadowRadius: \.ctaShadowRadius,
            ctaShadowY: \.ctaShadowY,
            pageSpringResponse: \.pageSpringResponse,
            pageSpringDamping: \.pageSpringDamping
        )
    }
}

enum OnboardingAssignDialKit {
    static func makePanel() -> DialPanelState<OnboardingAssignTuning> {
        DialPanelState(
            name: "Onboarding 2 — Assign",
            initial: .default,
            controls: chromeControls() + [
                .group("dial", children: [
                    .slider("centerY", keyPath: \.dialCenterY, range: -160...40, step: 1, unit: "pt"),
                    .slider("outerRadius", keyPath: \.outerArcRadius, range: 180...320, step: 0.25, unit: "pt"),
                    .slider("innerRadius", keyPath: \.innerArcRadius, range: 120...240, step: 0.25, unit: "pt"),
                    .slider("orbit", keyPath: \.orbitRadius, range: 180...320, step: 1, unit: "pt"),
                    .slider("spacing", keyPath: \.avatarSpacing, range: 24...60, step: 0.5, unit: "°"),
                    .slider("restAngle", keyPath: \.restAngle, range: 60...120, step: 1, unit: "°"),
                    .slider("arcOpacity", keyPath: \.arcStrokeOpacity, range: 0...0.5, step: 0.01),
                    .slider("arcStroke", keyPath: \.arcStrokeWidth, range: 0.5...4, step: 0.1, unit: "pt"),
                ]),
                .group("avatars", children: [
                    .slider("size", keyPath: \.avatarSize, range: 40...72, step: 0.1, unit: "pt"),
                    .slider("selectionGap", keyPath: \.selectionGap, range: 0...4, step: 0.05, unit: "pt"),
                    .slider("selectionStroke", keyPath: \.selectionStroke, range: 1...4, step: 0.1, unit: "pt"),
                    .slider("badge", keyPath: \.badgeSize, range: 10...24, step: 0.1, unit: "pt"),
                    .slider("nameSize", keyPath: \.nameSize, range: 10...18, step: 0.5, unit: "pt"),
                    .slider("nameOffsetY", keyPath: \.nameOffsetY, range: 12...36, step: 1, unit: "pt"),
                    .color("selection", keyPath: \.selectionHex),
                ]),
                .group("stickyCard", children: [
                    .slider("y", keyPath: \.stickyCardY, range: 240...520, step: 1, unit: "pt"),
                    .slider("width", keyPath: \.stickyCardWidth, range: 160...260, step: 0.5, unit: "pt"),
                    .slider("height", keyPath: \.stickyCardHeight, range: 160...260, step: 0.5, unit: "pt"),
                    .slider("corner", keyPath: \.stickyCornerRadius, range: 16...40, step: 0.25, unit: "pt"),
                    .slider("border", keyPath: \.stickyBorderWidth, range: 2...12, step: 0.1, unit: "pt"),
                    .slider("textSize", keyPath: \.stickyTextSize, range: 14...26, step: 0.1, unit: "pt"),
                    .slider("checkbox", keyPath: \.stickyCheckboxSize, range: 16...32, step: 0.1, unit: "pt"),
                    .slider("avatar", keyPath: \.stickyAvatarSize, range: 20...40, step: 1, unit: "pt"),
                    .color("paper", keyPath: \.stickyPaperHex),
                ]),
                .group("motion", children: [
                    .slider("rubberBand", keyPath: \.rubberBand, range: 0...0.6, step: 0.01),
                    .slider("snapResponse", keyPath: \.snapResponse, range: 0.15...0.8, step: 0.01, unit: "s"),
                    .slider("snapDamping", keyPath: \.snapDamping, range: 0.35...1, step: 0.01),
                    .slider("selectResponse", keyPath: \.selectResponse, range: 0.1...0.6, step: 0.01, unit: "s"),
                    .slider("selectDamping", keyPath: \.selectDamping, range: 0.35...1, step: 0.01),
                    .slider("avatarPop", keyPath: \.avatarTransitionScale, range: 0.3...1, step: 0.05),
                ]),
            ]
        )
    }

    private static func chromeControls() -> [DialControl<OnboardingAssignTuning>] {
        OnboardingDialChrome.controls(
            titleSize: \.titleSize,
            subtitleSize: \.subtitleSize,
            titleSubtitleSpacing: \.titleSubtitleSpacing,
            subtitleWidth: \.subtitleWidth,
            titleHex: \.titleHex,
            subtitleHex: \.subtitleHex,
            canvasHex: \.canvasHex,
            glowStartHex: \.glowStartHex,
            glowEndHex: \.glowEndHex,
            glowOpacity: \.glowOpacity,
            glowHeight: \.glowHeight,
            glowFadeHeight: \.glowFadeHeight,
            glowFadeOffsetY: \.glowFadeOffsetY,
            copyHorizontalPadding: \.copyHorizontalPadding,
            copyToButtonsSpacing: \.copyToButtonsSpacing,
            buttonsTrailingPadding: \.buttonsTrailingPadding,
            buttonsSpacing: \.buttonsSpacing,
            buttonsBottomInsetMin: \.buttonsBottomInsetMin,
            buttonsBottomInsetFraction: \.buttonsBottomInsetFraction,
            skipSize: \.skipSize,
            skipWidth: \.skipWidth,
            skipHex: \.skipHex,
            ctaSize: \.ctaSize,
            ctaWidth: \.ctaWidth,
            ctaHeight: \.ctaHeight,
            ctaCornerRadius: \.ctaCornerRadius,
            ctaFillHex: \.ctaFillHex,
            ctaTextHex: \.ctaTextHex,
            ctaShadowOpacity: \.ctaShadowOpacity,
            ctaShadowRadius: \.ctaShadowRadius,
            ctaShadowY: \.ctaShadowY,
            pageSpringResponse: \.pageSpringResponse,
            pageSpringDamping: \.pageSpringDamping
        )
    }
}

enum OnboardingWidgetDialKit {
    static func makePanel() -> DialPanelState<OnboardingWidgetTuning> {
        DialPanelState(
            name: "Onboarding 3 — Widget",
            initial: .default,
            controls: chromeControls() + [
                .group("hero", children: [
                    .slider("width", keyPath: \.heroWidth, range: 280...390, step: 1, unit: "pt"),
                    .slider("height", keyPath: \.heroHeight, range: 280...460, step: 1, unit: "pt"),
                    .slider("top", keyPath: \.heroTop, range: 40...180, step: 1, unit: "pt"),
                    .slider("corner", keyPath: \.heroCornerRadius, range: 24...72, step: 1, unit: "pt"),
                    .slider("fadeHeight", keyPath: \.heroFadeHeight, range: 160...420, step: 1, unit: "pt"),
                    .slider("fadeOffsetY", keyPath: \.heroFadeOffsetY, range: 120...360, step: 1, unit: "pt"),
                    .slider("fadeStop", keyPath: \.heroFadeStop, range: 0.3...0.9, step: 0.01),
                ]),
                .group("friendAvatar", children: [
                    .slider("size", keyPath: \.friendAvatarSize, range: 10...28, step: 0.1, unit: "pt"),
                    .slider("x", keyPath: \.friendAvatarX, range: 200...340, step: 1, unit: "pt"),
                    .slider("y", keyPath: \.friendAvatarY, range: 120...240, step: 1, unit: "pt"),
                    .slider("ringOpacity", keyPath: \.friendRingOpacity, range: 0...1, step: 0.01),
                    .slider("ringWidth", keyPath: \.friendRingWidth, range: 0...2, step: 0.05, unit: "pt"),
                    .slider("shadowOpacity", keyPath: \.friendShadowOpacity, range: 0...0.3, step: 0.01),
                    .slider("shadowRadius", keyPath: \.friendShadowRadius, range: 0...4, step: 0.1, unit: "pt"),
                ]),
                .group("entrance", children: [
                    .slider("scale", keyPath: \.heroEntranceScale, range: 0.85...1.15, step: 0.01),
                    .slider("offsetY", keyPath: \.heroEntranceOffsetY, range: -40...40, step: 1, unit: "pt"),
                    .slider("response", keyPath: \.heroEntranceResponse, range: 0.15...0.8, step: 0.01, unit: "s"),
                    .slider("damping", keyPath: \.heroEntranceDamping, range: 0.35...1, step: 0.01),
                ]),
            ]
        )
    }

    private static func chromeControls() -> [DialControl<OnboardingWidgetTuning>] {
        OnboardingDialChrome.controls(
            titleSize: \.titleSize,
            subtitleSize: \.subtitleSize,
            titleSubtitleSpacing: \.titleSubtitleSpacing,
            subtitleWidth: \.subtitleWidth,
            titleHex: \.titleHex,
            subtitleHex: \.subtitleHex,
            canvasHex: \.canvasHex,
            glowStartHex: \.glowStartHex,
            glowEndHex: \.glowEndHex,
            glowOpacity: \.glowOpacity,
            glowHeight: \.glowHeight,
            glowFadeHeight: \.glowFadeHeight,
            glowFadeOffsetY: \.glowFadeOffsetY,
            copyHorizontalPadding: \.copyHorizontalPadding,
            copyToButtonsSpacing: \.copyToButtonsSpacing,
            buttonsTrailingPadding: \.buttonsTrailingPadding,
            buttonsSpacing: \.buttonsSpacing,
            buttonsBottomInsetMin: \.buttonsBottomInsetMin,
            buttonsBottomInsetFraction: \.buttonsBottomInsetFraction,
            skipSize: \.skipSize,
            skipWidth: \.skipWidth,
            skipHex: \.skipHex,
            ctaSize: \.ctaSize,
            ctaWidth: \.ctaWidth,
            ctaHeight: \.ctaHeight,
            ctaCornerRadius: \.ctaCornerRadius,
            ctaFillHex: \.ctaFillHex,
            ctaTextHex: \.ctaTextHex,
            ctaShadowOpacity: \.ctaShadowOpacity,
            ctaShadowRadius: \.ctaShadowRadius,
            ctaShadowY: \.ctaShadowY,
            pageSpringResponse: \.pageSpringResponse,
            pageSpringDamping: \.pageSpringDamping
        )
    }
}

/// Shared chrome control schema for the three onboarding panels.
enum OnboardingDialChrome {
    static func controls<T>(
        titleSize: WritableKeyPath<T, Double>,
        subtitleSize: WritableKeyPath<T, Double>,
        titleSubtitleSpacing: WritableKeyPath<T, Double>,
        subtitleWidth: WritableKeyPath<T, Double>,
        titleHex: WritableKeyPath<T, String>,
        subtitleHex: WritableKeyPath<T, String>,
        canvasHex: WritableKeyPath<T, String>,
        glowStartHex: WritableKeyPath<T, String>,
        glowEndHex: WritableKeyPath<T, String>,
        glowOpacity: WritableKeyPath<T, Double>,
        glowHeight: WritableKeyPath<T, Double>,
        glowFadeHeight: WritableKeyPath<T, Double>,
        glowFadeOffsetY: WritableKeyPath<T, Double>,
        copyHorizontalPadding: WritableKeyPath<T, Double>,
        copyToButtonsSpacing: WritableKeyPath<T, Double>,
        buttonsTrailingPadding: WritableKeyPath<T, Double>,
        buttonsSpacing: WritableKeyPath<T, Double>,
        buttonsBottomInsetMin: WritableKeyPath<T, Double>,
        buttonsBottomInsetFraction: WritableKeyPath<T, Double>,
        skipSize: WritableKeyPath<T, Double>,
        skipWidth: WritableKeyPath<T, Double>,
        skipHex: WritableKeyPath<T, String>,
        ctaSize: WritableKeyPath<T, Double>,
        ctaWidth: WritableKeyPath<T, Double>,
        ctaHeight: WritableKeyPath<T, Double>,
        ctaCornerRadius: WritableKeyPath<T, Double>,
        ctaFillHex: WritableKeyPath<T, String>,
        ctaTextHex: WritableKeyPath<T, String>,
        ctaShadowOpacity: WritableKeyPath<T, Double>,
        ctaShadowRadius: WritableKeyPath<T, Double>,
        ctaShadowY: WritableKeyPath<T, Double>,
        pageSpringResponse: WritableKeyPath<T, Double>,
        pageSpringDamping: WritableKeyPath<T, Double>
    ) -> [DialControl<T>] {
        [
            .group("typography", children: [
                .slider("titleSize", keyPath: titleSize, range: 18...36, step: 0.5, unit: "pt"),
                .slider("subtitleSize", keyPath: subtitleSize, range: 14...28, step: 0.5, unit: "pt"),
                .slider("titleGap", keyPath: titleSubtitleSpacing, range: 2...20, step: 1, unit: "pt"),
                .slider("subtitleWidth", keyPath: subtitleWidth, range: 220...340, step: 1, unit: "pt"),
                .color("title", keyPath: titleHex),
                .color("subtitle", keyPath: subtitleHex),
            ]),
            .group("screen", children: [
                .color("canvas", keyPath: canvasHex),
                .color("glowStart", keyPath: glowStartHex),
                .color("glowEnd", keyPath: glowEndHex),
                .slider("glowOpacity", keyPath: glowOpacity, range: 0...0.25, step: 0.005),
                .slider("glowHeight", keyPath: glowHeight, range: 280...560, step: 1, unit: "pt"),
                .slider("glowFadeHeight", keyPath: glowFadeHeight, range: 160...420, step: 1, unit: "pt"),
                .slider("glowFadeY", keyPath: glowFadeOffsetY, range: 80...280, step: 1, unit: "pt"),
            ]),
            .group("buttons", children: [
                .slider("copyPadX", keyPath: copyHorizontalPadding, range: 16...48, step: 1, unit: "pt"),
                .slider("copyToButtons", keyPath: copyToButtonsSpacing, range: 16...72, step: 1, unit: "pt"),
                .slider("trailingPad", keyPath: buttonsTrailingPadding, range: 12...48, step: 1, unit: "pt"),
                .slider("buttonGap", keyPath: buttonsSpacing, range: 16...64, step: 1, unit: "pt"),
                .slider("bottomMin", keyPath: buttonsBottomInsetMin, range: 8...48, step: 1, unit: "pt"),
                .slider("bottomFraction", keyPath: buttonsBottomInsetFraction, range: 0...0.1, step: 0.001),
                .slider("skipSize", keyPath: skipSize, range: 14...28, step: 0.5, unit: "pt"),
                .slider("skipWidth", keyPath: skipWidth, range: 56...120, step: 1, unit: "pt"),
                .color("skip", keyPath: skipHex),
                .slider("ctaSize", keyPath: ctaSize, range: 14...28, step: 0.5, unit: "pt"),
                .slider("ctaWidth", keyPath: ctaWidth, range: 140...240, step: 1, unit: "pt"),
                .slider("ctaHeight", keyPath: ctaHeight, range: 48...76, step: 1, unit: "pt"),
                .slider("ctaCorner", keyPath: ctaCornerRadius, range: 12...28, step: 0.5, unit: "pt"),
                .color("ctaFill", keyPath: ctaFillHex),
                .color("ctaText", keyPath: ctaTextHex),
                .slider("ctaShadowOpacity", keyPath: ctaShadowOpacity, range: 0...0.2, step: 0.01),
                .slider("ctaShadowRadius", keyPath: ctaShadowRadius, range: 0...16, step: 0.5, unit: "pt"),
                .slider("ctaShadowY", keyPath: ctaShadowY, range: -4...12, step: 0.5, unit: "pt"),
            ]),
            .group("pageMotion", children: [
                .slider("response", keyPath: pageSpringResponse, range: 0.15...0.8, step: 0.01, unit: "s"),
                .slider("damping", keyPath: pageSpringDamping, range: 0.35...1, step: 0.01),
            ]),
        ]
    }
}

private struct OnboardingStickiesDialRegistrar: View {
    @ObservedObject var store: OnboardingStickiesTuningStore
    @StateObject private var dial = OnboardingStickiesDialKit.makePanel()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: dial.values) { _, values in store.values = values }
            .onAppear { store.values = dial.values }
    }
}

private struct OnboardingAssignDialRegistrar: View {
    @ObservedObject var store: OnboardingAssignTuningStore
    @StateObject private var dial = OnboardingAssignDialKit.makePanel()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: dial.values) { _, values in store.values = values }
            .onAppear { store.values = dial.values }
    }
}

private struct OnboardingWidgetDialRegistrar: View {
    @ObservedObject var store: OnboardingWidgetTuningStore
    @StateObject private var dial = OnboardingWidgetDialKit.makePanel()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: dial.values) { _, values in store.values = values }
            .onAppear { store.values = dial.values }
    }
}

/// Registers the three onboarding panels for DialKit's shared drawer picker.
struct OnboardingDialKitHost: View {
    @ObservedObject var stickiesStore: OnboardingStickiesTuningStore
    @ObservedObject var assignStore: OnboardingAssignTuningStore
    @ObservedObject var widgetStore: OnboardingWidgetTuningStore

    var body: some View {
        ZStack {
            OnboardingStickiesDialRegistrar(store: stickiesStore)
            OnboardingAssignDialRegistrar(store: assignStore)
            OnboardingWidgetDialRegistrar(store: widgetStore)
            DialRoot(position: .topLeft, storageID: "checkmate-onboarding-dialkit")
                .padding(.top, 56)
                .padding(.leading, 8)
        }
    }
}
