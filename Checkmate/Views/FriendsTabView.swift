import SwiftUI

struct FriendsTabView: View {
    @StateObject private var store = TaskStore.shared
    @Binding var dayOffset: Int
    var namespace: Namespace.ID
    var onEdit: (CheckmateTask) -> Void
    var onDelete: (CheckmateTask) -> Void

    private let dayRange = 0...14

    var body: some View {
        TabView(selection: $dayOffset) {
            ForEach(Array(dayRange), id: \.self) { offset in
                friendsDayPage(offset: offset)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    @ViewBuilder
    private func friendsDayPage(offset: Int) -> some View {
        let day = Date.today.adding(days: offset)
        let pending = store.friendsPending(on: day)
        let completed = store.friendsCompleted(on: day)
        let all = pending + completed

        if all.isEmpty {
            ScrollView {
                Color.clear
                    .gridLandingMeasurement(tab: .friends)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity)
                friendsEmptyState
                    .frame(minHeight: 400)
            }
            .scrollIndicators(.hidden)
        } else {
            let progress = store.progress(on: day, tab: .friends)
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                    spacing: 10
                ) {
                    if pending.isEmpty {
                        Color.clear
                            .gridLandingMeasurement(tab: .friends)
                    }
                    ForEach(Array(pending.enumerated()), id: \.element.id) { index, task in
                        StickyNoteCardView(
                            task: task,
                            isNewBadge: store.isNew(task),
                            namespace: namespace,
                            onEdit: { onEdit(task) },
                            onDelete: { onDelete(task) }
                        )
                        .background {
                            if index == 0 {
                                GridLandingAnchor(tab: .friends)
                            }
                        }
                    }
                    ForEach(completed) { task in
                        StickyNoteCardView(
                            task: task,
                            namespace: namespace,
                            onEdit: { onEdit(task) },
                            onDelete: { onDelete(task) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)
            .overlay(alignment: .bottom) {
                if progress.total > 0 {
                    VStack(spacing: 6) {
                        LinearGradient(
                            colors: [Theme.Palette.canvas.opacity(0), Theme.Palette.canvas],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 56)
                        ProgressPill(done: progress.done, total: progress.total)
                    }
                    .allowsHitTesting(false)
                    .padding(.bottom, 88)
                }
            }
        }
    }

    private var friendsEmptyState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 80)
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Palette.dim)
            Text("No tasks for friends yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
            Text("Assign a todo to someone and it will land here.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Palette.dim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer(minLength: 120)
        }
    }
}
