import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if CheckmateConfig.isPrototype {
                MyTodoView()
            } else if auth.isAuthenticated {
                MyTodoView()
            } else {
                AuthView()
            }
        }
        .animation(Theme.spring, value: auth.isAuthenticated)
        .task(id: auth.isAuthenticated) {
            if auth.isAuthenticated {
                await TaskStore.shared.fetchTasks()
                if CheckmateConfig.pushEnabled {
                    await NotificationService.shared.requestPermission()
                }
            }
        }
        .onAppear {
            TaskStore.shared.applyWidgetSnapshotIfNeeded()
            TaskStore.shared.syncWidgetSnapshot()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                TaskStore.shared.applyWidgetSnapshotIfNeeded()
                TaskStore.shared.syncWidgetSnapshot()
            }
        }
    }
}
