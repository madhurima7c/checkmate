import SwiftUI
import UIKit

struct StickyNoteCardView: View {
    let task: CheckmateTask
    var isNewBadge: Bool = false
    var avatarName: String? = nil
    var avatarImageData: Data? = nil

    @State private var checking = false
    @State private var checked = false
    @State private var showBurst = false
    @State private var burstScale: CGFloat = 0.35
    @State private var burstOpacity: Double = 1
    @State private var checkTrim: CGFloat = 0
    @State private var checkFillScale: CGFloat = 0.15

    private let cardShape = RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ZStack {
                    task.color.paper
                    content(in: geo.size)
                }
                .clipShape(cardShape)
                .overlay(cardShape.strokeBorder(Color.white, lineWidth: Theme.Stroke.cardBorder))
                .stickyShadow()
                .scaleEffect(checking ? 0.95 : 1)

                if showBurst {
                    Image("CheckBurst")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .scaleEffect(burstScale)
                        .opacity(burstOpacity)
                        .offset(x: -6, y: -6)
                        .allowsHitTesting(false)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { syncFromTask() }
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
                checkbox
                Spacer()
                if let avatarName {
                    PersonAvatarView(name: avatarName, imageData: avatarImageData, size: 24)
                }
            }

            if isNewBadge {
                Spacer(minLength: 4)
                NewBadge()
            } else {
                Spacer(minLength: 0)
            }

            taskText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var checkbox: some View {
        Button { toggleCheck() } label: {
            ZStack {
                if !checked {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Theme.Palette.checkboxStroke, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
                if checked {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.Palette.blue)
                        .frame(width: 20, height: 20)
                        .scaleEffect(checkFillScale)
                        .overlay(
                            CheckmarkShape()
                                .trim(from: 0, to: checkTrim)
                                .stroke(
                                    Color.white,
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                                )
                                .frame(width: 12, height: 12)
                        )
                }
            }
            .frame(width: 20, height: 20)
        }
        .buttonStyle(BoopButtonStyle())
    }

    private var taskText: some View {
        Text(task.text)
            .font(.system(size: 15, weight: .medium))
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        checking = true
        showBurst = true
        burstScale = 0.25
        burstOpacity = 1
        checkFillScale = 0.2

        withAnimation(Theme.checkPop) {
            checked = true
            checkFillScale = 1
            checkTrim = 1
            burstScale = 1.05
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.58)) {
                burstScale = 1.25
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.easeOut(duration: 0.14)) {
                burstScale = 0.2
                burstOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            TaskStore.shared.markDoneLocally(taskId: task.id)
            checking = false
            showBurst = false
            burstOpacity = 1
            burstScale = 0.35
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

struct NewBadge: View {
    var compact: Bool = false

    private var fontSize: CGFloat { compact ? 11 : 15 }
    private var tracking: CGFloat { compact ? -2.5 : -3.3 }
    private var ovalW: CGFloat { compact ? 38 : 48 }
    private var ovalH: CGFloat { compact ? 17 : 22 }

    var body: some View {
        ZStack {
            Image("NewBadgeOval")
                .resizable()
                .scaledToFit()
                .frame(width: ovalW, height: ovalH)
            Text("NEW")
                .font(FigmaHandFont.badge(size: fontSize))
                .foregroundStyle(Theme.Palette.newRed)
                .tracking(tracking)
        }
        .frame(width: ovalW + 2, height: ovalH)
        .rotationEffect(.degrees(-6))
    }
}

enum FigmaHandFont {
    static func badge(size: CGFloat) -> Font {
        if UIFont(name: "FigmaHand-Regular", size: size) != nil {
            return .custom("FigmaHand-Regular", size: size)
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }
}
