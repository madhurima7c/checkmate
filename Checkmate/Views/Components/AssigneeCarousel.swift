import SwiftUI

/// Figma 650:2514 — horizontal assignee row (Add → Myself → friends).
struct AssigneeCarousel: View {
    @Binding var assignee: TaskAssignee
    let people: [FriendLink]
    var onAdd: () -> Void
    var onInteract: (() -> Void)? = nil

    /// Figma 650:2517 — inner avatar; 650:2522 — outer ring with white gap before blue stroke.
    private let avatarSize: CGFloat = 53.739
    /// White gap between avatar and blue ring (reference shows more air than inset math alone).
    private let selectionGap: CGFloat = 3.5
    /// Figma 650:2522 — 2.239pt #08f stroke (thinner than prior 3.5pt build).
    private let selectionStrokeWidth: CGFloat = 2.239
    private let figmaFrameSize: CGFloat = 55.978
    private var whiteHaloSize: CGFloat { avatarSize + selectionGap * 2 }
    private var selectedOuterSize: CGFloat { whiteHaloSize + selectionStrokeWidth * 2 }
    /// Fixed avatar slot so labels never shift between selected and unselected.
    private var slotSize: CGFloat { selectedOuterSize }
    /// Figma 650:2524 — 15.674pt; slightly larger for legibility.
    private let badgeSize: CGFloat = 17
    private var checkIconSize: CGFloat { badgeSize * (6.158 / 15.674) }
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
                }
                .frame(width: slotSize, height: slotSize)
                .overlay(alignment: .center) {
                    AssigneeSelectionBadge(
                        selected: selected,
                        size: badgeSize,
                        checkSize: checkIconSize
                    )
                    .offset(badgeOffset)
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Palette.assignLabelMuted)
                    .lineLimit(1)
                    .frame(width: itemWidth, height: labelHeight)
            }
        }
        .buttonStyle(.plain)
    }

    /// Figma 650:2524 — badge center ~(47, 49) on 55.978 frame (4:30 on ring).
    private var badgeOffset: CGSize {
        let scale = slotSize / figmaFrameSize
        let frameCenter = figmaFrameSize / 2
        let badgeCenterX: CGFloat = 47.02
        let badgeCenterY: CGFloat = 49.25
        return CGSize(
            width: (badgeCenterX - frameCenter) * scale,
            height: (badgeCenterY - frameCenter) * scale
        )
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
