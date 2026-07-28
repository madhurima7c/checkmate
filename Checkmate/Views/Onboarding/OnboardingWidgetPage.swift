import SwiftUI

/// Figma 598:2655 — static "add widget" page: home-screen edit-mode capture
/// with the Checkmate widget, fading into canvas. No interaction.
struct OnboardingWidgetPage: View {
    @Environment(\.onboardingWidgetTuning) private var tuning
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                hero
                    .scaleEffect(appeared ? 1 : tuning.heroEntranceScale)
                    .offset(y: appeared ? 0 : tuning.heroEntranceOffsetY)
                    .position(
                        x: geo.size.width / 2,
                        y: tuning.heroTop + tuning.heroHeight / 2
                    )

                LinearGradient(
                    stops: [
                        .init(color: Color(dialHex: tuning.canvasHex).opacity(0), location: 0),
                        .init(color: Color(dialHex: tuning.canvasHex), location: tuning.heroFadeStop)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: tuning.heroFadeHeight)
                .offset(y: tuning.heroFadeOffsetY)
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(
                    .spring(
                        response: tuning.heroEntranceResponse,
                        dampingFraction: tuning.heroEntranceDamping
                    )
                ) {
                    appeared = true
                }
            }
        }
    }

    private var hero: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: tuning.heroCornerRadius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: tuning.heroCornerRadius,
            style: .continuous
        )
        return Image("OnboardingWidgetHero")
            .resizable()
            .scaledToFill()
            .frame(width: tuning.heroWidth, height: tuning.heroHeight, alignment: .top)
            .clipShape(shape)
            .overlay(alignment: .topLeading) {
                // Figma 2051:3038 — friend avatar pinned to the widget's third row.
                Image("OnboardingAvatarFriend")
                    .resizable()
                    .scaledToFill()
                    .frame(width: tuning.friendAvatarSize, height: tuning.friendAvatarSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            Color.white.opacity(tuning.friendRingOpacity),
                            lineWidth: tuning.friendRingWidth
                        )
                    )
                    .shadow(
                        color: .black.opacity(tuning.friendShadowOpacity),
                        radius: tuning.friendShadowRadius
                    )
                    .offset(x: tuning.friendAvatarX, y: tuning.friendAvatarY)
            }
    }
}
