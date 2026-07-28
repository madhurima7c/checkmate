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
    @ObservedObject var controller: CardFocusController
    @Environment(\.homePageTuning) private var tuning

    private var columns: [GridItem] {
        let spacing = CGFloat(tuning.gridSpacing)
        return [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: CGFloat(tuning.gridSpacing)) {
            ForEach(Array(pending.enumerated()), id: \.element.id) { index, task in
                gridCell(
                    task: task,
                    showLanding: index == 0,
                    isRightColumn: index % 2 == 1
                )
            }
            ForEach(Array(completed.enumerated()), id: \.element.id) { index, task in
                let globalIndex = pending.count + index
                gridCell(
                    task: task,
                    showLanding: pending.isEmpty && index == 0,
                    isRightColumn: globalIndex % 2 == 1
                )
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func gridCell(task: CheckmateTask, showLanding: Bool, isRightColumn: Bool) -> some View {
        StickyNoteGridCell(
            task: task,
            isNewBadge: isNew(task),
            avatarName: avatarName(task),
            avatarImageData: avatarData(task),
            allowsEdit: allowsEdit(task),
            isRightColumn: isRightColumn,
            onEdit: { onEdit(task) },
            onDelete: { onDelete(task) },
            controller: controller
        )
        .background {
            if showLanding {
                GridLandingAnchor(tab: tab)
            }
        }
    }
}
