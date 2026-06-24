import Foundation

/// A marking layered ON the body (clipped to the body circle), part of a
/// creature's IDENTITY alongside colour + top feature. Like `CreatureStyle`,
/// each case is drawn in code (see `CreatureParts.swift`), so the taxonomy grows
/// by adding a case, never an art asset. `.none` draws nothing.
///
/// Cases are grouped by the species family they came from (docs/species/*.md).
enum BodyPattern: String, CaseIterable, Sendable, Identifiable {
    case none

    // celestial
    case starFreckles, galaxySwirl, crescentBelly, twilightBand, orbitRings, moonDust

    // garden
    case ladybugSpots, beeStripe, freckleDots, leafBelly, petalSpeckle, vineTrail, snailSwirl

    // ocean
    case scaleSpeckle, pearlBelly, bubbleDots, waveStripe, seafoamFreckles, tidalGradientBand

    // cozy
    case cocoaFreckles, creamBellyPatch, knitVStitches, sprinkleDots, toastyCheeks, swirlMarbling

    var id: String { rawValue }
}
