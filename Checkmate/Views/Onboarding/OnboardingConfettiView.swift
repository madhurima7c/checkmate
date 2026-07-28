import SwiftUI

/// Celebration confetti that drops from the top of the screen. Each bump of
/// `token` spawns a fresh batch; pieces clean themselves up after falling.
struct OnboardingConfettiView: View {
    let token: Int
    var tuning: OnboardingStickiesTuning = .default

    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, canvasSize: geo.size)
                }
            }
        }
        .onChange(of: token) { _, _ in
            spawnBatch()
        }
    }

    private func spawnBatch() {
        let count = max(1, Int(tuning.confettiCount.rounded()))
        let batch = (0..<count).map { _ in ConfettiPiece.random(tuning: tuning) }
        pieces.append(contentsOf: batch)

        let batchIds = Set(batch.map(\.id))
        let lifetime = (batch.map { $0.delay + $0.duration }.max() ?? 3) + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
            pieces.removeAll { batchIds.contains($0.id) }
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let xFraction: CGFloat
    let size: CGSize
    let color: Color
    let isRound: Bool
    let delay: Double
    let duration: Double
    /// Horizontal drift over the fall, in points.
    let drift: CGFloat
    /// Total flat-spin rotation over the fall, in degrees.
    let spin: Double
    /// Total 3D tumble over the fall, in degrees.
    let tumble: Double
    let tumbleAxis: (x: CGFloat, y: CGFloat, z: CGFloat)

    /// Sticky-note dots plus the selection blue — Checkmate's own palette.
    private static let colors: [Color] = [
        Color(hex: 0xFFE3AE),
        Color(hex: 0xFFC0EA),
        Color(hex: 0xBFEEFF),
        Color(hex: 0xFFD2B2),
        Theme.Palette.selectionBlue,
        Color(hex: 0x96CEFF)
    ]

    static func random(tuning: OnboardingStickiesTuning) -> ConfettiPiece {
        let isRound = Double.random(in: 0...1) < 0.3
        let minSize = min(tuning.confettiMinSize, tuning.confettiMaxSize)
        let maxSize = max(tuning.confettiMinSize, tuning.confettiMaxSize)
        let width = CGFloat.random(in: minSize...maxSize)
        let minDuration = min(tuning.confettiMinDuration, tuning.confettiMaxDuration)
        let maxDuration = max(tuning.confettiMinDuration, tuning.confettiMaxDuration)
        let tumbleMin = min(tuning.confettiTumbleMin, tuning.confettiTumbleMax)
        let tumbleMax = max(tuning.confettiTumbleMin, tuning.confettiTumbleMax)
        let drift = abs(tuning.confettiDrift)
        let spin = abs(tuning.confettiSpin)
        return ConfettiPiece(
            xFraction: CGFloat.random(in: 0.02...0.98),
            size: isRound
                ? CGSize(width: width, height: width)
                : CGSize(width: width, height: width * CGFloat.random(in: 1.3...1.8)),
            color: colors.randomElement()!,
            isRound: isRound,
            delay: Double.random(in: 0...max(0.01, tuning.confettiMaxDelay)),
            duration: Double.random(in: minDuration...maxDuration),
            drift: CGFloat.random(in: -drift...drift),
            spin: Double.random(in: -spin...spin),
            tumble: Double.random(in: tumbleMin...tumbleMax),
            tumbleAxis: (
                x: CGFloat.random(in: 0.4...1),
                y: CGFloat.random(in: 0.4...1),
                z: 0
            )
        )
    }
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let canvasSize: CGSize

    @State private var falling = false

    var body: some View {
        shape
            .frame(width: piece.size.width, height: piece.size.height)
            .rotation3DEffect(
                .degrees(falling ? piece.tumble : 0),
                axis: piece.tumbleAxis
            )
            .rotationEffect(.degrees(falling ? piece.spin : 0))
            .position(
                x: canvasSize.width * piece.xFraction + (falling ? piece.drift : 0),
                y: falling ? canvasSize.height + 40 : -30
            )
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                    falling = true
                }
            }
    }

    @ViewBuilder
    private var shape: some View {
        if piece.isRound {
            Circle().fill(piece.color)
        } else {
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(piece.color)
        }
    }
}
