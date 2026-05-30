import SwiftUI

/// Long-press action shown while the finger is held (Figma 656:2836 / 656:2837).
enum CardAction: String, CaseIterable {
    case delete
    case edit
}

/// Figma — 52pt white circles; delete above edit on the right, or delete alone on the left.
struct CardActionBubbles: View {
    var allowsEdit: Bool
    var highlighted: CardAction?
    var onFramesChange: (([CardAction: CGRect]) -> Void)? = nil

    private let bubbleSize: CGFloat = 52
    private let iconSize: CGFloat = 24
    private let stackSpacing: CGFloat = 4

    private var actions: [CardAction] {
        allowsEdit ? [.delete, .edit] : [.delete]
    }

    var body: some View {
        Group {
            if allowsEdit {
                VStack(spacing: stackSpacing) {
                    ForEach(actions, id: \.self) { action in
                        bubble(for: action)
                    }
                }
            } else {
                bubble(for: .delete)
            }
        }
        .onPreferenceChange(BubbleFrameKey.self) { frames in
            onFramesChange?(frames)
        }
    }

    private func bubble(for action: CardAction) -> some View {
        let isHighlighted = highlighted == action
        return ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 4.5, x: 0, y: 2)
                .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 0)

            Image(systemName: action == .delete ? "trash" : "pencil")
                .font(.system(size: iconSize * 0.58, weight: .semibold))
                .foregroundStyle(action == .delete ? Color(hex: 0xFF3B30) : Theme.Palette.ink)
        }
        .frame(width: bubbleSize, height: bubbleSize)
        .scaleEffect(isHighlighted ? 1.08 : 1)
        .animation(Theme.snappy, value: isHighlighted)
        .background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: BubbleFrameKey.self,
                    value: [action: geo.frame(in: .global)]
                )
            }
        }
    }
}

private struct BubbleFrameKey: PreferenceKey {
    static var defaultValue: [CardAction: CGRect] = [:]

    static func reduce(value: inout [CardAction: CGRect], nextValue: () -> [CardAction: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
