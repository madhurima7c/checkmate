import SwiftUI

struct ProgressPill: View {
    let done: Int
    let total: Int

    private var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            ProgressDial(fraction: fraction)
                .frame(width: 20, height: 20)

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

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Palette.blue.opacity(0.22), lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    Theme.Palette.blue,
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.spring, value: fraction)
        }
    }
}
