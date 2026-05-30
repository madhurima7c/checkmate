import SwiftUI

/// Grid cell with pile dimming, tilt, and Pinterest-style hold → drag to edit/delete.
struct StickyNoteGridCell: View {
    let task: CheckmateTask
    var isNewBadge: Bool = false
    var avatarName: String?
    var avatarImageData: Data? = nil
    var allowsEdit: Bool = true
    var onEdit: () -> Void
    var onDelete: () -> Void
    @Binding var focusedTaskId: UUID?

    private let holdDuration: Double = 0.55
    private let holdTilt: Double = 3.34
    private let activationMoveLimit: CGFloat = 14

    @State private var isPressing = false
    @State private var pressBeganAt: Date?
    @State private var highlightedAction: CardAction?
    @State private var bubbleFrames: [CardAction: CGRect] = [:]

    private var isFocused: Bool { focusedTaskId == task.id }
    private var isDimmed: Bool { focusedTaskId != nil && !isFocused }

    var body: some View {
        StickyNoteCardView(
            task: task,
            isNewBadge: isNewBadge,
            avatarName: avatarName,
            avatarImageData: avatarImageData
        )
        .opacity(isDimmed ? 0.26 : 1)
        .rotationEffect(.degrees(isFocused || isPressing ? holdTilt : 0))
        .scaleEffect(isPressing && !isFocused ? 0.99 : 1)
        .animation(.easeOut(duration: 0.12), value: isFocused)
        .animation(.easeOut(duration: 0.08), value: isPressing)
        .zIndex(isFocused ? 5 : 0)
        .overlay(alignment: allowsEdit ? .topTrailing : .topLeading) {
            if isFocused {
                CardActionBubbles(
                    allowsEdit: allowsEdit,
                    highlighted: highlightedAction,
                    onFramesChange: { bubbleFrames = $0 }
                )
                .offset(x: allowsEdit ? 10 : -44, y: allowsEdit ? -18 : -22)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .gesture(holdAndDragGesture, including: .subviews)
    }

    private var holdAndDragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if pressBeganAt == nil {
                    pressBeganAt = Date()
                    isPressing = true
                }

                let elapsed = Date().timeIntervalSince(pressBeganAt ?? Date())
                let moved = hypot(value.translation.width, value.translation.height)

                if !isFocused {
                    if moved > activationMoveLimit {
                        cancelPress()
                        return
                    }
                    if elapsed >= holdDuration {
                        activateFocus()
                    }
                } else {
                    highlightedAction = action(at: value.location)
                }
            }
            .onEnded { value in
                isPressing = false
                pressBeganAt = nil

                guard isFocused else { return }

                if let action = action(at: value.location) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismissFocus()
                    switch action {
                    case .edit: onEdit()
                    case .delete: onDelete()
                    }
                } else {
                    dismissFocus()
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

    private func cancelPress() {
        isPressing = false
        pressBeganAt = nil
    }
}
