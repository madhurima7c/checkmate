import SwiftUI

struct ProgressPill: View {
    let done: Int
    let total: Int

    /// Figma — gap between the dial and “N of M done”.
    private let dialToTextSpacing: CGFloat = 6
    private let dialSize: CGFloat = 20

    private var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    var body: some View {
        HStack(alignment: .center, spacing: dialToTextSpacing) {
            ProgressDial(fraction: fraction)
                .frame(width: dialSize, height: dialSize)

            Text("\(done) of \(total) done")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Palette.dim)
                .fixedSize(horizontal: true, vertical: false)
                .contentTransition(.numericText())
        }
        .opacity(total > 0 ? 1 : 0)
        .animation(Theme.spring, value: done)
        .animation(Theme.spring, value: total)
    }
}

struct ProgressDial: View {
    let fraction: Double

    private let strokeWidth = Theme.Stroke.progressRing

    var body: some View {
        let ring = StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        ZStack {
            Circle()
                .stroke(Theme.Palette.selectionBlue.opacity(0.22), style: ring)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Theme.Palette.selectionBlue, style: ring)
                .rotationEffect(.degrees(-90))
                .animation(Theme.spring, value: fraction)
        }
    }
}
