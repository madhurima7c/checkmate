import SwiftUI

/// Two-column sticky grid with overflow-friendly clipping and stable single-card layout.
struct TodoTaskGrid: View {
    let pending: [CheckmateTask]
    let completed: [CheckmateTask]
    let tab: AppTab
    var isNew: (CheckmateTask) -> Bool
    var avatarName: (CheckmateTask) -> String?
    var avatarData: (CheckmateTask) -> Data?
    var allowsEdit: (CheckmateTask) -> Bool
    var onEdit: (CheckmateTask) -> Void
    var onDelete: (CheckmateTask) -> Void
    @Binding var focusedCardId: UUID?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(pending.enumerated()), id: \.element.id) { index, task in
                gridCell(task: task, showLanding: index == 0)
            }
            ForEach(Array(completed.enumerated()), id: \.element.id) { index, task in
                gridCell(
                    task: task,
                    showLanding: pending.isEmpty && index == 0
                )
            }
        }
        .padding(.top, 8)
        .animation(.easeOut(duration: 0.14), value: focusedCardId)
    }

    @ViewBuilder
    private func gridCell(task: CheckmateTask, showLanding: Bool) -> some View {
        let actionEdge: StickyNoteGridCell.ActionEdge = columnIndex(for: task) == 0 ? .trailing : .leading

        StickyNoteGridCell(
            task: task,
            isNewBadge: isNew(task),
            avatarName: avatarName(task),
            avatarImageData: avatarData(task),
            allowsEdit: allowsEdit(task),
            actionEdge: actionEdge,
            onEdit: { onEdit(task) },
            onDelete: { onDelete(task) },
            focusedTaskId: $focusedCardId
        )
        .background {
            if showLanding {
                GridLandingAnchor(tab: tab)
            }
        }
        .zIndex(focusedCardId == task.id ? 3 : 1)
    }

    private func columnIndex(for task: CheckmateTask) -> Int {
        let orderedTasks = pending + completed
        guard let index = orderedTasks.firstIndex(where: { $0.id == task.id }) else {
            return 0
        }
        return index % 2
    }
}
