import SwiftUI
import UIKit

/// Figma 2050:2976 — scattered oversized sticky cards. Cards deal from a center
/// pile into place, drag anywhere, and check-off rains confetti from the top.
struct OnboardingStickiesPage: View {
    @Environment(\.onboardingStickiesTuning) private var tuning
    @State private var confettiToken = 0
    @State private var spread = false

    private static let cards: [OnboardingCardSpec] = [
        OnboardingCardSpec(text: "Pick up milk", color: .blue, startsChecked: false),
        OnboardingCardSpec(text: "Water plants", color: .orange, startsChecked: false),
        OnboardingCardSpec(text: "Call grandma", color: .yellow, startsChecked: true),
        OnboardingCardSpec(text: "Book dentist", color: .pink, startsChecked: false),
        OnboardingCardSpec(text: "Walk the dog", color: .blue, startsChecked: false)
    ]

    /// Collected pile — each card shares center but keeps its own tilt + peek offset.
    private static let pileLayouts: [(rotation: Double, nudgeX: Double, nudgeY: Double)] = [
        (-14.5, -11, -9),
        (-6.5, 9, -6),
        (2.5, -7, 1),
        (11.5, 10, 5),
        (-10.5, 0, 9)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(Self.cards.enumerated()), id: \.element.id) { index, spec in
                    let layout = tuning.layout(for: index)
                    let pile = Self.pileLayouts[index]
                    OnboardingDraggableCard(
                        spec: spec,
                        canvasWidth: geo.size.width,
                        targetXFraction: layout.x,
                        targetY: layout.y,
                        targetRotation: layout.rotation,
                        pileRotation: pile.rotation,
                        pileNudge: CGSize(width: pile.nudgeX, height: pile.nudgeY),
                        spread: spread,
                        stackOrder: index,
                        tuning: tuning
                    ) {
                        confettiToken += 1
                    }
                    .zIndex(Double(index))
                }

                OnboardingConfettiView(token: confettiToken, tuning: tuning)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .allowsHitTesting(false)
                    .zIndex(1_000)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                spread = false
                DispatchQueue.main.asyncAfter(deadline: .now() + tuning.dealPileHold) {
                    spread = true
                }
            }
        }
    }
}

struct OnboardingCardSpec: Identifiable {
    let id = UUID()
    let text: String
    let color: StickyColor
    let startsChecked: Bool
}

/// Home-page sticky visuals blown up for onboarding — free drag + confetti check-off.
private struct OnboardingDraggableCard: View {
    let spec: OnboardingCardSpec
    let canvasWidth: CGFloat
    let targetXFraction: Double
    let targetY: Double
    let targetRotation: Double
    let pileRotation: Double
    let pileNudge: CGSize
    let spread: Bool
    let stackOrder: Int
    let tuning: OnboardingStickiesTuning
    let onCelebrate: () -> Void

    @State private var checked: Bool
    @State private var checkTrim: CGFloat
    @State private var checkFillScale: CGFloat
    @State private var restOffset: CGSize = .zero
    @State private var dragTranslation: CGSize = .zero
    @State private var dragging = false

    init(
        spec: OnboardingCardSpec,
        canvasWidth: CGFloat,
        targetXFraction: Double,
        targetY: Double,
        targetRotation: Double,
        pileRotation: Double,
        pileNudge: CGSize,
        spread: Bool,
        stackOrder: Int,
        tuning: OnboardingStickiesTuning,
        onCelebrate: @escaping () -> Void
    ) {
        self.spec = spec
        self.canvasWidth = canvasWidth
        self.targetXFraction = targetXFraction
        self.targetY = targetY
        self.targetRotation = targetRotation
        self.pileRotation = pileRotation
        self.pileNudge = pileNudge
        self.spread = spread
        self.stackOrder = stackOrder
        self.tuning = tuning
        self.onCelebrate = onCelebrate
        _checked = State(initialValue: spec.startsChecked)
        _checkTrim = State(initialValue: spec.startsChecked ? 1 : 0)
        _checkFillScale = State(initialValue: spec.startsChecked ? 1 : 0.15)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CGFloat(tuning.cardCornerRadius), style: .continuous)
    }

    private var dealAnimation: Animation {
        .spring(response: tuning.dealSpringResponse, dampingFraction: tuning.dealSpringDamping)
            .delay(Double(stackOrder) * tuning.dealStagger)
    }

    /// Animate offset from the pile — never animate `.position`, which stretches views.
    private var dealOffset: CGSize {
        spread
            ? .zero
            : CGSize(
                width: canvasWidth * (tuning.dealPileX - targetXFraction) + pileNudge.width,
                height: tuning.dealPileY - targetY + pileNudge.height
            )
    }

    var body: some View {
        ZStack {
            spec.color.paper
            content
        }
        .frame(width: CGFloat(tuning.cardWidth), height: CGFloat(tuning.cardHeight))
        .clipShape(cardShape)
        .overlay(cardShape.strokeBorder(Color.white, lineWidth: CGFloat(tuning.cardBorderWidth)))
        .shadow(
            color: .black.opacity(tuning.shadowOpacity),
            radius: CGFloat(tuning.shadowRadius),
            x: 0,
            y: CGFloat(tuning.shadowY)
        )
        .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 0)
        .rotationEffect(.degrees(spread ? targetRotation : pileRotation))
        .animation(dealAnimation, value: spread)
        .scaleEffect(dragging ? tuning.dragLiftScale : 1)
        .animation(Theme.boop, value: dragging)
        .offset(
            x: dealOffset.width + restOffset.width + dragTranslation.width,
            y: dealOffset.height + restOffset.height + dragTranslation.height
        )
        .animation(dealAnimation, value: spread)
        .position(x: canvasWidth * targetXFraction, y: targetY)
        .gesture(dragGesture)
        .zIndex(dragging ? 900 : Double(stackOrder))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if !dragging {
                    dragging = true
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
                dragTranslation = value.translation
            }
            .onEnded { value in
                restOffset.width += value.translation.width
                restOffset.height += value.translation.height
                dragTranslation = .zero
                dragging = false
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                checkbox
                Spacer()
            }
            Spacer(minLength: 0)
            Text(spec.text)
                .font(.system(size: tuning.cardTextSize, weight: .medium))
                .foregroundStyle(checked ? Theme.Palette.strike : Theme.Palette.body)
                .strikethrough(checked, color: Theme.Palette.strike)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(Theme.instant, value: checked)
        }
        .padding(.horizontal, CGFloat(tuning.cardPaddingX))
        .padding(.vertical, CGFloat(tuning.cardPaddingY))
    }

    private var checkbox: some View {
        let size = CGFloat(tuning.checkboxSize)
        let scale = size / 20
        let stroke = CGFloat(tuning.checkboxStrokeWidth)
        return Button { toggleCheck() } label: {
            ZStack {
                if !checked {
                    RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                        .stroke(Theme.Palette.checkboxStroke, lineWidth: stroke)
                        .frame(width: size, height: size)
                }
                if checked {
                    RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                        .fill(Theme.Palette.blue)
                        .frame(width: size, height: size)
                        .scaleEffect(checkFillScale)
                        .overlay(
                            CheckmarkShape()
                                .trim(from: 0, to: checkTrim)
                                .stroke(
                                    Color.white,
                                    style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, lineJoin: .round)
                                )
                                .frame(width: 12 * scale, height: 12 * scale)
                        )
                }
            }
            .frame(width: size + 8, height: size + 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(BoopButtonStyle())
        .accessibilityIdentifier("onboarding.checkbox.\(spec.text)")
    }

    private func toggleCheck() {
        let checkSpring = Animation.spring(
            response: tuning.checkResponse,
            dampingFraction: tuning.checkDamping
        )
        if checked {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(Theme.snappy) {
                checked = false
                checkTrim = 0
                checkFillScale = 0.15
            }
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(checkSpring) {
                checked = true
                checkFillScale = 1
                checkTrim = 1
            }
            onCelebrate()
        }
    }
}
