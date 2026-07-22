import SwiftUI

/// Figma 650:2514 — horizontal assignee row (Add → Myself → friends).
struct AssigneeCarousel: View {
    @Binding var assignee: TaskAssignee
    let people: [FriendLink]
    var onAdd: () -> Void
    var onInteract: (() -> Void)? = nil

    /// Figma 650:2517 / 650:2523 — avatar diameter.
    private let avatarSize: CGFloat = 53.739
    /// Figma 650:2522/2523 — 1.119pt white gap between avatar edge and blue ring inner edge.
    private let selectionGap: CGFloat = 1.119
    /// White halo diameter (avatar + gap on both sides).
    private var whiteRingDiameter: CGFloat { avatarSize + selectionGap * 2 }
    /// Figma 650:2522 — 2pt blue ring; matches the color selector ring weight.
    private let selectionStrokeWidth: CGFloat = 2
    /// Frame sized so `.stroke` centers on the white-ring outer edge, extending outward.
    private var selectionRingDiameter: CGFloat { whiteRingDiameter + selectionStrokeWidth }
    private var selectedOuterDiameter: CGFloat { selectionRingDiameter }
    /// Fixed slot so labels never shift between selected and unselected.
    private var slotSize: CGFloat { selectedOuterDiameter }
    /// Figma 650:2524 / 650:2518 — status badge.
    private let badgeSize: CGFloat = 15.674
    private var checkIconSize: CGFloat { badgeSize * (6.158 / 15.674) }
    /// Figma 650:2518 — badge on avatar rim (~4:30), not on the outer blue stroke.
    private var assigneeBadgeOffset: CGSize {
        CGSize(width: -1.119, height: 1.119)
    }
    private let itemWidth: CGFloat = 64
    private let labelHeight: CGFloat = 22.391
    private let labelGap: CGFloat = 6

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
            .frame(height: slotSize + labelHeight + labelGap + 12, alignment: .top)
        }
    }

    private var addItem: some View {
        Button {
            onInteract?()
            onAdd()
        } label: {
            VStack(spacing: labelGap) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.12), lineWidth: 1.12)
                        )
                    FigmaIcon(name: "AssignPlus", size: 21.608)
                }
                .frame(width: slotSize, height: slotSize)

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
            VStack(spacing: labelGap) {
                ZStack {
                    if selected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: whiteRingDiameter, height: whiteRingDiameter)
                        Circle()
                            .stroke(
                                Theme.Palette.selectionBlue,
                                style: StrokeStyle(lineWidth: selectionStrokeWidth, lineCap: .round)
                            )
                            .frame(width: selectionRingDiameter, height: selectionRingDiameter)
                    }

                    PersonAvatarView(
                        name: name,
                        imageData: imageData,
                        size: avatarSize,
                        showsBorder: false
                    )
                    .overlay(alignment: .bottomTrailing) {
                        AssigneeSelectionBadge(
                            selected: selected,
                            size: badgeSize,
                            checkSize: checkIconSize
                        )
                        .offset(assigneeBadgeOffset)
                    }
                }
                .frame(width: slotSize, height: slotSize)

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
    var size: CGFloat = 16
    var checkSize: CGFloat = 6.2

    var body: some View {
        ZStack {
            Circle()
                .fill(selected ? Theme.Palette.selectionBlue : .white)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(selected ? 0.06 : 0.12), lineWidth: 1.12)
                )
            if selected {
                FigmaIcon(name: "AssignCheck", size: checkSize)
            }
        }
        .frame(width: size, height: size)
    }
}
