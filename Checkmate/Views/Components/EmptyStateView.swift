import SwiftUI

/// Figma iPhone 16 & 17 Pro - 26 (571:10167) — empty My todo.
struct EmptyStateView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: max(24, geo.size.height * 0.22))
                    ZStack {
                        FigmaEmptyIllustration()
                            .frame(width: 340, height: 175)

                        // 571:10193 — progressive white fade over stickies
                        VStack {
                            Spacer()
                            LinearGradient(
                                stops: [
                                    .init(color: Color(hex: 0xFAFAFA).opacity(0), location: 0),
                                    .init(color: Theme.Palette.canvas, location: 0.58654)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 165)
                        }
                        .frame(width: geo.size.width, height: 175)
                        .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity)

                    Text("Nothing here yet")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.Palette.ink)
                        .padding(.top, 6)

                    Text("Click to add a todo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Palette.dim)
                        .multilineTextAlignment(.center)
                        .frame(width: 164)
                        .padding(.top, 8)

                    Spacer(minLength: 0)
                }

                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateArrowOverlay: View {
    var body: some View {
        GeometryReader { geo in
            EmptyStateArrow()
                .stroke(Color(hex: 0xD5D5D5), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 70, height: 118)
                .rotationEffect(.degrees(1.82))
                .position(
                    x: geo.size.width * 0.57,
                    y: geo.size.height - 150
                )
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Decorative stickies (exact Figma layout 571:10171)

struct FigmaEmptyIllustration: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Back — blue, no rotation (571:10485)
            emptyStickyCard(
                color: .blue,
                rotation: 0,
                position: CGPoint(x: 170, y: 67),
                z: 0
            ) {
                EmptyView()
            } checkbox: {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.Palette.checkboxStroke, lineWidth: 1.5)
                    .frame(width: 15, height: 15)
                    .padding(14)
            }

            // Left — yellow, done + avatar (571:10177)
            emptyStickyCard(
                color: .yellow,
                rotation: -10.15,
                position: CGPoint(x: 78, y: 90),
                z: 1
            ) {
                EmptyView()
            } checkbox: {
                Image("CheckboxDone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .padding(14)
            }

            // Right — pink (571:10184)
            emptyStickyCard(
                color: .pink,
                rotation: 15.09,
                position: CGPoint(x: 253, y: 88),
                z: 2
            ) {
                EmptyView()
            } checkbox: {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.Palette.checkboxStroke, lineWidth: 1.5)
                    .frame(width: 15, height: 15)
                    .padding(14)
            }
        }
        .frame(width: 340, height: 175)
    }

    private func emptyStickyCard<Content: View, Checkbox: View>(
        color: StickyColor,
        rotation: Double,
        position: CGPoint,
        z: Double,
        @ViewBuilder content: () -> Content,
        @ViewBuilder checkbox: () -> Checkbox
    ) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18.2, style: .continuous)
                .fill(color.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 18.2, style: .continuous)
                        .strokeBorder(.white, lineWidth: 4.5)
                )
                .frame(width: 131, height: 134)
                .emptyStickyShadow()

            checkbox()
            content()
        }
        .zIndex(z)
        .rotationEffect(.degrees(rotation))
        .position(position)
    }
}

extension View {
    /// Figma empty-state card shadow (571:10178).
    fileprivate func emptyStickyShadow() -> some View {
        shadow(color: .black.opacity(0.03), radius: 3.4, x: 1.5, y: -5.3)
            .shadow(color: .black.opacity(0.03), radius: 1.4, x: 0, y: 1.5)
            .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 0)
    }
}

struct EmptyStateArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sx = rect.width / 117.43
        let sy = rect.height / 219.438
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * sx, y: y * sy)
        }

        path.move(to: p(1.0, 9.55))
        path.addCurve(to: p(16.12, 85.12), control1: p(2.43, 21.87), control2: p(6.66, 47.88))
        path.addCurve(to: p(42.80, 138.14), control1: p(23.48, 103.63), control2: p(35.34, 126.30))
        path.addCurve(to: p(86.85, 188.16), control1: p(57.29, 158.73), control2: p(72.71, 175.33))
        path.addCurve(to: p(115.19, 209.88), control1: p(101.54, 200.35), control2: p(109.69, 206.60))

        path.move(to: p(116.43, 210.87))
        path.addLine(to: p(109.93, 210.85))
        path.move(to: p(116.43, 210.87))
        path.addCurve(to: p(112.84, 203.0), control1: p(114.79, 207.43), control2: p(113.74, 205.18))
        return path
    }
}
