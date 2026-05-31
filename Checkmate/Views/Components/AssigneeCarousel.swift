import SwiftUI

/// Figma 650:2514 — horizontal assignee row (Add → Myself → friends).
struct AssigneeCarousel: View {
    @Binding var assignee: TaskAssignee
    let people: [FriendLink]
    var onAdd: () -> Void
    var onInteract: (() -> Void)? = nil

    private let avatarSize: CGFloat = 48
    private let ringSize: CGFloat = 54
    private let itemWidth: CGFloat = 48

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
            .frame(height: ringSize + 24, alignment: .top)
        }
        .task {
            await FriendsStore.shared.refreshContactPhotos()
        }
    }

    private var addItem: some View {
        Button {
            onInteract?()
            onAdd()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                        )
                    FigmaIcon(name: "AssignAdd", size: 19.3)
                }
                .frame(width: ringSize, height: ringSize)

                Text("Add")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Palette.body)
                    .lineLimit(1)
                    .frame(width: itemWidth)
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
            VStack(spacing: 4) {
                ZStack {
                    PersonAvatarView(
                        name: name,
                        imageData: imageData,
                        size: avatarSize,
                        showsBorder: false
                    )
                    .overlay(
                        Circle().strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        AssigneeSelectionBadge(selected: selected)
                            .offset(x: 1, y: 1)
                    }

                    if selected {
                        Circle()
                            .strokeBorder(Theme.Palette.selectionBlue, lineWidth: 2)
                            .frame(width: ringSize, height: ringSize)
                    }
                }
                .frame(width: ringSize, height: ringSize)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Palette.assignLabelMuted)
                    .lineLimit(1)
                    .frame(width: itemWidth)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Figma 650:2518 / 650:2524 — 14pt badge: blue check when selected, empty white dot otherwise.
private struct AssigneeSelectionBadge: View {
    let selected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(selected ? Theme.Palette.selectionBlue : .white)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle().strokeBorder(Color.black.opacity(selected ? 0.06 : 0.12), lineWidth: 1)
                )
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}
