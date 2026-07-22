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
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { @MainActor in
                TaskStore.shared.applyWidgetSnapshotIfNeeded()
                TaskStore.shared.syncWidgetSnapshot()
            }
        }
    }
}
