import SwiftUI
import CoreMotion
import QuartzCore

/// Where the card is pointing, and how hard it is being moved.
///
/// One object owns the whole input path: device gyroscope, finger drag, the slow drift it
/// does when nobody is touching it, and the two followers that give the card and its foil
/// different weights. Views just read `tilt` and `sheet`.
///
/// **Why a display link and not `TimelineView`.** The rest of the app derives motion from
/// a timestamp — `YolkMotion` is a pure function of `t`, which is what makes the creature
/// snapshot-testable and freezable. That doctrine does not fit here, because a follower is
/// an *integrator*: where the card is pointing depends on every input since you touched
/// it, not on the clock. So this is honestly stateful, driven off `CADisplayLink`, and it
/// stops itself the moment the card leaves the screen.
@Observable
final class CardTilt {
    /// The fast follower. Drives the card's own geometry — rotation, glare, edge catch.
    private(set) var tilt: CGPoint = .zero

    /// The slow follower. Drives the foil, the reveal threshold and the sweet spot.
    ///
    /// Everything that belongs to the *surface* rather than to the card's geometry reads
    /// this one, so it inherits the lag for free and can never snap into place in a single
    /// frame the way it would off the fast value.
    private(set) var sheet: CGPoint = .zero

    /// Direction of travel, for the velocity streak.
    private(set) var velocity: CGPoint = .zero

    /// Smoothed speed, 0…1.
    private(set) var speed: Double = 0

    /// Seconds since this card woke up, for the slow resting cycles.
    private(set) var time: Double = 0

    /// True once device motion has actually produced a reading, so the UI can offer the
    /// drag fallback only where it is needed rather than promising tilt on a simulator.
    private(set) var usingDeviceMotion = false

    private var card = Follow(stiffness: 0.16)
    private var foil = Follow(stiffness: 0.09)
    private var kick = Kick()

    private var motion: CMMotionManager?
    /// The first orientation reading, taken as the origin.
    private var zero: (roll: Double, pitch: Double)?

    private var link: CADisplayLink?
    private var lastTick: CFTimeInterval = 0
    private var t0: CFTimeInterval = 0

    /// Where the finger says to point. Held rather than assigned straight to the target so
    /// the frame loop can ease into it.
    private var aim: CGPoint = .zero
    private var touching = false

    /// Progress of the ease into a fresh touch, and where the card was when it started.
    ///
    /// Without this, first contact assigns a target most of the card's travel away and the
    /// follower covers 16% of that gap on the next frame — a visible teleport. This picks
    /// the card up from wherever it had drifted to instead.
    private var grab: Double = 1
    private var grabFrom: CGPoint = .zero

    /// The same ease on the way out, back into the idle drift.
    private var release: Double = 1
    private var handoff: CGPoint = .zero
    private var idle: Double = 0

    private var reduceMotion = false
    /// Whether the sheet is currently inside the sweet spot, for the haptic's hysteresis.
    private var inSweetSpot = false

    // MARK: Lifecycle

    /// Begin. Safe to call repeatedly; only the first call does anything.
    func start(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
        guard link == nil else { return }

        // Reduce Motion gets a still card at a flattering fixed pose rather than a dead
        // flat one. The material is the point of the card, and killing the tilt entirely
        // would leave a grey rectangle — so the pose is frozen near the sweet spot, which
        // is a card catching the light, just not one that moves.
        guard !reduceMotion else {
            tilt = CGPoint(x: -0.30, y: -0.26)
            sheet = tilt
            return
        }

        startDeviceMotion()

        t0 = CACurrentMediaTime()
        lastTick = t0
        let l = CADisplayLink(target: Proxy(self), selector: #selector(Proxy.tick(_:)))
        l.add(to: .main, forMode: .common)
        link = l
    }

    /// Stop and release the sensor. Called when the card scrolls away or the sheet closes —
    /// a gyroscope left running is a real battery cost for a card nobody is looking at.
    func stop() {
        link?.invalidate()
        link = nil
        motion?.stopDeviceMotionUpdates()
        motion = nil
        zero = nil
        usingDeviceMotion = false
    }

    private func startDeviceMotion() {
        let m = CMMotionManager()
        guard m.isDeviceMotionAvailable else { return }
        m.deviceMotionUpdateInterval = 1.0 / 60.0
        // Started without a handler and polled from the frame loop instead. A callback
        // would hand us a non-Sendable `CMDeviceMotion` across an isolation boundary, and
        // polling keeps every input on one clock anyway.
        m.startDeviceMotionUpdates()
        motion = m
    }

    // MARK: Input

    /// A finger, in the card's own coordinate space.
    func drag(to point: CGPoint, in size: CGSize) {
        guard !reduceMotion else { return }
        aim = CGPoint(x: Holo.clamp(point.x / size.width * 2 - 1),
                      y: Holo.clamp(point.y / size.height * 2 - 1))
        if !touching {
            // Only on the transition into a touch. Restarting the pick-up on every drag
            // update would leave the card permanently lagging the finger.
            touching = true
            grabFrom = card.value
            grab = 0
        }
        release = 0
    }

    /// The finger left.
    func releaseDrag() {
        guard !reduceMotion else { return }
        touching = false
        handoff = card.value
        release = 0
        grab = 1
        // Carry past a little on the axis you were pushing. Scaled by the speed at
        // release, so a flick throws the card and setting it down does nothing.
        kick.fire(card.velocity)
    }

    // MARK: The frame

    fileprivate func step() {
        let now = CACurrentMediaTime()
        lastTick = now
        time = now - t0

        // Device motion wins when it is actually reporting, because a phone in the hand is
        // the medium this card is for. A finger still overrides it: if you are dragging,
        // you are deliberately aiming.
        if !touching, let att = motion?.deviceMotion?.attitude {
            // ZEROED ON THE FIRST READING. This is the detail that makes tilt usable at
            // all: nobody holds a phone flat, so pitch sits somewhere around 40–70° for a
            // person looking at a screen. An absolute reading pins the card to one corner
            // and it never comes back. Taking the first sample as the origin means the
            // card responds to how far you have turned it FROM WHERE YOU ALREADY WERE.
            if zero == nil {
                zero = (att.roll, att.pitch)
                usingDeviceMotion = true
            }
            if let z = zero {
                // Small range, because wrist movement is small. At 45° you would have to
                // turn the phone over to reach the edge of the effect.
                let range = 0.38
                card.target = CGPoint(x: Holo.clamp((att.roll - z.roll) / range),
                                      y: Holo.clamp((att.pitch - z.pitch) / range))
                release = 1
                grab = 1
            }
        } else if touching {
            // Ease from where the card was into where the finger is, so it picks up gently
            // instead of snatching. Squared, so it leaves slowly and arrives with pace.
            grab = min(1, grab + 0.018 * 2)
            let k = grab * grab
            card.target = CGPoint(x: grabFrom.x + (aim.x - grabFrom.x) * k,
                                  y: grabFrom.y + (aim.y - grabFrom.y) * k)
        } else {
            // A slow wander when untouched and unsensed, so the card is alive before you
            // reach it. Two incommensurate rates, so it never visibly repeats.
            idle += 0.0042
            let drift = CGPoint(x: sin(idle) * 0.28, y: cos(idle * 0.73) * 0.20)
            // EASE BACK INTO THE DRIFT, do not cut to it. The drift's phase keeps
            // advancing while you hold the card, so at the moment you let go it is
            // somewhere unrelated to where the card is pointing. Handing the target
            // straight over teleports it and the follower then races to catch up.
            release = min(1, release + 0.016)
            let k = release * release
            card.target = CGPoint(x: handoff.x + (drift.x - handoff.x) * k,
                                  y: handoff.y + (drift.y - handoff.y) * k)
        }

        // The release overshoot rides ON TOP of the target rather than replacing it, so
        // the branches above stay untouched and the bounce simply adds and decays away.
        let k = kick.step()
        if k != .zero {
            card.target = CGPoint(x: card.target.x + k.x, y: card.target.y + k.y)
        }

        card.step()
        foil.target = card.value
        foil.step()

        tilt = card.value
        sheet = foil.value
        velocity = foil.velocity
        speed = foil.speed

        reportSweetSpot()
    }

    /// A tick when the material lines up.
    ///
    /// `HoloMaterial` puts the sweet spot off-centre specifically so it has to be hunted
    /// for, and hunting for something you can only see is half an interaction. Feeling the
    /// moment it aligns is what tells you it was a real place on the card rather than the
    /// foil happening to look nice, and it is what makes people keep turning it.
    ///
    /// **Hysteresis, not a threshold.** A single trip point would chatter continuously while
    /// a hand hovered near the edge of the spot, which is the worst possible haptic: constant
    /// and meaningless. It fires entering at 0.72 and only re-arms once you have clearly left
    /// at 0.45.
    ///
    /// Gated on the input actually being driven. The idle drift sweeps through the spot on
    /// its own, and a card buzzing at nobody is a bug.
    private func reportSweetSpot() {
        guard usingDeviceMotion || touching else { inSweetSpot = false; return }
        let s = Holo.spot(foil.value)
        if s > 0.72, !inSweetSpot {
            inSweetSpot = true
            Haptics.shared.select()
        } else if s < 0.45 {
            inSweetSpot = false
        }
    }

    /// `CADisplayLink` needs an `NSObject` target and retains it, so a proxy holding the
    /// store weakly is what lets a discarded card actually deallocate.
    ///
    /// It also invalidates itself once the owner is gone. `deinit` cannot do that job —
    /// it is nonisolated and cannot touch this actor's state — and without it the link
    /// would sit in the run loop firing into nothing for the life of the process.
    private final class Proxy: NSObject {
        weak var owner: CardTilt?
        init(_ owner: CardTilt) { self.owner = owner }
        @objc func tick(_ link: CADisplayLink) {
            guard let owner else { link.invalidate(); return }
            owner.step()
        }
    }
}

// MARK: - Followers

/// A damped follower.
///
/// Not a spring with overshoot — a simple exponential ease toward a target, run per frame.
/// Overshoot is wrong here: a card settling should look like *weight*, not like a bounce,
/// and a card that wobbles whenever you nudge it reads as an animation rather than as an
/// object. `stiffness` is the fraction of the remaining distance covered each frame, so a
/// lower number is heavier.
private struct Follow {
    var value: CGPoint = .zero
    var target: CGPoint = .zero
    var velocity: CGPoint = .zero
    /// Smoothed magnitude of that velocity. Raw per-frame deltas are spiky enough to make
    /// anything driven by them flicker, so consumers read this instead.
    var speed: Double = 0
    let stiffness: Double

    mutating func step() {
        let p = value
        value.x += (target.x - value.x) * stiffness
        value.y += (target.y - value.y) * stiffness
        velocity = CGPoint(x: value.x - p.x, y: value.y - p.y)
        // Asymmetric smoothing: rises fast so a flick registers on the frame it happens,
        // falls slowly so the streak it leaves decays instead of snapping off the moment
        // you stop. A symmetric filter gives you one or the other, never both.
        let raw = min(1, hypot(velocity.x, velocity.y) * 14)
        speed += (raw - speed) * (raw > speed ? 0.45 : 0.06)
    }
}

/// A one-shot overshoot, for the moment the finger leaves.
///
/// Real objects do not glide to a stop along the shortest path — they carry past a little
/// on the axis they were pushed and settle back. Deliberately *not* a spring on the main
/// follower: a spring rings on every movement. This fires once, scaled by how fast you
/// were going, and decays to exactly nothing.
private struct Kick {
    private var amount: CGPoint = .zero
    private var life: Double = 0

    mutating func fire(_ v: CGPoint, gain: Double = 2.6) {
        // Below a threshold there was no throw, just a finger lifting, and a bounce there
        // reads as a twitch.
        guard hypot(v.x, v.y) >= 0.002 else { return }
        amount = CGPoint(x: v.x * gain, y: v.y * gain)
        life = 1
    }

    mutating func step() -> CGPoint {
        guard life > 0 else { return .zero }
        life = max(0, life - 0.035)
        // A half sine over the life: rises to the overshoot, returns through zero. Ending
        // at exactly zero is the point — a decaying oscillation would leave the card
        // fractionally off true forever.
        let e = sin(life * .pi) * life
        return CGPoint(x: amount.x * e, y: amount.y * e)
    }

    var active: Bool { life > 0 }
}
