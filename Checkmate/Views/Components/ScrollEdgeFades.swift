import SwiftUI

/// Full-width edge fades for scroll content — top + bottom anchored to screen chrome.
struct ScrollEdgeFades<Content: View>: View {
    let done: Int
    let total: Int
    let bottomInset: CGFloat
    @ViewBuilder var content: () -> Content

    private var showProgress: Bool { total > 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            content()

            // Top fade — cards dissolve when scrolling up
            VStack {
                LinearGradient(
                    stops: [
                        .init(color: Theme.Palette.canvas, location: 0),
                        .init(color: Theme.Palette.canvas.opacity(0.85), location: 0.35),
                        .init(color: Theme.Palette.canvas.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)
                Spacer()
            }
            .allowsHitTesting(false)

            // Bottom fade — continuous wash down to tab bar
            VStack(spacing: 0) {
                Spacer()
                if showProgress {
                    LinearGradient(
                        stops: [
                            .init(color: Theme.Palette.canvas.opacity(0), location: 0),
                            .init(color: Theme.Palette.canvas.opacity(0.55), location: 0.45),
                            .init(color: Theme.Palette.canvas, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)

                    ProgressPill(done: done, total: total)
                        .padding(.bottom, 10)
                }

                LinearGradient(
                    colors: [Theme.Palette.canvas.opacity(0), Theme.Palette.canvas],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: bottomInset)
            }
            .allowsHitTesting(false)
        }
    }
}

/// White fade behind the add-todo confirm button (Figma).
struct ConfirmButtonChrome<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: Theme.Palette.canvas.opacity(0), location: 0),
                    .init(color: Theme.Palette.canvas.opacity(0.92), location: 0.35),
                    .init(color: Theme.Palette.canvas, location: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)

            content()
        }
    }
}
