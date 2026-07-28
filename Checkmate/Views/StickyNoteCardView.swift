import SwiftUI
import UIKit

struct StickyNoteCardView: View {
    let task: CheckmateTask
    var isNewBadge: Bool = false
    var avatarName: String? = nil
    var avatarImageData: Data? = nil
    var showsCheckbox: Bool = true
    /// When false, the checkbox ignores touches (e.g. during press-and-hold on the card).
    var allowsCheckboxTap: Bool = true
    @Environment(\.homePageTuning) private var tuning

    @State private var checking = false
    @State private var checked = false
    @State private var showBurst = false
    @State private var burstOpacity: Double = 1
    @State private var burstToken = 0
    @State private var checkTrim: CGFloat = 0
    @State private var checkFillScale: CGFloat = 0.15

    private let cardShape = RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                task.color.paper
                content(in: geo.size)
            }
            .clipShape(cardShape)
            .overlay(cardShape.strokeBorder(Color.white, lineWidth: Theme.Stroke.cardBorder))
            .stickyShadow()
            .scaleEffect(checking ? 0.95 : 1)
            // Confetti sits outside the paper clip so it can burst past the card edge.
            .overlay {
                if showBurst {
                    let confettiWidth = geo.size.width * CGFloat(tuning.confettiScale)
                    CheckConfettiView(speed: tuning.confettiSpeed)
                        .frame(
                            width: confettiWidth,
                            height: confettiWidth / CheckConfettiView.aspectRatio
                        )
                        .offset(
                            x: CGFloat(tuning.confettiXOffset),
                            y: CGFloat(tuning.confettiYOffset)
                        )
                        .opacity(burstOpacity)
                        .allowsHitTesting(false)
                        .id(burstToken)
                }
            }
        }
        .aspectRatio(CGFloat(tuning.cardAspectRatio), contentMode: .fit)
        .preference(key: HomeConfettiBurstKey.self, value: showBurst)
        .zIndex(showBurst ? 80 : 0)
        .onAppear {
            syncFromTask()
            ConfettiCelebration.shared.prewarm()
        }
        .onChange(of: task.status) { _, _ in syncFromTask() }
    }

    private func syncFromTask() {
        checked = task.status == .done
        checkTrim = checked ? 1 : 0
        checkFillScale = checked ? 1 : 0.15
        showBurst = false
        burstOpacity = 1
    }

    private func content(in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                if showsCheckbox {
                    checkbox
                }
                Spacer()
                if let avatarName {
                    PersonAvatarView(
                        name: avatarName,
                        imageData: avatarImageData,
                        size: CGFloat(tuning.avatarSize)
                    )
                }
            }

            if isNewBadge {
                Spacer(minLength: 4)
                NewBadge()
            } else {
                Spacer(minLength: 0)
            }

            taskText
                .padding(.top, isNewBadge ? 12 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var checkbox: some View {
        let checkboxSize = CGFloat(tuning.checkboxSize)
        let scale = checkboxSize / 20
        return Button { toggleCheck() } label: {
            ZStack {
                if !checked {
                    RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                        .stroke(Theme.Palette.checkboxStroke, lineWidth: 2 * scale)
                        .frame(width: checkboxSize, height: checkboxSize)
                }
                if checked {
                    RoundedRectangle(cornerRadius: 6 * scale, style: .continuous)
                        .fill(Theme.Palette.blue)
                        .frame(width: checkboxSize, height: checkboxSize)
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
            .frame(width: checkboxSize, height: checkboxSize)
        }
        .buttonStyle(BoopButtonStyle())
        .allowsHitTesting(allowsCheckboxTap)
        .accessibilityIdentifier("home.checkbox.\(task.text)")
    }

    private var taskText: some View {
        Text(task.text)
            .font(.system(size: CGFloat(tuning.cardTextSize), weight: .medium))
            .foregroundStyle(checked ? Theme.Palette.strike : Theme.Palette.body)
            .strikethrough(checked, color: Theme.Palette.strike)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(Theme.instant, value: checked)
    }

    private func toggleCheck() {
        if checked { undoCheck() } else { completeCheck() }
    }

    private func completeCheck() {
        ConfettiCelebration.shared.play(
            volume: tuning.confettiVolume,
            hapticIntensity: tuning.confettiHapticIntensity,
            sound: tuning.confettiSoundEnabled,
            haptics: tuning.confettiHapticsEnabled
        )
        checking = true
        burstToken += 1
        showBurst = true
        burstOpacity = 1
        checkFillScale = 0.2

        withAnimation(Theme.checkPop) {
            checked = true
            checkFillScale = 1
            checkTrim = 1
        }

        // Release the press-squish as soon as the check pop lands; the
        // confetti keeps playing until doneDelay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(Theme.snappy) {
                checking = false
            }
        }

        let doneDelay = max(0.2, tuning.confettiDoneDelay)
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.1, doneDelay - 0.16)) {
            withAnimation(.easeOut(duration: 0.14)) {
                burstOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + doneDelay) {
            TaskStore.shared.markDoneLocally(taskId: task.id)
            checking = false
            showBurst = false
            burstOpacity = 1
        }
    }

    private func undoCheck() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(Theme.snappy) {
            checked = false
            checkTrim = 0
            checkFillScale = 0.15
            showBurst = false
            burstOpacity = 1
        }
        TaskStore.shared.undoPendingLocally(taskId: task.id)
    }
}

/// Grid cells raise z-index while a home-page Lottie burst is active so the
/// confetti can paint over neighboring cards.
struct HomeConfettiBurstKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.78))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.25))
        return path
    }
}

/// Figma 670:3064 — hand-drawn “NEW” label (oval stroke + letterforms, #F83A00).
struct NewBadge: View {
    /// Artboard size from Figma (49.11 × 22.47pt).
    private static let artboard = CGSize(width: 49.1131, height: 22.4651)

    var body: some View {
        Image("NewBadge")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: Self.artboard.width, height: Self.artboard.height)
            .accessibilityLabel("New")
    }
}
