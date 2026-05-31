import SwiftUI

struct AssignFlightOverlay: View {
    @ObservedObject private var coordinator = AssignFlightCoordinator.shared

    var body: some View {
        if let flight = coordinator.activeFlight {
            GeometryReader { geo in
                let start = coordinator.startPoint(in: geo.size)
                let end = coordinator.endPoint(in: geo.size, destination: flight.destination)
                let landing = coordinator.landingSize(for: flight.destination)
                let p = coordinator.progress
                let position = CGPoint(
                    x: start.x + (end.x - start.x) * p,
                    y: start.y + (end.y - start.y) * p
                )
                let startSide: CGFloat = 172
                let endSide = max(landing.width, landing.height)
                let side = startSide + (endSide - startSide) * p
                let settle = 1 + 0.02 * (1 - abs(p - 0.92) / 0.92)

                FlyingStickyCard(color: flight.color, text: flight.text)
                    .frame(width: side, height: side)
                    .scaleEffect(settle)
                    .rotationEffect(.degrees(6 * (1 - p)))
                    .position(position)
                    .shadow(color: .black.opacity(0.1 * (1 - p * 0.5)), radius: 8, y: 4)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .zIndex(100)
        }
    }
}

/// Reports the global center + size of the first sticky slot in a tab grid.
struct GridLandingAnchor: View {
    let tab: AppTab

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { report(proxy) }
                .onChange(of: proxy.frame(in: .global)) { _, _ in report(proxy) }
        }
    }

    private func report(_ proxy: GeometryProxy) {
        let frame = proxy.frame(in: .global)
        guard frame.width > 8, frame.height > 8 else { return }
        let coordinator = AssignFlightCoordinator.shared
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let size = CGSize(width: frame.width, height: frame.height)
        switch tab {
        case .myTodo:
            coordinator.myTodoLandingCenter = center
            coordinator.myTodoLandingSize = size
        case .friends:
            coordinator.friendsLandingCenter = center
            coordinator.friendsLandingSize = size
        }
    }
}

extension View {
    func gridLandingMeasurement(tab: AppTab) -> some View {
        background { GridLandingAnchor(tab: tab) }
            .aspectRatio(1, contentMode: .fit)
            .opacity(0.001)
            .allowsHitTesting(false)
    }
}

struct FlyingStickyCard: View {
    let color: StickyColor
    let text: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
                .fill(color.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
                        .strokeBorder(.white, lineWidth: Theme.Stroke.cardBorder)
                )
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Palette.body)
                .lineLimit(4)
                .padding(14)
        }
        .stickyShadow()
    }
}
