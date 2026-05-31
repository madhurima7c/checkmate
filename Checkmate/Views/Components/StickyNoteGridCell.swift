import SwiftUI
import UIKit

/// Tap the checkbox to toggle done/undone. Press-and-hold the card body for edit/delete.
struct StickyNoteGridCell: View {
    enum ActionEdge { case leading, trailing }

    let task: CheckmateTask
    var isNewBadge: Bool = false
    var avatarName: String?
    var avatarImageData: Data? = nil
    var allowsEdit: Bool = true
    /// Right column in the two-up grid (actions on the left of the card).
    var isRightColumn: Bool = false
    var onEdit: () -> Void
    var onDelete: () -> Void
    @ObservedObject var controller: CardFocusController

    /// Short hold so focus feels immediate; movement cancels (scroll).
    private let holdDuration: TimeInterval = 0.42
    private let holdMoveLimit: CGFloat = 16
    private let pressScaleAmount: CGFloat = 0.94

    @State private var cellFrame: CGRect = .zero
    @State private var isPressing = false
    @State private var pressScale: CGFloat = 1
    @State private var holdTask: Task<Void, Never>?
    @State private var gestureActive = false
    @State private var startedInCheckbox = false
    @State private var lastFinger: CGPoint?
    @State private var blockCheckboxTap = false

    private var isFocused: Bool { controller.focusedId == task.id }

    private let checkboxExclusion = CGRect(x: 0, y: 0, width: 52, height: 52)

    private var actionEdge: ActionEdge {
        isRightColumn ? .leading : .trailing
    }

    private var allowsCheckboxTap: Bool {
        !gestureActive && !isPressing && !blockCheckboxTap && !isFocused
    }

    var body: some View {
        StickyNoteCardView(
            task: task,
            isNewBadge: isNewBadge,
            avatarName: avatarName,
            avatarImageData: avatarImageData,
            allowsCheckboxTap: allowsCheckboxTap
        )
        .scaleEffect(isFocused ? 1 : pressScale)
        .animation(Theme.snappy, value: pressScale)
        .opacity(isFocused ? 0 : 1)
        .background(frameTracker)
        .overlay(holdOverlay)
        .onDisappear {
            cancelPressFeedback()
            if isFocused { controller.clear() }
        }
    }

    // MARK: - Hold overlay

    @ViewBuilder
    private var holdOverlay: some View {
        let overlay = Color.clear
            .contentShape(CardPressShape(exclusion: checkboxExclusion), eoFill: true)

        if isRightColumn {
            overlay.highPriorityGesture(pressAndHoldGesture)
        } else {
            overlay.simultaneousGesture(pressAndHoldGesture)
        }
    }

    // MARK: - Gesture

    private var pressAndHoldGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(CardFocusSpace.name))
            .onChanged { value in
                lastFinger = value.location

                if !gestureActive {
                    if isStartInCheckbox(value.startLocation) {
                        startedInCheckbox = true
                        return
                    }
                    gestureActive = true
                }
                guard !startedInCheckbox else { return }

                let moved = hypot(value.translation.width, value.translation.height)

                if !controller.isActive {
                    if !isPressing {
                        startPressFeedback()
                    } else if moved > holdMoveLimit {
                        cancelPressFeedback()
                        return
                    }
                }

                if controller.focusedId == task.id {
                    controller.updateDrag(value.location)
                }
            }
            .onEnded { value in
                let engagedHold = isPressing || controller.focusedId == task.id
                defer {
                    gestureActive = false
                    startedInCheckbox = false
                    lastFinger = nil
                }
                guard !startedInCheckbox else { return }

                if controller.focusedId == task.id {
                    controller.updateDrag(value.location)
                    controller.end()
                }
                cancelPressFeedback()

                if engagedHold {
                    blockCheckboxTap = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        blockCheckboxTap = false
                    }
                }
            }
    }

    // MARK: - Press feedback

    private func startPressFeedback() {
        isPressing = true
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(Theme.snappy) {
            pressScale = pressScaleAmount
        }

        holdTask?.cancel()
        holdTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(holdDuration))
            guard !Task.isCancelled, isPressing, !controller.isActive, cellFrame != .zero else { return }
            controller.begin(makeFocusedCard(), finger: lastFinger)
        }
    }

    private func cancelPressFeedback() {
        holdTask?.cancel()
        holdTask = nil
        isPressing = false
        guard !isFocused else { return }
        withAnimation(Theme.snappy) {
            pressScale = 1
        }
    }

    // MARK: - Frame tracking

    private var frameTracker: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { cellFrame = geo.frame(in: .named(CardFocusSpace.name)) }
                .onChange(of: geo.frame(in: .named(CardFocusSpace.name))) { _, frame in
                    cellFrame = frame
                }
        }
    }

    // MARK: - Helpers

    private func isStartInCheckbox(_ location: CGPoint) -> Bool {
        guard cellFrame != .zero else { return false }
        let checkbox = CGRect(
            x: cellFrame.minX + checkboxExclusion.minX,
            y: cellFrame.minY + checkboxExclusion.minY,
            width: checkboxExclusion.width,
            height: checkboxExclusion.height
        )
        return checkbox.contains(location)
    }

    private func makeFocusedCard() -> CardFocusController.FocusedCard {
        CardFocusController.FocusedCard(
            id: task.id,
            task: task,
            isNewBadge: isNewBadge,
            avatarName: avatarName,
            avatarImageData: avatarImageData,
            allowsEdit: allowsEdit,
            edge: actionEdge,
            frame: cellFrame,
            onEdit: onEdit,
            onDelete: onDelete
        )
    }
}

// MARK: - Hit-test shape with checkbox hole

private struct CardPressShape: Shape {
    let exclusion: CGRect

    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addRect(exclusion)
        return p
    }
}
