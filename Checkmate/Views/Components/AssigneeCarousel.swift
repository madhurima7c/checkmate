import SwiftUI

/// Figma 650:2514 — horizontal assignee row (Add → Myself → friends).
struct AssigneeCarousel: View {
    @Binding var assignee: TaskAssignee
    let people: [FriendLink]
    var onAdd: () -> Void
    var onInteract: (() -> Void)? = nil

    /// Figma 650:2517 — inner avatar; 650:2522 — outer ring with white gap before blue stroke.
    private let avatarSize: CGFloat = 53.739
    /// White space between photo circle and blue ring (Figma ~1.12pt per side).
    private let selectionGap: CGFloat = 2.24
    /// Figma 650:2522 border 2.239pt; drawn outside the white halo via `.stroke`.
    private let selectionStrokeWidth: CGFloat = 3.5
    private var whiteHaloSize: CGFloat { avatarSize + selectionGap * 2 }
    private var selectedOuterSize: CGFloat { whiteHaloSize + selectionStrokeWidth * 2 }
    private let itemWidth: CGFloat = 64
    private let labelHeight: CGFloat = 22.391

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                addItem

                carouselItem(
                    title: "Myself",
                    imageData: nil,
                    name: "Myself",
                    selected: assignee.isMyself
                ) {
                    onInteract?()
                    withAnimation(Theme.snappy) { assignee = .myself }
                }

                ForEach(people) { link in
                    carouselItem(
                        title: link.chipLabel,
                        imageData: link.avatarData,
                        name: link.name,
                        selected: assignee.id == TaskAssignee.person(link).id
                    ) {
                        onInteract?()
                        withAnimation(Theme.snappy) { assignee = .person(link) }
                    }
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.vertical, 4)
            .frame(height: selectedOuterSize + labelHeight + 12, alignment: .top)
        }
    }

    private var addItem: some View {
        Button {
            onInteract?()
            onAdd()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.12), lineWidth: 1.12)
                        )
                    FigmaIcon(name: "AssignPlus", size: 21.608)
                }
                .frame(width: avatarSize, height: avatarSize)

                Text("Add")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Palette.body)
                    .lineLimit(1)
                    .frame(width: itemWidth, height: labelHeight)
            }
        }
        .buttonStyle(BoopButtonStyle())
    }

    private func carouselItem(
        title: String,
        imageData: Data?,
        name: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            onInteract?()
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if selected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: whiteHaloSize, height: whiteHaloSize)
                        Circle()
                            .stroke(Theme.Palette.selectionBlue, lineWidth: selectionStrokeWidth)
                            .frame(width: selectedOuterSize, height: selectedOuterSize)
                    }

                    PersonAvatarView(
                        name: name,
                        imageData: imageData,
                        size: avatarSize,
                        showsBorder: false
                    )
                    .overlay(alignment: .bottomTrailing) {
                        AssigneeSelectionBadge(selected: selected)
                            .offset(x: selected ? 2 : 0.2, y: selected ? 2 : 0.2)
                    }
                }
                .frame(
                    width: selected ? selectedOuterSize : avatarSize,
                    height: selected ? selectedOuterSize : avatarSize
                )

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Palette.assignLabelMuted)
                    .lineLimit(1)
                    .frame(width: itemWidth, height: labelHeight)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Figma 650:2518 / 650:2524 — circular badge; selected state includes the check glyph.
private struct AssigneeSelectionBadge: View {
    let selected: Bool

    private let size: CGFloat = 15.674

    var body: some View {
        ZStack {
            Circle()
                .fill(selected ? Theme.Palette.selectionBlue : .white)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(selected ? 0.06 : 0.12), lineWidth: 1.12)
                )
            if selected {
                FigmaIcon(name: "AssignCheck", size: 6.158)
            }
        }
        .frame(width: size, height: size)
    }
}
