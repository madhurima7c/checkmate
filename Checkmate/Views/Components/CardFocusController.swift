import SwiftUI

/// Coordinate space shared by the grid cells and the focus overlay so frames line up.
enum CardFocusSpace {
    static let name = "cardFocusRoot"
}

/// Drives the Pinterest-style press-and-hold focus: the card stays in its grid
/// position, the rest of the app is blocked by a full-screen dim, and releasing near
/// an action bubble selects it.
@MainActor
final class CardFocusController: ObservableObject {
    struct FocusedCard {
        let id: UUID
        let task: CheckmateTask
        let isNewBadge: Bool
        let avatarName: String?
        let avatarImageData: Data?
        let allowsEdit: Bool
        let edge: StickyNoteGridCell.ActionEdge
        let frame: CGRect
        let onEdit: () -> Void
        let onDelete: () -> Void
    }

    @Published private(set) var focused: FocusedCard?
    @Published private(set) var highlighted: CardAction?
    @Published private(set) var fingerLocation: CGPoint?
    var tuning: CardFocusTuning = .default
    private var bubbleFrames: [CardAction: CGRect] = [:]
    private var focusGeneration = 0
    private let holdFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let actionFeedback = UIImpactFeedbackGenerator(style: .light)

    var focusedId: UUID? { focused?.id }
    var isActive: Bool { focused != nil }

    func begin(_ card: FocusedCard, finger: CGPoint? = nil) {
        guard focused == nil else { return }
        holdFeedback.prepare()
        selectionFeedback.prepare()
        actionFeedback.prepare()
        holdFeedback.impactOccurred()
        focusGeneration += 1
        let generation = focusGeneration
        bubbleFrames = actionFrames(for: card)
        highlighted = nil
        fingerLocation = nil
        withAnimation(Theme.boop) {
            focused = card
        }
        if let finger {
            updateDrag(finger)
        }
        Task { @MainActor in
            let timeout = tuning.focusTimeout
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            if self.focusGeneration == generation {
                self.clear()
            }
        }
    }

    func updateDrag(_ location: CGPoint) {
        guard focused != nil else { return }
        fingerLocation = location
        let next = action(at: location)
        if next != highlighted {
            if next != nil {
                selectionFeedback.selectionChanged()
                selectionFeedback.prepare()
            }
            withAnimation(.easeOut(duration: 0.1)) {
                highlighted = next
            }
        }
    }

    func end() {
        guard let focused else {
            clear()
            return
        }
        let selected = fingerLocation.flatMap { action(at: $0) } ?? highlighted
        clear()
        guard let selected else { return }
        actionFeedback.impactOccurred()
        actionFeedback.prepare()
        switch selected {
        case .edit: focused.onEdit()
        case .delete: focused.onDelete()
        }
    }

    func clear() {
        focusGeneration += 1
        bubbleFrames = [:]
        withAnimation(.easeOut(duration: 0.14)) {
            focused = nil
            highlighted = nil
            fingerLocation = nil
        }
    }

    func reportBubbleFrames(_ frames: [CardAction: CGRect]) {
        guard !frames.isEmpty, let card = focused else { return }
        // Ignore layout glitches; only accept frames plausibly near the focused card.
        let search = card.frame.insetBy(dx: -100, dy: -100)
        guard frames.values.contains(where: { search.intersects($0) }) else { return }
        bubbleFrames = frames
    }

    private func action(at location: CGPoint) -> CardAction? {
        let magneticRadius = tuning.magneticRadius
        var best: (action: CardAction, distance: CGFloat)?
        for (action, frame) in bubbleFrames {
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let distance = hypot(location.x - center.x, location.y - center.y)
            let threshold = max(frame.width, frame.height) / 2 + magneticRadius
            guard distance <= threshold else { continue }
            if best == nil || distance < best!.distance {
                best = (action, distance)
            }
        }
        return best?.action
    }

    private func actionFrames(for card: FocusedCard) -> [CardAction: CGRect] {
        let bubbleSize = tuning.bubbleSize
        let editDelta = tuning.editDelta(for: card.edge)
        let offset = tuning.bubbleOffset(for: card.edge)
        let x: CGFloat

        switch card.edge {
        case .trailing:
            x = card.frame.maxX - bubbleSize + offset.width
        case .leading:
            x = card.frame.minX + offset.width
        }

        let deleteFrame = CGRect(
            x: x,
            y: card.frame.minY + offset.height,
            width: bubbleSize,
            height: bubbleSize
        )

        guard card.allowsEdit else {
            return [.delete: deleteFrame]
        }

        return [
            .delete: deleteFrame,
            .edit: deleteFrame.offsetBy(dx: editDelta.width, dy: editDelta.height)
        ]
    }
}

// MARK: - Root overlay

/// Full-screen overlay rendered above the app while a card is focused. The selected
/// card is positioned at its captured screen frame so it does not visibly move.
struct CardFocusOverlay: View {
    @ObservedObject var controller: CardFocusController

    var body: some View {
        GeometryReader { _ in
            if let card = controller.focused {
                ZStack(alignment: .topLeading) {
                    Color.white.opacity(controller.tuning.overlayOpacity)
                        .ignoresSafeArea()

                    focusedCard(card)
                        .frame(width: card.frame.width, height: card.frame.height)
                        .offset(x: card.frame.minX, y: card.frame.minY)
                }
                // Visual only — the grid cell under this overlay keeps the
                // active touch so drag → highlight → release still works.
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
    }

    private func focusedCard(_ card: CardFocusController.FocusedCard) -> some View {
        let tilt = card.edge == .leading ? -controller.tuning.holdTilt : controller.tuning.holdTilt
        return FocusedCardLift(tilt: tilt, startScale: controller.tuning.liftStartScale) {
            StickyNoteCardView(
                task: card.task,
                isNewBadge: card.isNewBadge,
                avatarName: card.avatarName,
                avatarImageData: card.avatarImageData,
                showsCheckbox: false
            )
            .overlay(alignment: card.edge == .trailing ? .topTrailing : .topLeading) {
                CardActionBubbles(
                    tuning: controller.tuning,
                    allowsEdit: card.allowsEdit,
                    highlighted: controller.highlighted,
                    editDirection: card.edge == .trailing ? .trailing : .leading,
                    onFramesChange: { controller.reportBubbleFrames($0) }
                )
                .offset(controller.tuning.bubbleOffset(for: card.edge))
            }
        }
    }
}

/// Springs the focused card + action bubbles from a press scale into the tilted hold pose.
private struct FocusedCardLift<Content: View>: View {
    let tilt: Double
    let startScale: CGFloat
    @ViewBuilder var content: () -> Content

    @State private var lifted = false

    var body: some View {
        content()
            .scaleEffect(lifted ? 1 : startScale)
            .rotationEffect(.degrees(lifted ? tilt : 0))
            .onAppear {
                withAnimation(Theme.boop) {
                    lifted = true
                }
            }
    }
}
