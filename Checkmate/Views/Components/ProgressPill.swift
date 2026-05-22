import SwiftUI

// Figma: dial + "x of y done" — no pill background, sits on the page fade.
struct ProgressPill: View {
    let done: Int
    let total: Int

    private var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    var body: some View {
        HStack(spacing: 4) {
            ProgressDial(fraction: fraction)
                .frame(width: 20, height: 20)

            Text("\(done) of \(total) done")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Palette.dim)
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
                .stroke(Color.black.opacity(0.12), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    Theme.Palette.blue,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.spring, value: fraction)
        }
    }
}
