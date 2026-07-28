import SwiftUI

/// Figma 571:10465 — confetti bursts from behind the checkbox; each dot/star has its
/// own spring timing so the motion feels organic rather than mechanical.
struct CheckBurstView: View {
    @Environment(\.homePageTuning) private var tuning

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / Self.viewBox.width
            let scaleY = geo.size.height / Self.viewBox.height
            let origin = CGPoint(x: Self.origin.x * scaleX, y: Self.origin.y * scaleY)

            ZStack {
                ForEach(Self.pieces) { piece in
                    BurstParticleView(
                        piece: piece,
                        origin: origin,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        spread: tuning.burstSpread,
                        responseMultiplier: tuning.burstResponseMultiplier,
                        dampingOffset: tuning.burstDampingOffset
                    )
                }
            }
        }
        .aspectRatio(Self.viewBox.width / Self.viewBox.height, contentMode: .fit)
    }

    private static let viewBox = CGSize(width: 40, height: 32.0089)
    /// Checkbox center in burst asset coordinates (aligned with card checkbox).
    private static let origin = CGPoint(x: 11.5, y: 11.5)

    private static let burstBlue = Color(hex: 0x0088FF)
    private static let burstMid = Color(hex: 0x96CEFF)
    private static let burstPale = Color(hex: 0xC5E4FF)
}

// MARK: - Single particle

private struct BurstParticleView: View {
    let piece: BurstPiece
    let origin: CGPoint
    let scaleX: CGFloat
    let scaleY: CGFloat
    let spread: Double
    let responseMultiplier: Double
    let dampingOffset: Double

    @State private var progress: CGFloat = 0

    private var target: CGPoint {
        let original = CGPoint(x: piece.center.x * scaleX, y: piece.center.y * scaleY)
        let spreadScale = CGFloat(spread)
        return CGPoint(
            x: origin.x + (original.x - origin.x) * spreadScale,
            y: origin.y + (original.y - origin.y) * spreadScale
        )
    }

    private var position: CGPoint {
        CGPoint(
            x: origin.x + (target.x - origin.x) * progress,
            y: origin.y + (target.y - origin.y) * progress
        )
    }

    private var visualScale: CGFloat {
        let eased = progress
        let overshoot = progress > 0.85 ? sin((progress - 0.85) / 0.15 * .pi) * 0.12 : 0
        return max(0.001, eased * (1 + overshoot))
    }

    private var diameter: CGFloat {
        piece.radius * 2 * max(scaleX, scaleY) * visualScale
    }

    var body: some View {
        Group {
            if piece.isStar {
                BurstStar()
                    .fill(piece.color)
                    .frame(width: diameter, height: diameter)
            } else {
                Circle()
                    .fill(piece.color)
                    .frame(width: diameter, height: diameter)
            }
        }
        .position(position)
        .opacity(Double(min(1, progress * 1.35)))
        .onAppear { playBurst() }
    }

    private func playBurst() {
        progress = 0
        withAnimation(
            .spring(
                response: piece.response * responseMultiplier,
                dampingFraction: min(1, max(0.1, piece.damping + dampingOffset))
            )
            .delay(piece.delay)
        ) {
            progress = 1
        }
    }
}

private struct BurstPiece: Identifiable {
    let id: Int
    let center: CGPoint
    let radius: CGFloat
    let color: Color
    let isStar: Bool
    let delay: Double
    let response: Double
    let damping: Double
}

private extension CheckBurstView {
    static let pieces: [BurstPiece] = [
        BurstPiece(id: 0, center: CGPoint(x: 2.35, y: 12.94), radius: 2.35, color: burstPale, isStar: false, delay: 0.00, response: 0.38, damping: 0.68),
        BurstPiece(id: 1, center: CGPoint(x: 5.88, y: 1.18), radius: 1.18, color: burstPale, isStar: false, delay: 0.04, response: 0.28, damping: 0.74),
        BurstPiece(id: 2, center: CGPoint(x: 6.01, y: 6.01), radius: 1.76, color: burstBlue, isStar: false, delay: 0.07, response: 0.32, damping: 0.62),
        BurstPiece(id: 3, center: CGPoint(x: 4.70, y: 17.64), radius: 1.76, color: burstMid, isStar: false, delay: 0.02, response: 0.36, damping: 0.70),
        BurstPiece(id: 4, center: CGPoint(x: 9.29, y: 3.71), radius: 1.18, color: burstBlue, isStar: false, delay: 0.10, response: 0.26, damping: 0.76),
        BurstPiece(id: 5, center: CGPoint(x: 5.91, y: 24.73), radius: 0.90, color: burstPale, isStar: false, delay: 0.14, response: 0.34, damping: 0.66),
        BurstPiece(id: 6, center: CGPoint(x: 34.71, y: 5.29), radius: 1.76, color: burstBlue, isStar: false, delay: 0.06, response: 0.30, damping: 0.58),
        BurstPiece(id: 7, center: CGPoint(x: 38.82, y: 5.88), radius: 1.18, color: burstBlue, isStar: false, delay: 0.11, response: 0.24, damping: 0.72),
        BurstPiece(id: 8, center: CGPoint(x: 34.71, y: 5.29), radius: 1.76, color: burstMid, isStar: false, delay: 0.09, response: 0.33, damping: 0.64),
        BurstPiece(id: 9, center: CGPoint(x: 35.29, y: 23.53), radius: 1.18, color: burstBlue, isStar: false, delay: 0.16, response: 0.29, damping: 0.60),
        BurstPiece(id: 10, center: CGPoint(x: 33.86, y: 27.98), radius: 1.18, color: burstBlue, isStar: false, delay: 0.19, response: 0.27, damping: 0.68),
        BurstPiece(id: 11, center: CGPoint(x: 34.71, y: 20.59), radius: 0.59, color: burstPale, isStar: false, delay: 0.12, response: 0.22, damping: 0.78),
        BurstPiece(id: 12, center: CGPoint(x: 30.71, y: 29.53), radius: 1.85, color: burstPale, isStar: false, delay: 0.18, response: 0.35, damping: 0.56),
        BurstPiece(id: 13, center: CGPoint(x: 36.50, y: 10.20), radius: 3.2, color: burstBlue, isStar: true, delay: 0.08, response: 0.31, damping: 0.60),
        BurstPiece(id: 14, center: CGPoint(x: 8.50, y: 28.00), radius: 3.2, color: burstBlue, isStar: true, delay: 0.15, response: 0.37, damping: 0.54)
    ]
}

private struct BurstStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42
        let points = 5
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let radius = i % 2 == 0 ? outer : inner
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
