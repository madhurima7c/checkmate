import SwiftUI

/// Full empty state (illustration + copy + arrow) for a day with no todos.
struct TodoEmptyDayPage: View {
    var tab: AppTab
    var showLandingAnchor: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            EmptyStateView()
            if showLandingAnchor {
                Color.clear
                    .gridLandingMeasurement(tab: tab)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
