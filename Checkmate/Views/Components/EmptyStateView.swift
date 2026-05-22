import SwiftUI

/// Figma iPhone 16 & 17 Pro - 26 (571:10167)
struct EmptyStateView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                FigmaEmptyIllustration()
                    .frame(height: 200)

                Text("Nothing here yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Palette.ink)
                    .padding(.top, 16)

                Text("Click to add a todo")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Palette.dim)
                    .padding(.top, 8)

                Image("EmptyArrow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 115, height: 220)
                    .rotationEffect(.degrees(1.82))
                    .padding(.top, 8)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)

            // Figma gradient wash over illustration area
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color(hex: 0xFAFAFA).opacity(0), Theme.Palette.canvas],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 199)
            }
            .allowsHitTesting(false)
            .padding(.bottom, 180)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Decorative stickies — intentionally tilted (empty state only).
struct FigmaEmptyIllustration: View {
    var body: some View {
        ZStack {
            emptySticky(
                color: .blue,
                text: "Plan for the party on Saturday",
                rotation: 0,
                offset: CGSize(width: 12, height: -24)
            )
            emptySticky(
                color: .yellow,
                text: "Connect with dentist",
                rotation: -10.15,
                offset: CGSize(width: -88, height: 8),
                done: true
            )
            emptySticky(
                color: .pink,
                text: "Pick up Cheddar from neighbors",
                rotation: 15.09,
                offset: CGSize(width: 78, height: 4),
                showNew: true
            )
        }
        .frame(width: 280, height: 170)
    }

    private func emptySticky(
        color: StickyColor,
        text: String,
        rotation: Double,
        offset: CGSize,
        done: Bool = false,
        showNew: Bool = false
    ) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white, lineWidth: 4.5)
                )
                .frame(width: 131, height: 134)
                .stickyShadow()

            if done {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Theme.Palette.blue)
                    .frame(width: 15, height: 15)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .padding(12)
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.Palette.checkboxStroke, lineWidth: 1.5)
                    .frame(width: 15, height: 15)
                    .padding(12)
            }

            if showNew {
                NewBadge()
                    .padding(.leading, 54)
                    .padding(.top, 38)
            }

            Text(text)
                .font(.system(size: 11, weight: done ? .regular : .medium))
                .foregroundStyle(done ? Theme.Palette.strike : Theme.Palette.body)
                .strikethrough(done)
                .lineLimit(3)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .rotationEffect(.degrees(rotation))
        .offset(offset)
    }
}
