import SwiftUI

/// Grid cell with pile dimming, tilt, and Pinterest-style hold → drag to edit/delete.
struct StickyNoteGridCell: View {
    enum ActionEdge {
        case leading
        case trailing
    }

    let task: CheckmateTask
    var isNewBadge: Bool = false
    var avatarName: String?
    var avatarImageData: Data? = nil
    var allowsEdit: Bool = true
    var actionEdge: ActionEdge = .trailing
    var onEdit: () -> Void
    var onDelete: () -> Void
    @Binding var focusedTaskId: UUID?

    private let holdDuration: Double = 0.55
    private let holdTilt: Double = 3.34

    @State private var highlightedAction: CardAction?
    @State private var bubbleFrames: [CardAction: CGRect] = [:]

    private var isFocused: Bool { focusedTaskId == task.id }
    private var isDimmed: Bool { focusedTaskId != nil && !isFocused }
    private var overlayAlignment: Alignment { actionEdge == .trailing ? .topTrailing : .topLeading }
    private var bubbleOffset: CGSize {
        if actionEdge == .trailing {
            CGSize(width: 26, height: -20)
        } else {
            CGSize(width: -26, height: -20)
        }
    }

    var body: some View {
        StickyNoteCardView(
            task: task,
            isNewBadge: isNewBadge,
            avatarName: avatarName,
            avatarImageData: avatarImageData
        )
        .opacity(isDimmed ? 0.14 : 1)
        .overlay {
            if isDimmed {
                Color.white.opacity(0.72)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .rotationEffect(.degrees(isFocused ? holdTilt : 0))
        .animation(.easeOut(duration: 0.12), value: isFocused)
        .zIndex(isFocused ? 5 : 0)
        .overlay(alignment: overlayAlignment) {
            if isFocused {
                CardActionBubbles(
                    allowsEdit: allowsEdit,
                    highlighted: highlightedAction,
                    onFramesChange: { bubbleFrames = $0 }
                )
                .offset(bubbleOffset)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .gesture(holdThenDragGesture)
    }

    /// Long-press must finish before drag is recognized — quick swipes scroll normally.
    private var holdThenDragGesture: some Gesture {
        LongPressGesture(minimumDuration: holdDuration, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                switch value {
                case .first(true):
                    if !isFocused {
                        activateFocus()
                    }
                case .second(true, let drag?):
                    if isFocused {
                        highlightedAction = action(at: drag.location)
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                switch value {
                case .second(true, let drag?):
                    guard isFocused else { return }
                    if let action = action(at: drag.location) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismissFocus()
                        switch action {
                        case .edit: onEdit()
                        case .delete: onDelete()
                        }
                    } else {
                        dismissFocus()
                    }
                case .first(true):
                    dismissFocus()
                default:
                    if isFocused {
                        dismissFocus()
                    }
                }
            }
    }

    private func action(at location: CGPoint) -> CardAction? {
        let hitPadding: CGFloat = 10
        for action in bubbleFrames.keys {
            guard let frame = bubbleFrames[action] else { continue }
            let hit = frame.insetBy(dx: -hitPadding, dy: -hitPadding)
            if hit.contains(location) { return action }
        }
        return nil
    }

    private func activateFocus() {
        guard focusedTaskId == nil || focusedTaskId == task.id else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeOut(duration: 0.15)) {
            focusedTaskId = task.id
        }
    }

    private func dismissFocus() {
        withAnimation(.easeOut(duration: 0.12)) {
            focusedTaskId = nil
            highlightedAction = nil
        }
    }
}
