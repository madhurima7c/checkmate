import SwiftUI

struct FriendsTabView: View {
    @StateObject private var store = TaskStore.shared
    @Binding var dayOffset: Int
    var namespace: Namespace.ID
    @ObservedObject var controller: CardFocusController
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
        .animation(Theme.snappy, value: dayOffset)
        .onChange(of: dayOffset) { _, _ in controller.clear() }
    }

    @ViewBuilder
    private func friendsDayPage(offset: Int) -> some View {
        let day = Date.today.adding(days: offset)
        let pending = store.friendsPending(on: day)
        let completed = store.friendsCompleted(on: day)
        let all = pending + completed

        if all.isEmpty {
            TodoEmptyDayPage(tab: .friends, showLandingAnchor: offset == 0)
        } else {
            ScrollEdgeFades(onScroll: {
                if controller.isActive { controller.clear() }
            }) {
                TodoTaskGrid(
                        pending: pending,
                        completed: completed,
                        tab: .friends,
                        isNew: { store.isNew($0) },
                        avatarName: friendsAvatarName,
                        avatarData: friendsAvatarData,
                        allowsEdit: { _ in true },
                        onEdit: onEdit,
                        onDelete: onDelete,
                        controller: controller
                    )
                .padding(.horizontal, 24)
            }
            .scrollDisabled(controller.isActive)
        }
    }

    private func friendsAvatarName(_ task: CheckmateTask) -> String? {
        task.assigneeName
    }

    private func friendsAvatarData(_ task: CheckmateTask) -> Data? {
        if let contact = task.inviteContact,
           let link = FriendsStore.shared.recent.first(where: { $0.contact == contact }) {
            return link.avatarData
        }
        if let receiverId = task.receiverId {
            return FriendsStore.shared.friendLink(forUserId: receiverId)?.avatarData
        }
        return nil
    }
}
