import SwiftUI
import UIKit

struct StickyNoteCardView: View {
    let task: CheckmateTask
    var isNewBadge: Bool = false
    var namespace: Namespace.ID? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var checking = false
    @State private var checked = false
    @State private var showBurst = false
    @State private var checkTrim: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                task.color.paper
                content(in: geo.size)
                if showBurst {
                    CheckBurstView()
                        .frame(width: 44, height: 44)
                        .position(x: 22, y: 22)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: Theme.Stroke.cardBorder)
            )
            .stickyShadow()
            .scaleEffect(checking ? 0.95 : 1)
        }
        .aspectRatio(1, contentMode: .fit)
        .contextMenu {
            if let onEdit {
                Button { onEdit() } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            if let onDelete {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onAppear {
            checked = task.status == .done
            checkTrim = checked ? 1 : 0
        }
        .onChange(of: task.status) { _, status in
            checked = status == .done
            checkTrim = checked ? 1 : 0
        }
    }

    private func content(in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                checkbox
                Spacer()
                if task.isAssignedToFriend {
                    assigneePin
                }
            }

            if isNewBadge {
                NewBadge()
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)

            taskText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var assigneePin: some View {
        PersonAvatarView(
            name: task.assigneeName ?? "?",
            size: 24
        )
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
        if checked {
            undoCheck()
        } else {
            completeCheck()
        }
    }

    private func completeCheck() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        checking = true
        showBurst = true
        withAnimation(Theme.snappy) {
            checked = true
            checkTrim = 1
        }
        TaskStore.shared.markDoneLocally(taskId: task.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            checking = false
            showBurst = false
        }
    }

    private func undoCheck() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(Theme.snappy) {
            checked = false
            checkTrim = 0
            showBurst = false
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
    var body: some View {
        ZStack {
            Image("NewBadgeOval")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 22)
            Text("NEW")
                .font(FigmaHandFont.badge)
                .foregroundStyle(Theme.Palette.newRed)
                .tracking(-3.3)
        }
        .frame(width: 48, height: 22)
        .rotationEffect(.degrees(-6))
    }
}

enum FigmaHandFont {
    static let badge: Font = {
        if UIFont(name: "FigmaHand-Regular", size: 15) != nil {
            return .custom("FigmaHand-Regular", size: 15)
        }
        return .system(size: 15, weight: .bold, design: .rounded)
    }()
}
