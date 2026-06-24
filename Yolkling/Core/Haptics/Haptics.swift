import CoreHaptics
import UIKit

/// Central haptics. Uses Core Haptics for rich, punchy custom patterns, with a
/// UIKit impact fallback. Call the presets from interaction handlers.
@MainActor
final class Haptics {
    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() {
        guard supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.isAutoShutdownEnabled = true
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        try? engine?.start()
    }

    // MARK: Presets

    /// Tiny crisp tick — typewriter, light steps.
    func tick() { transient(intensity: 0.6, sharpness: 0.85) }

    /// A selection / toggle — crisp and present.
    func select() { transient(intensity: 0.85, sharpness: 0.6) }

    /// Squishy pet — a firm soft thud with a little bounce after.
    func pet() {
        play([
            transientEvent(0, intensity: 1.0, sharpness: 0.3),
            transientEvent(0.07, intensity: 0.6, sharpness: 0.25),
        ])
    }

    /// A satisfying pop — the hatch / big moment. A quick rumble into a sharp tap.
    func pop() {
        play([
            continuousEvent(0, duration: 0.13, intensity: 0.7, sharpness: 0.25),
            transientEvent(0.13, intensity: 1.0, sharpness: 0.95),
        ])
    }

    /// Reward / success — two rising taps.
    func reward() {
        play([
            transientEvent(0, intensity: 0.75, sharpness: 0.45),
            transientEvent(0.13, intensity: 1.0, sharpness: 0.75),
        ])
    }

    /// A gentle "nope" — two dull bumps.
    func warn() {
        play([
            transientEvent(0, intensity: 0.8, sharpness: 0.2),
            transientEvent(0.11, intensity: 0.55, sharpness: 0.2),
        ])
    }

    // MARK: Engine

    private func transient(intensity: Float, sharpness: Float) {
        play([transientEvent(0, intensity: intensity, sharpness: sharpness)])
    }

    private func transientEvent(_ t: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: t)
    }

    private func continuousEvent(_ t: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: t, duration: duration)
    }

    private func play(_ events: [CHHapticEvent]) {
        guard supportsHaptics, let engine else { fallbackImpact(); return }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            fallbackImpact()
        }
    }

    private func fallbackImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
