import SwiftUI

// MARK: - Figma 571:10111 — edge fades + bottom chrome metrics

enum TodoListChromeMetrics {
    /// Gap from header row to first card row (~40pt per design).
    static let headerToGridSpacing: CGFloat = 40
    static let gridInnerTopPadding: CGFloat = 8
    static var scrollContentTopPadding: CGFloat {
        headerToGridSpacing - gridInnerTopPadding
    }

    /// Canvas wash height rising above bottom chrome.
    static let fadeHeight: CGFloat = 268
    static let topFadeHeight: CGFloat = 56
    static let progressRowHeight: CGFloat = 20
    static let progressToNavSpacing: CGFloat = 40
    static let navBarHeight: CGFloat = 52
    static let navBottomInset: CGFloat = 20

    static var scrollBottomInset: CGFloat {
        fadeHeight + progressRowHeight + progressToNavSpacing + navBarHeight + navBottomInset
    }
}

/// Figma 571:10111 — progressive canvas fade from the bottom.
struct TodoBottomFadeGradient: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Theme.Palette.canvas.opacity(0), location: 0),
                .init(color: Theme.Palette.canvas.opacity(0.35), location: 0.32),
                .init(color: Theme.Palette.canvas.opacity(0.72), location: 0.62),
                .init(color: Theme.Palette.canvas.opacity(0.94), location: 0.88),
                .init(color: Theme.Palette.canvas, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Header zone — 100% canvas at top, 0% at bottom so cards dissolve when scrolling up.
struct TodoTopFadeGradient: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Theme.Palette.canvas, location: 0),
                .init(color: Theme.Palette.canvas.opacity(0.55), location: 0.45),
                .init(color: Theme.Palette.canvas.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Bottom chrome: white fade, progress pill, then navigation (always above scrolling cards).
struct TodoListBottomChrome: View {
    let done: Int
    let total: Int
    @Binding var selectedTab: AppTab
    var onAdd: () -> Void

    private var showProgress: Bool { total > 0 }

    private var fadeStackHeight: CGFloat {
        var height = TodoListChromeMetrics.fadeHeight
        if showProgress {
            height += TodoListChromeMetrics.progressRowHeight + TodoListChromeMetrics.progressToNavSpacing
        }
        return height
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TodoBottomFadeGradient()
                .frame(height: fadeStackHeight)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                if showProgress {
                    ProgressPill(done: done, total: total)
                        .frame(maxWidth: .infinity)
                        .frame(height: TodoListChromeMetrics.progressRowHeight)
                        .padding(.bottom, TodoListChromeMetrics.progressToNavSpacing)
                }
                HomeBottomBar(selectedTab: $selectedTab, onAdd: onAdd)
                    .frame(height: TodoListChromeMetrics.navBarHeight)
            }
            .padding(.bottom, TodoListChromeMetrics.navBottomInset)
        }
    }
}

/// Scroll container — cards fade at top and bottom under fixed chrome.
struct ScrollEdgeFades<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            content()
                .padding(.top, TodoListChromeMetrics.scrollContentTopPadding)
                .padding(.bottom, TodoListChromeMetrics.scrollBottomInset)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) {
            TodoTopFadeGradient()
                .frame(height: TodoListChromeMetrics.topFadeHeight)
                .allowsHitTesting(false)
        }
        .mask {
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.85), location: 0.35),
                        .init(color: .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: TodoListChromeMetrics.topFadeHeight)

                Rectangle()
                    .fill(Color.black)

                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black.opacity(0.88), location: 0.45),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 88)
            }
        }
    }
}

/// Translucent footer behind the add-todo Confirm button (24pt vertical padding).
struct ConfirmButtonChrome<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.top, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    LinearGradient(
                        stops: [
                            .init(color: Theme.Palette.canvas.opacity(0), location: 0.007),
                            .init(color: Theme.Palette.canvas.opacity(0.55), location: 0.35),
                            .init(color: Theme.Palette.canvas, location: 0.99)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.35)
                }
                .allowsHitTesting(false)
            }
    }
}
