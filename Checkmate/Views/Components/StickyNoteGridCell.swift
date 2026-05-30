import SwiftUI

/// Grid cell. Press-and-hold lifts the card into `CardFocusController`'s overlay; the
/// finger then drags near an action bubble and release selects it. Quick swipes keep
/// scrolling untouched.
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
    @ObservedObject var controller: CardFocusController

    private let holdDuration: Double = 0.35

    @State private var cellFrame: CGRect = .zero

    private var isFocused: Bool { controller.focusedId == task.id }

    var body: some View {
        StickyNoteCardView(
            task: task,
            isNewBadge: isNewBadge,
            avatarName: avatarName,
            avatarImageData: avatarImageData
        )
        .opacity(isFocused ? 0 : 1)
        .background(frameReader)
        .contentShape(Rectangle())
        .simultaneousGesture(holdThenDragGesture)
        .onDisappear {
            if isFocused {
                controller.clear()
            }
        }
    }

    private var frameReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { cellFrame = geo.frame(in: .named(CardFocusSpace.name)) }
                .onChange(of: geo.frame(in: .named(CardFocusSpace.name))) { _, newValue in
                    cellFrame = newValue
                }
        }
    }

    /// Drag only begins after the long-press succeeds, so vertical swipes still scroll.
    private var holdThenDragGesture: some Gesture {
        LongPressGesture(minimumDuration: holdDuration, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(CardFocusSpace.name)))
            .onChanged { value in
                switch value {
                case .first(true):
                    guard cellFrame != .zero, !controller.isActive else { return }
                    controller.begin(focusedCard)
                case .second(true, let drag?):
                    controller.updateDrag(drag.location)
                default:
                    break
                }
            }
            .onEnded { value in
                if case .second(true, let drag?) = value {
                    controller.updateDrag(drag.location)
                }
                if controller.focusedId == task.id {
                    controller.end()
                }
            }
    }

    private var focusedCard: CardFocusController.FocusedCard {
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
