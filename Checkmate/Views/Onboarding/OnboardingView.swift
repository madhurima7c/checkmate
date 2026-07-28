import SwiftUI

/// Figma 2050:2976 (stickies) / 598:2632 (assign) / 598:2655 (widget) —
/// three-page onboarding flow. Presented full screen on first launch and
/// replayable from Settings → Onboarding.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(CheckmateConfig.Onboarding.completedKey) private var onboardingCompleted = false
    @AppStorage(CheckmateConfig.DialKit.onboardingKey) private var dialKitOnboardingEnabled = false

    @StateObject private var stickiesStore = OnboardingStickiesTuningStore.shared
    @StateObject private var assignStore = OnboardingAssignTuningStore.shared
    @StateObject private var widgetStore = OnboardingWidgetTuningStore.shared

    @State private var page: OnboardingPage = {
        // QA hook: SIMCTL_CHILD_ONBOARDING_PAGE=1 opens straight to a page.
        if let raw = ProcessInfo.processInfo.environment["ONBOARDING_PAGE"],
           let index = Int(raw),
           let override = OnboardingPage(rawValue: index) {
            return override
        }
        return .stickies
    }()

    private var chrome: any OnboardingChromeReadable {
        guard dialKitOnboardingEnabled else { return OnboardingChromeDefaults.shared }
        switch page {
        case .stickies: return stickiesStore.values
        case .assign: return assignStore.values
        case .widget: return widgetStore.values
        }
    }

    private var activeStickies: OnboardingStickiesTuning {
        dialKitOnboardingEnabled ? stickiesStore.values : .default
    }

    private var activeAssign: OnboardingAssignTuning {
        dialKitOnboardingEnabled ? assignStore.values : .default
    }

    private var activeWidget: OnboardingWidgetTuning {
        dialKitOnboardingEnabled ? widgetStore.values : .default
    }

    private var pageAnimation: Animation {
        .spring(response: chrome.pageSpringResponse, dampingFraction: chrome.pageSpringDamping)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color(dialHex: chrome.canvasHex)

                OnboardingTopGlow(width: geo.size.width, chrome: chrome)

                pageContent
                    .frame(width: geo.size.width, height: geo.size.height)

                chromeOverlay(size: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)

                if dialKitOnboardingEnabled {
                    OnboardingDialKitHost(
                        stickiesStore: stickiesStore,
                        assignStore: assignStore,
                        widgetStore: widgetStore
                    )
                    .zIndex(100)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .statusBarHidden(false)
        .environment(\.onboardingStickiesTuning, activeStickies)
        .environment(\.onboardingAssignTuning, activeAssign)
        .environment(\.onboardingWidgetTuning, activeWidget)
    }

    private var pageContent: some View {
        ZStack {
            switch page {
            case .stickies:
                OnboardingStickiesPage()
                    .transition(Self.pageTransition)
            case .assign:
                OnboardingAssignPage()
                    .transition(Self.pageTransition)
            case .widget:
                OnboardingWidgetPage()
                    .transition(Self.pageTransition)
            }
        }
        .animation(pageAnimation, value: page)
    }

    private static let pageTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    // MARK: - Bottom chrome (copy + Skip / Next)

    private func chromeOverlay(size: CGSize) -> some View {
        let c = chrome
        return VStack(alignment: .leading, spacing: 0) {
            Spacer()

            ZStack(alignment: .topLeading) {
                copyBlock(for: page, chrome: c)
                    .id(page)
                    .transition(Self.pageTransition)
            }
            .animation(pageAnimation, value: page)
            .padding(.horizontal, CGFloat(c.copyHorizontalPadding))
            .frame(maxWidth: size.width, alignment: .leading)

            Spacer().frame(height: CGFloat(c.copyToButtonsSpacing))

            // Figma 2061:4608 Skip (80×62) + 2063:4678 Next (180×62), y=780.
            HStack(alignment: .center, spacing: CGFloat(c.buttonsSpacing)) {
                Button {
                    finish()
                } label: {
                    Text("Skip")
                        .font(.system(size: c.skipSize, weight: .semibold))
                        .foregroundStyle(
                            dialKitOnboardingEnabled
                                ? Color(dialHex: c.skipHex)
                                : Theme.Palette.strike
                        )
                        .frame(width: CGFloat(c.skipWidth), height: CGFloat(c.ctaHeight))
                        .contentShape(
                            RoundedRectangle(cornerRadius: CGFloat(c.ctaCornerRadius), style: .continuous)
                        )
                }
                .buttonStyle(BoopButtonStyle())
                .fixedSize()

                Button {
                    advance()
                } label: {
                    Text(page.ctaTitle)
                        .font(.system(size: c.ctaSize, weight: .semibold))
                        .foregroundStyle(Color(dialHex: c.ctaTextHex))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(width: CGFloat(c.ctaWidth), height: CGFloat(c.ctaHeight))
                        .background(
                            RoundedRectangle(cornerRadius: CGFloat(c.ctaCornerRadius), style: .continuous)
                                .fill(Color(dialHex: c.ctaFillHex))
                                .shadow(
                                    color: .black.opacity(c.ctaShadowOpacity),
                                    radius: CGFloat(c.ctaShadowRadius),
                                    x: 0,
                                    y: CGFloat(c.ctaShadowY)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CGFloat(c.ctaCornerRadius), style: .continuous)
                                .stroke(Color.black.opacity(0.03), lineWidth: 1)
                        )
                }
                .buttonStyle(BoopButtonStyle())
                .fixedSize()

                Spacer(minLength: 0)
            }
            .frame(maxWidth: size.width, alignment: .leading)
            .padding(.horizontal, CGFloat(c.copyHorizontalPadding))
            .padding(.bottom, max(size.height * c.buttonsBottomInsetFraction, c.buttonsBottomInsetMin))
        }
        .animation(nil)
    }

    private func copyBlock(for page: OnboardingPage, chrome c: any OnboardingChromeReadable) -> some View {
        VStack(alignment: .leading, spacing: CGFloat(c.titleSubtitleSpacing)) {
            Text(page.title)
                .font(.system(size: c.titleSize, weight: .semibold))
                .foregroundStyle(Color(dialHex: c.titleHex))
                .fixedSize(horizontal: false, vertical: true)
            Text(page.subtitle)
                .font(.system(size: c.subtitleSize, weight: .semibold))
                .foregroundStyle(Color(dialHex: c.subtitleHex))
                .frame(width: CGFloat(c.subtitleWidth), alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: CGFloat(c.subtitleWidth), alignment: .leading)
    }

    private func advance() {
        switch page {
        case .stickies:
            withAnimation(pageAnimation) { page = .assign }
        case .assign:
            withAnimation(pageAnimation) { page = .widget }
        case .widget:
            finish()
        }
    }

    private func finish() {
        onboardingCompleted = true
        dismiss()
    }
}

enum OnboardingPage: Int, CaseIterable {
    case stickies
    case assign
    case widget

    var title: String {
        switch self {
        case .stickies: "Todos that feel delightful"
        case .assign: "Assign to contacts"
        case .widget: "Glance with a widget"
        }
    }

    var subtitle: String {
        switch self {
        case .stickies: "Celebrate every task and get ahead of your day."
        case .assign: "Give a todo to a friend so your list and theirs stay in sync."
        case .widget: "Today at a glance, from your home screen."
        }
    }

    var ctaTitle: String {
        switch self {
        case .stickies, .assign: "Next"
        case .widget: "Add widget"
        }
    }
}

/// Figma 2051:3081 — soft pink→gold wash behind the top of every
/// onboarding page, dissolved into canvas by a vertical fade.
struct OnboardingTopGlow: View {
    let width: CGFloat
    var chrome: any OnboardingChromeReadable = OnboardingChromeDefaults.shared

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(dialHex: chrome.glowStartHex), Color(dialHex: chrome.glowEndHex)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(chrome.glowOpacity)
            .frame(width: width * 1.1, height: CGFloat(chrome.glowHeight))
            .rotationEffect(.degrees(-0.45))
            .offset(y: -27)

            LinearGradient(
                stops: [
                    .init(color: Color(dialHex: chrome.canvasHex).opacity(0), location: 0),
                    .init(color: Color(dialHex: chrome.canvasHex), location: 0.586)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: CGFloat(chrome.glowFadeHeight))
            .offset(y: CGFloat(chrome.glowFadeOffsetY))
        }
        .frame(width: width, alignment: .top)
        .allowsHitTesting(false)
    }
}
