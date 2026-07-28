import Lottie
import SwiftUI

/// Lottie confetti burst for home-page check-off (`ConfettiBurst.json`).
/// Plays once from the card center. Onboarding keeps its own falling confetti.
struct CheckConfettiView: UIViewRepresentable {
    var speed: Double = 1

    /// ConfettiBurst.json composition size (940×752).
    static let aspectRatio: CGFloat = 940.0 / 752.0

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false
        container.clipsToBounds = false

        let animationView = LottieAnimationView(name: "ConfettiBurst")
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.loopMode = .playOnce
        animationView.animationSpeed = CGFloat(speed)
        animationView.isUserInteractionEnabled = false
        animationView.backgroundColor = .clear
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.animationView = animationView
        animationView.play()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.animationView?.animationSpeed = CGFloat(speed)
    }

    final class Coordinator {
        var animationView: LottieAnimationView?
    }
}
