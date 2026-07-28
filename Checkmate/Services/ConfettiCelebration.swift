import AVFoundation
import CoreHaptics
import UIKit

/// iMessage-style confetti celebration: the actual CKConfettiEffect sound
/// (`ConfettiSoundEffect.m4a`, bundled) plus a celebratory haptic burst —
/// a strong pop followed by a sparkle of decaying taps.
///
/// Audio session + player setup happens on a background queue: first-time
/// CoreAudio spin-up can block for seconds (especially on the simulator) and
/// must never stall the check-off animation. Call `prewarm()` early.
final class ConfettiCelebration {
    static let shared = ConfettiCelebration()

    private let audioQueue = DispatchQueue(label: "checkmate.confetti.audio", qos: .userInitiated)
    /// Only touched on `audioQueue`.
    private var player: AVAudioPlayer?
    private var audioReady = false

    /// Only touched on the main thread.
    private var hapticEngine: CHHapticEngine?

    private init() {}

    /// Loads the sound and audio session off the main thread so the first
    /// check-off doesn't hitch.
    func prewarm() {
        audioQueue.async { self.loadAudioIfNeeded() }
    }

    func play(
        volume: Double = 0.8,
        hapticIntensity: Double = 1,
        sound: Bool = true,
        haptics: Bool = true
    ) {
        if haptics { playHaptics(intensity: hapticIntensity) }
        if sound {
            audioQueue.async {
                self.loadAudioIfNeeded()
                guard let player = self.player else { return }
                player.volume = Float(max(0, min(1, volume)))
                player.currentTime = 0
                player.play()
            }
        }
    }

    // MARK: - Sound

    private func loadAudioIfNeeded() {
        guard !audioReady else { return }
        audioReady = true
        // Ambient like iMessage effects: mixes with music, mutes with the
        // silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        if let url = Bundle.main.url(forResource: "ConfettiSoundEffect", withExtension: "m4a") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        }
    }

    // MARK: - Haptics

    private func playHaptics(intensity: Double) {
        let clamped = max(0, min(1, intensity))
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        if hapticEngine == nil {
            hapticEngine = try? CHHapticEngine()
            hapticEngine?.resetHandler = { [weak self] in
                DispatchQueue.main.async { try? self?.hapticEngine?.start() }
            }
        }
        guard let engine = hapticEngine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        do {
            try engine.start()
            let pattern = try Self.celebrationPattern(intensity: clamped)
            let hapticPlayer = try engine.makePlayer(with: pattern)
            try hapticPlayer.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Big opening pop + short rumble + ~1s of scattered decaying pops.
    private static func celebrationPattern(intensity: Double) throws -> CHHapticPattern {
        func transient(time: Double, strength: Double, sharpness: Double) -> CHHapticEvent {
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(strength * intensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness))
                ],
                relativeTime: time
            )
        }

        var events: [CHHapticEvent] = [
            transient(time: 0, strength: 1, sharpness: 0.65),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.45 * intensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.01,
                duration: 0.28
            )
        ]

        // Sparkle: pops thin out and soften as the confetti disperses.
        let sparkle: [(Double, Double, Double)] = [
            (0.08, 0.85, 0.55), (0.16, 0.75, 0.5), (0.22, 0.8, 0.6),
            (0.31, 0.65, 0.45), (0.38, 0.55, 0.5), (0.47, 0.6, 0.4),
            (0.58, 0.45, 0.45), (0.66, 0.5, 0.35), (0.78, 0.35, 0.4),
            (0.9, 0.3, 0.3), (1.05, 0.22, 0.3)
        ]
        events.append(contentsOf: sparkle.map { transient(time: $0.0, strength: $0.1, sharpness: $0.2) })

        return try CHHapticPattern(events: events, parameters: [])
    }
}
