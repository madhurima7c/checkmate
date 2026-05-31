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
    static let progressRowHeight: CGFloat = 24
    /// Figma 664:3034 — 16pt frame gap + 20pt nav-row top padding.
    static let progressToNavSpacing: CGFloat = 36
    /// Figma 664:3034 — tab pill / add button are 56pt tall.
    static let navBarHeight: CGFloat = 56
    /// Figma 664:3034 — nav sits 40pt above the screen bottom; ~34pt is the
    /// home-indicator safe area, leaving ~6pt of explicit inset above it.
    static let navBottomInset: CGFloat = 6

    static var scrollBottomInset: CGFloat {
        progressRowHeight + progressToNavSpacing + navBarHeight + navBottomInset + 48
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
                        .frame(maxWidth: .infinity, minHeight: TodoListChromeMetrics.progressRowHeight)
                        .padding(.bottom, TodoListChromeMetrics.progressToNavSpacing)
                }
                HomeBottomBar(selectedTab: $selectedTab, onAdd: onAdd)
                    .frame(height: TodoListChromeMetrics.navBarHeight)
            }
            .padding(.bottom, TodoListChromeMetrics.navBottomInset)
        }
    }
}

private struct TodoScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Scroll container — cards fade at top and bottom under fixed chrome.
struct ScrollEdgeFades<Content: View>: View {
    var onScroll: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    @State private var lastOffset: CGFloat?

    var body: some View {
        ScrollView {
            content()
                .padding(.top, TodoListChromeMetrics.scrollContentTopPadding)
                .padding(.bottom, TodoListChromeMetrics.scrollBottomInset)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: TodoScrollOffsetKey.self,
                            value: geo.frame(in: .named("todoScroll")).minY
                        )
                    }
                )
        }
        .coordinateSpace(name: "todoScroll")
        .onPreferenceChange(TodoScrollOffsetKey.self) { offset in
            defer { lastOffset = offset }
            guard let lastOffset else { return }
            guard abs(offset - lastOffset) > 2 else { return }
            onScroll?()
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
