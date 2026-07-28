import SwiftUI

struct RootView: View {
    @StateObject private var auth = AuthService.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(CheckmateConfig.Onboarding.completedKey) private var onboardingCompleted = false

    var body: some View {
        ZStack {
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

            // Overlay (not a cover) so first launch can never drop the
            // presentation; clearing the flag from Settings re-shows it.
            if !onboardingCompleted {
                OnboardingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(Theme.spring, value: onboardingCompleted)
        .onAppear { ConfettiCelebration.shared.prewarm() }
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
