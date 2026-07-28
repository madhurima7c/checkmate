#if DEBUG
import SwiftUI

enum CheckmatePreviewFixtures {
    static let userID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    static let pending = task(
        id: "10000000-0000-0000-0000-000000000001",
        text: "Send portfolio notes to Ani",
        color: .yellow
    )

    static let done = task(
        id: "10000000-0000-0000-0000-000000000002",
        text: "Book the studio for Tuesday",
        status: .done,
        color: .blue
    )

    static let assigned = task(
        id: "10000000-0000-0000-0000-000000000003",
        text: "Review onboarding prototype",
        receiverID: friendID,
        color: .pink,
        assigneeName: "Ani"
    )

    static let friends = [
        FriendLink(name: "Ani", contact: "ani@example.com", profileId: friendID),
        FriendLink(name: "Sam", contact: "sam@example.com"),
        FriendLink(name: "Priya", contact: "priya@example.com")
    ]

    private static func task(
        id: String,
        text: String,
        receiverID: UUID? = nil,
        status: TaskStatus = .pending,
        color: StickyColor,
        assigneeName: String? = nil
    ) -> CheckmateTask {
        CheckmateTask(
            id: UUID(uuidString: id)!,
            text: text,
            senderId: userID,
            receiverId: receiverID,
            dueDate: .today,
            status: status,
            isSeen: true,
            color: color,
            allDay: true,
            dueAt: nil,
            createdAt: .today,
            assigneeName: assigneeName,
            inviteContact: nil,
            widgetAvatarName: nil,
            widgetAvatarImageData: nil
        )
    }
}

struct CatalogSurface<Content: View>: View {
    var padding: CGFloat = 24
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.canvas)
    }
}

struct PaletteCatalog: View {
    private let colors: [(String, Color)] = [
        ("canvas", Theme.Palette.canvas),
        ("ink", Theme.Palette.ink),
        ("body", Theme.Palette.body),
        ("subtitle", Theme.Palette.subtitle),
        ("dim", Theme.Palette.dim),
        ("strike", Theme.Palette.strike),
        ("checkboxStroke", Theme.Palette.checkboxStroke),
        ("blue", Theme.Palette.blue),
        ("selectionBlue", Theme.Palette.selectionBlue),
        ("selectionFill", Theme.Palette.selectionFill),
        ("assignLabelMuted", Theme.Palette.assignLabelMuted),
        ("newRed", Theme.Palette.newRed),
        ("dark", Theme.Palette.dark),
        ("surface", Theme.Palette.surface),
        ("chipBorder", Theme.Palette.chipBorder)
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.fixed(96)), GridItem(.fixed(96)), GridItem(.fixed(96))], spacing: 16) {
            ForEach(colors, id: \.0) { name, color in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(color)
                        .frame(width: 96, height: 72)
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.card)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        }
                    Text(name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Palette.body)
                        .lineLimit(1)
                    }
            }
        }
        .padding(24)
        .background(Theme.Palette.canvas)
    }
}

struct StickyColorCatalog: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(StickyColor.allCases) { color in
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(color.paper)
                        .frame(width: 72, height: 72)
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(color.dot)
                                .frame(width: 24, height: 24)
                                .padding(8)
                        }
                    Text(color.rawValue)
                        .font(.system(size: 13, weight: .medium))
                }
            }
        }
    }
}

struct RadiusAndStrokeCatalog: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            LazyVGrid(columns: [GridItem(.fixed(112)), GridItem(.fixed(112))], spacing: 16) {
                sample("card", radius: Theme.Radius.card)
                sample("cardLarge", radius: Theme.Radius.cardLarge)
                sample("pill", radius: Theme.Radius.pill)
                sample("chip", radius: Theme.Radius.chip)
                sample("panel", radius: Theme.Radius.panel)
            }
            HStack(spacing: 28) {
                stroke("cardBorder", width: Theme.Stroke.cardBorder)
                stroke("cardBorderLarge", width: Theme.Stroke.cardBorderLarge)
                stroke("progressRing", width: Theme.Stroke.progressRing)
            }
        }
    }

    private func sample(_ name: String, radius: CGFloat) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(StickyColor.yellow.paper)
                .frame(width: 96, height: 72)
            Text("\(name) · \(radius.formatted())")
                .font(.caption)
        }
    }

    private func stroke(_ name: String, width: CGFloat) -> some View {
        VStack(spacing: 8) {
            Circle()
                .stroke(Theme.Palette.selectionBlue, lineWidth: width)
                .frame(width: 48, height: 48)
            Text("\(name) · \(width.formatted())")
                .font(.caption)
        }
    }
}

#Preview("Foundations / Palette", traits: .sizeThatFitsLayout) {
    CatalogSurface {
        PaletteCatalog()
    }
}

#Preview("Foundations / Sticky colors", traits: .sizeThatFitsLayout) {
    CatalogSurface {
        StickyColorCatalog()
    }
}

#Preview("Foundations / Radius and stroke", traits: .sizeThatFitsLayout) {
    CatalogSurface {
        RadiusAndStrokeCatalog()
    }
}

#Preview("Components / Sticky card / Pending", traits: .fixedLayout(width: 220, height: 220)) {
    CatalogSurface {
        StickyNoteCardView(task: CheckmatePreviewFixtures.pending)
    }
}

#Preview("Components / Sticky card / Done", traits: .fixedLayout(width: 220, height: 220)) {
    CatalogSurface {
        StickyNoteCardView(task: CheckmatePreviewFixtures.done)
    }
}

#Preview("Components / Sticky card / Assigned new", traits: .fixedLayout(width: 220, height: 220)) {
    CatalogSurface {
        StickyNoteCardView(
            task: CheckmatePreviewFixtures.assigned,
            isNewBadge: true,
            avatarName: "Ani"
        )
    }
}

#Preview("Components / Progress / Empty", traits: .fixedLayout(width: 320, height: 100)) {
    CatalogSurface {
        ProgressPill(done: 0, total: 0)
    }
}

#Preview("Components / Progress / Partial", traits: .fixedLayout(width: 320, height: 100)) {
    CatalogSurface {
        ProgressPill(done: 2, total: 5)
    }
}

#Preview("Components / Progress / Complete", traits: .fixedLayout(width: 320, height: 100)) {
    CatalogSurface {
        ProgressPill(done: 5, total: 5)
    }
}

#Preview("Components / Avatar / Initials", traits: .sizeThatFitsLayout) {
    CatalogSurface {
        HStack(spacing: 20) {
            PersonAvatarView(name: "Ani", size: 24)
            PersonAvatarView(name: "Madhurima Das", size: 40)
            PersonAvatarView(name: "Sam", size: 54, showsBorder: false)
        }
    }
}

#Preview("Components / Assignee carousel / Myself", traits: .fixedLayout(width: 402, height: 130)) {
    @Previewable @State var assignee = TaskAssignee.myself
    CatalogSurface(padding: 0) {
        AssigneeCarousel(
            assignee: $assignee,
            people: CheckmatePreviewFixtures.friends,
            onAdd: {}
        )
    }
}

#Preview("Components / Action bubbles / Resting", traits: .fixedLayout(width: 180, height: 150)) {
    CatalogSurface {
        CardActionBubbles(allowsEdit: true)
    }
    .coordinateSpace(name: CardFocusSpace.name)
}

#Preview("Components / Action bubbles / Delete", traits: .fixedLayout(width: 180, height: 150)) {
    CatalogSurface {
        CardActionBubbles(allowsEdit: true, highlighted: .delete)
    }
    .coordinateSpace(name: CardFocusSpace.name)
}

#Preview("Components / Action bubbles / Edit", traits: .fixedLayout(width: 180, height: 150)) {
    CatalogSurface {
        CardActionBubbles(allowsEdit: true, highlighted: .edit)
    }
    .coordinateSpace(name: CardFocusSpace.name)
}

#Preview("Components / Bottom bar / My todo", traits: .fixedLayout(width: 402, height: 120)) {
    @Previewable @State var selectedTab = AppTab.myTodo
    CatalogSurface(padding: 0) {
        HomeBottomBar(selectedTab: $selectedTab, onAdd: {})
    }
}

#Preview("Components / Switch / States", traits: .sizeThatFitsLayout) {
    @Previewable @State var enabled = true
    @Previewable @State var disabled = false
    CatalogSurface {
        HStack(spacing: 24) {
            FigmaSwitch(isOn: $enabled)
            FigmaSwitch(isOn: $disabled)
        }
    }
}

#Preview("Components / Empty state", traits: .fixedLayout(width: 402, height: 620)) {
    EmptyStateView()
        .background(Theme.Palette.canvas)
}

#Preview("Components / Check confetti", traits: .fixedLayout(width: 220, height: 180)) {
    CatalogSurface {
        CheckConfettiView(speed: 1.5)
            .frame(width: 200, height: 200 / CheckConfettiView.aspectRatio)
    }
}

#Preview("Components / Icons", traits: .sizeThatFitsLayout) {
    CatalogSurface {
        HStack(spacing: 24) {
            FigmaIcon.gear()
            FigmaIcon.noteTab()
            FigmaIcon.friendsTab()
            FigmaIcon.addFAB()
            FigmaIcon.actionPencil()
            FigmaIcon.actionTrash()
        }
    }
}

#Preview("Components / Boop button", traits: .sizeThatFitsLayout) {
    CatalogSurface {
        Button("Add todo") {}
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .frame(height: 56)
            .background(Theme.Palette.dark, in: RoundedRectangle(cornerRadius: Theme.Radius.pill))
            .buttonStyle(BoopButtonStyle())
    }
}
#endif
