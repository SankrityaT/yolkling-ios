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

    // MARK: Dragging texture

    /// The player behind ``startScratch()``. Held because a continuous haptic has to be
    /// steered while it runs and then stopped, which a fire-and-forget player cannot do.
    private var scratchPlayer: CHHapticAdvancedPatternPlayer?

    /// Begin a continuous scratchy texture, for a drag.
    ///
    /// **Why continuous and not a train of taps.** A run of transients is a click track: at
    /// any spacing you can pick out the individual clicks, and it reads as a ratchet rather
    /// than a surface. Friction is a sustained vibration whose character changes with how
    /// fast you are moving, which is a continuous event with its parameters driven live.
    /// The transient grain from ``scratchGrain(speed:)`` then rides on top, the way real
    /// texture is a rumble with catches in it.
    ///
    /// Starts silent. ``updateScratch(speed:)`` is what makes it audible, so touching down
    /// without moving buzzes nothing.
    func startScratch() {
        guard supportsHaptics, let engine, scratchPlayer == nil else { return }
        do {
            try engine.start()
            // 30s is Core Haptics' ceiling for one continuous event. Nobody scratches for
            // 30 seconds, and `stopScratch()` ends it long before that.
            let event = continuousEvent(0, duration: 30, intensity: 0.0, sharpness: 0.9)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: 0)
            scratchPlayer = player
        } catch {
            scratchPlayer = nil
        }
    }

    /// Steer the texture. `speed` is 0...1, normalised by the caller.
    ///
    /// Intensity tracks speed so a slow careful scratch is faint and a fast sweep is
    /// coarse. Sharpness moves the opposite way, down slightly as speed rises: a fast drag
    /// across a rough surface is more of a rumble than a hiss, and holding sharpness at
    /// maximum makes speed read as volume rather than as friction.
    func updateScratch(speed: Double) {
        guard let scratchPlayer else { return }
        let s = min(max(speed, 0), 1)
        let intensity = Float(0.12 + 0.5 * s)
        let sharpness = Float(0.95 - 0.25 * s)
        try? scratchPlayer.sendParameters([
            CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                     value: intensity, relativeTime: 0),
            CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                     value: sharpness, relativeTime: 0),
        ], atTime: CHHapticTimeImmediate)
    }

    /// One irregular catch, to sit on top of the continuous bed.
    ///
    /// Jittered on purpose. A grain at constant intensity is a metronome, and a metronome
    /// is the one thing a scratch is not. The caller fires these per unit of DISTANCE
    /// travelled rather than per unit of time, so the grain is a property of the surface
    /// rather than of the frame rate.
    func scratchGrain(speed: Double) {
        let s = Float(min(max(speed, 0), 1))
        let jitter = Float.random(in: 0.7...1.0)
        transient(intensity: (0.14 + 0.3 * s) * jitter, sharpness: 0.9)
    }

    /// Lift. Safe to call when nothing is running.
    func stopScratch() {
        guard let scratchPlayer else { return }
        try? scratchPlayer.stop(atTime: CHHapticTimeImmediate)
        self.scratchPlayer = nil
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
