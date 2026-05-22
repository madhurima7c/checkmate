import SwiftUI

/// Animates a sticky from the add flow into the first grid slot on My todo or Friends.
@MainActor
final class AssignFlightCoordinator: ObservableObject {
    static let shared = AssignFlightCoordinator()

    struct Flight: Identifiable {
        let id = UUID()
        let color: StickyColor
        let text: String
        let destination: AppTab
    }

    @Published private(set) var activeFlight: Flight?
    @Published var progress: CGFloat = 0
    @Published var myTodoLandingCenter: CGPoint = .zero
    @Published var myTodoLandingSize: CGSize = CGSize(width: 165, height: 165)
    @Published var friendsLandingCenter: CGPoint = .zero
    @Published var friendsLandingSize: CGSize = CGSize(width: 165, height: 165)

    private var onLand: (() -> Void)?
    private var landingRefreshGeneration = 0

    private init() {}

    func run(
        color: StickyColor,
        text: String,
        destination: AppTab,
        switchTab: @escaping (AppTab) -> Void,
        onLand: @escaping () -> Void
    ) {
        self.onLand = onLand
        progress = 0
        activeFlight = nil

        withAnimation(Theme.snappy) { switchTab(destination) }

        landingRefreshGeneration += 1
        let generation = landingRefreshGeneration

        Task { @MainActor in
            // Let the destination tab layout so the grid anchor can report its frame.
            try? await Task.sleep(for: .milliseconds(48))
            guard generation == landingRefreshGeneration else { return }

            activeFlight = Flight(color: color, text: text, destination: destination)

            withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                progress = 1
            }

            try? await Task.sleep(for: .milliseconds(400))
            guard generation == landingRefreshGeneration else { return }

            onLand()
            self.onLand = nil
            withAnimation(Theme.instant) {
                activeFlight = nil
                progress = 0
            }
        }
    }

    func cancelFlight() {
        landingRefreshGeneration += 1
        activeFlight = nil
        progress = 0
        onLand = nil
    }

    func endPoint(in size: CGSize, destination: AppTab) -> CGPoint {
        switch destination {
        case .friends:
            if friendsLandingCenter != .zero { return friendsLandingCenter }
            return CGPoint(x: size.width * 0.27, y: 200)
        case .myTodo:
            if myTodoLandingCenter != .zero { return myTodoLandingCenter }
            return CGPoint(x: size.width * 0.27, y: 200)
        }
    }

    func landingSize(for destination: AppTab) -> CGSize {
        switch destination {
        case .friends:
            friendsLandingSize.width > 8 ? friendsLandingSize : CGSize(width: 165, height: 165)
        case .myTodo:
            myTodoLandingSize.width > 8 ? myTodoLandingSize : CGSize(width: 165, height: 165)
        }
    }

    func startPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height * 0.36)
    }
}
