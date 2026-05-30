import SwiftUI

/// Figma 573:2469 / 650:2514 — horizontal assignee row (Add → Myself → friends).
struct AssigneeCarousel: View {
    @Binding var assignee: TaskAssignee
    let people: [FriendLink]
    var onAdd: () -> Void
    var onInteract: (() -> Void)? = nil

    private let avatarSize: CGFloat = 48
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
            .padding(.horizontal, 20)
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
                        .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 0)
                    FigmaIcon(name: "AssignAdd", size: 20)
                }
                Text("Add")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Palette.body)
                    .lineLimit(1)
            }
            .frame(width: itemWidth)
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
            VStack(spacing: selected ? 2 : 4) {
                ZStack(alignment: .bottomTrailing) {
                    if selected {
                        Circle()
                            .strokeBorder(Theme.Palette.selectionBlue, lineWidth: 1.5)
                            .frame(width: 50, height: 50)
                            .overlay {
                                PersonAvatarView(name: name, imageData: imageData, size: avatarSize)
                            }
                    } else {
                        PersonAvatarView(name: name, imageData: imageData, size: avatarSize)
                    }

                    ZStack {
                        Circle()
                            .fill(selected ? Theme.Palette.selectionBlue : .white)
                            .frame(width: 14, height: 14)
                            .shadow(color: .black.opacity(selected ? 0.06 : 0.12), radius: 0, x: 0, y: 0)
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .offset(x: selected ? 2 : -1, y: selected ? 2 : -1)
                }
                .frame(width: 50, height: 50)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(selected ? Theme.Palette.assignLabelMuted : Theme.Palette.body)
                    .lineLimit(1)
                    .frame(width: itemWidth)
            }
        }
        .buttonStyle(.plain)
    }
}
