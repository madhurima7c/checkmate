import SwiftUI

/// Compact iMessage tray — Figma 798:2747 (402x339 design frame).
struct ComposerTrayView: View {
    var onAddTapped: () -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                background

                ForEach(Sticky.scattered) { sticky in
                    StickyNoteView(sticky: sticky)
                        .position(
                            x: size.width * sticky.unitCenter.x,
                            y: size.height * sticky.unitCenter.y
                        )
                }

                // Tagline pinned near the top of the tray (Figma 798:2730).
                Image("TrayTagline")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 13.5)
                    .position(x: size.width / 2, y: size.height * 0.153)

                // Icon -> wordmark cluster (spacing per Figma).
                VStack(spacing: 0) {
                    Image("TrayIcon")
                        .resizable()
                        .frame(width: 64, height: 64)
                    Image("TrayWordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 13.3)
                        .padding(.top, 15.4)
                }
                .position(x: size.width / 2, y: size.height * 0.455)

                createButton
                    .frame(width: size.width - 50, height: 62)
                    .position(x: size.width / 2, y: size.height * 0.835)
            }
            .clipped()
        }
        .ignoresSafeArea()
    }

    private var background: some View {
        ZStack {
            Color(hex: 0xF9F7F3)
            Image("CloudBackground")
                .resizable()
                .scaledToFill()
        }
    }

    private var createButton: some View {
        Button(action: onAddTapped) {
            Text("Create a todo")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Palette.dark, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.03), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.07), radius: 3.1, x: 0, y: 1.4)
        }
        .buttonStyle(BoopButtonStyle())
    }
}

// MARK: - Scattered sticky notes

/// Static decoration specs pulled from Figma; `unitCenter` is the card center
/// as a fraction of the 402x339 design frame so edge notes stay pinned to the
/// tray edges at any width/height.
private struct Sticky: Identifiable {
    let id: Int
    let paper: Color
    let rotation: Double
    let unitCenter: CGPoint
    let checked: Bool

    static let scattered: [Sticky] = [
        // Right edge, top to bottom.
        Sticky(id: 0, paper: Color(hex: 0xFFC7EC), rotation: 21.92, unitCenter: CGPoint(x: 385.7 / 402, y: 90.0 / 339), checked: true),
        Sticky(id: 1, paper: Color(hex: 0xFFD9C0), rotation: 6.12, unitCenter: CGPoint(x: 371.5 / 402, y: 155.6 / 339), checked: false),
        Sticky(id: 2, paper: Color(hex: 0xBFEEFF), rotation: -19.78, unitCenter: CGPoint(x: 393.3 / 402, y: 205.4 / 339), checked: false),
        // Left edge, top to bottom.
        Sticky(id: 3, paper: Color(hex: 0xBFEEFF), rotation: -22.16, unitCenter: CGPoint(x: 28.2 / 402, y: 90.0 / 339), checked: false),
        Sticky(id: 4, paper: Color(hex: 0xFFEEAE), rotation: 20.63, unitCenter: CGPoint(x: 21.0 / 402, y: 138.3 / 339), checked: true),
        Sticky(id: 5, paper: Color(hex: 0xFFD9C0), rotation: -5.89, unitCenter: CGPoint(x: 21.0 / 402, y: 202.2 / 339), checked: false),
    ]
}

private struct StickyNoteView: View {
    let sticky: Sticky

    var body: some View {
        RoundedRectangle(cornerRadius: 9.5, style: .continuous)
            .fill(sticky.paper)
            .frame(width: 68, height: 69.6)
            .overlay(
                RoundedRectangle(cornerRadius: 9.5, style: .continuous)
                    .stroke(.white, lineWidth: 2.37)
            )
            .overlay(alignment: .topLeading) {
                checkbox.padding(8)
            }
            .shadow(color: .black.opacity(0.03), radius: 1.2, x: 0.5, y: 1)
            .rotationEffect(.degrees(sticky.rotation))
    }

    @ViewBuilder
    private var checkbox: some View {
        if sticky.checked {
            RoundedRectangle(cornerRadius: 2.6, style: .continuous)
                .fill(Theme.Palette.selectionBlue)
                .frame(width: 7.9, height: 7.9)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 4.4, weight: .heavy))
                        .foregroundStyle(.white)
                )
        } else {
            RoundedRectangle(cornerRadius: 2.6, style: .continuous)
                .stroke(Theme.Palette.checkboxStroke, lineWidth: 0.78)
                .frame(width: 7.9, height: 7.9)
        }
    }
}

#Preview(traits: .fixedLayout(width: 402, height: 339)) {
    ComposerTrayView(onAddTapped: {})
}
