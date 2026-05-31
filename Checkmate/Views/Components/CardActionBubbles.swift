import SwiftUI

/// Long-press action shown while the finger is held (Figma 656:2836 / 656:2837).
enum CardAction: String, CaseIterable {
    case delete
    case edit
}

enum CardActionEditDirection {
    case leading
    case trailing
}

/// Figma — 52pt circles arranged diagonally; selected action fills.
/// Purely visual: selection is driven by the drag location in `CardFocusController`.
struct CardActionBubbles: View {
    var allowsEdit: Bool
    var highlighted: CardAction?
    var editDirection: CardActionEditDirection = .trailing
    var onFramesChange: (([CardAction: CGRect]) -> Void)? = nil

    private let bubbleSize: CGFloat = 52
    private let iconSize: CGFloat = 24
    private let selectedScale: CGFloat = 1.1
    private var editOffset: CGSize {
        editDirection == .trailing ? CGSize(width: 54, height: 42) : CGSize(width: -54, height: 42)
    }
    private var deleteBaseOffset: CGSize {
        editDirection == .trailing ? .zero : CGSize(width: 54, height: 0)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            bubble(for: .delete)
                .offset(deleteBaseOffset)
            if allowsEdit {
                bubble(for: .edit)
                    .offset(
                        x: deleteBaseOffset.width + editOffset.width,
                        y: editOffset.height
                    )
            }
        }
        .frame(
            width: allowsEdit ? bubbleSize + abs(editOffset.width) : bubbleSize,
            height: allowsEdit ? bubbleSize + editOffset.height : bubbleSize,
            alignment: editDirection == .trailing ? .topLeading : .topTrailing
        )
        .onPreferenceChange(BubbleFrameKey.self) { frames in
            onFramesChange?(frames)
        }
    }

    private func bubble(for action: CardAction) -> some View {
        let isHighlighted = highlighted == action
        return ZStack {
            Circle()
                .fill(backgroundColor(for: action, isHighlighted: isHighlighted))
                .shadow(color: .black.opacity(0.07), radius: 4.5, x: 0, y: 2)
                .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 0)

            actionIcon(for: action, isHighlighted: isHighlighted)
        }
        .frame(width: bubbleSize, height: bubbleSize)
        .scaleEffect(isHighlighted ? selectedScale : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.72), value: isHighlighted)
        .background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: BubbleFrameKey.self,
                    value: [action: geo.frame(in: .named(CardFocusSpace.name))]
                )
            }
        }
    }

    private func backgroundColor(for action: CardAction, isHighlighted: Bool) -> Color {
        guard isHighlighted else { return .white }
        switch action {
        case .delete:
            return Color(hex: 0xFA3E3E)
        case .edit:
            return Color(hex: 0x393834)
        }
    }

    @ViewBuilder
    private func actionIcon(for action: CardAction, isHighlighted: Bool) -> some View {
        let name = action == .delete ? "ActionTrash" : "ActionPencil"
        if isHighlighted {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(name)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        }
    }
}

private struct BubbleFrameKey: PreferenceKey {
    static var defaultValue: [CardAction: CGRect] = [:]

    static func reduce(value: inout [CardAction: CGRect], nextValue: () -> [CardAction: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
