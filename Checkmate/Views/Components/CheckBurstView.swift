import SwiftUI

// Playful check burst — stars + dots radiating from the checkbox (Figma 571:10465).
struct CheckBurstView: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let specs: [(angle: Double, dist: CGFloat, kind: Int, size: CGFloat)] = [
                (0.0, 1.0, 1, 9), (0.5, 0.85, 0, 6), (1.1, 0.95, 1, 8),
                (1.8, 0.75, 0, 5), (2.4, 1.0, 1, 10), (3.2, 0.8, 0, 6), (3.9, 0.9, 1, 7),
                (4.6, 0.7, 0, 5), (5.2, 0.95, 1, 8), (5.8, 0.85, 0, 6), (6.4, 1.05, 1, 7)
            ]
            for spec in specs {
                let d = progress * spec.dist * 36
                let x = center.x + cos(spec.angle) * d
                let y = center.y + sin(spec.angle) * d
                let alpha = 1 - progress * 0.85
                let s = spec.size * (1 - progress * 0.35)
                if spec.kind == 1 {
                    drawStar(ctx: ctx, center: CGPoint(x: x, y: y), size: s, alpha: alpha)
                } else {
                    let rect = CGRect(x: x - s/2, y: y - s/2, width: s, height: s)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Theme.Palette.blue.opacity(alpha)))
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.28)) { progress = 1 }
        }
    }

    private func drawStar(ctx: GraphicsContext, center: CGPoint, size: CGFloat, alpha: Double) {
        var path = Path()
        let points = 5
        let outer = size / 2
        let inner = outer * 0.42
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let r = i % 2 == 0 ? outer : inner
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(Theme.Palette.blue.opacity(alpha)))
    }
}
