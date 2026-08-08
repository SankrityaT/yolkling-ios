import SwiftUI

/// Scratch the card to find out what you got.
///
/// This replaced a crack-and-flip cutscene, and it is better for one reason: you do it.
/// A ceremony you watch is the same every time and you learn to skip it. A scratch panel
/// has your finger in it, gives way under pressure, and hides the answer until you have
/// personally uncovered enough of it. Everyone already knows the gesture, which means
/// there is nothing to teach.
///
/// It also costs almost nothing to build here, because ``YolkCardBack`` already *is* a
/// scratch panel: dotted stock over the thing you want. The card front renders underneath
/// at full quality the whole time, so what you uncover is the real foil catching the real
/// light, not a picture of it.
///
/// **Scratch, then flip.** Passing the threshold does not just dissolve the rest. The
/// panel finishes clearing, the card turns over in 3D, and it lands as the live hero card.
/// The scratch is the interaction; the flip is the payoff.
struct CardScratchView: View {
    let face: YolkCardFace
    var width: CGFloat = 300
    /// Called once, when the card has finished revealing itself.
    var onRevealed: () -> Void = {}

    /// Strokes the finger has made, in the card's own coordinate space. Kept as separate
    /// strokes rather than one path so lifting and re-touching does not draw a line across
    /// the card between the two places you touched.
    @State private var strokes: [[CGPoint]] = []
    /// Coarse coverage grid. Counting scratched *pixels* would mean reading back the mask
    /// every frame; marking cells is O(1) per touch point and accurate enough to decide
    /// when someone has clearly seen the answer.
    @State private var scratched: Set<Int> = []
    @State private var revealed = false
    @State private var flip: Double = 0
    /// Distance travelled since the last haptic tick, so the texture is a function of how
    /// far the finger has moved rather than how many events arrived.
    @State private var sinceTick: CGFloat = 0
    @State private var lastPoint: CGPoint?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var height: CGFloat { width / YolkCard.aspect }
    private var u: CGFloat { width / 300 }

    /// The brush. Generous on purpose: a thin nib turns this into a chore, and the goal is
    /// for three or four sweeps to be enough.
    private var brush: CGFloat { 46 * u }

    private static let cols = 10
    private static let rows = 14
    /// How much has to come off before it finishes on its own.
    ///
    /// Not 1.0, and not close. Nobody scratches the corners of a real card, and requiring
    /// it would turn a nice moment into hunting for the last unscratched patch. Just over
    /// half is the point where you have unambiguously seen what you got.
    private static let threshold = 0.55

    private var coverage: Double {
        Double(scratched.count) / Double(Self.cols * Self.rows)
    }

    var body: some View {
        ZStack {
            // The real card, at full quality, the whole time. Frozen while it is covered
            // (no point running a gyroscope loop under an opaque panel) and live the
            // moment it is revealed.
            //
            // Frozen FLAT, at zero, not at `posed`. A posed card is rotated in 3D, and its
            // rotated bounds do not line up with an unrotated panel — the foil leaked out
            // past the right edge and along the bottom, which read as the sticker being
            // crooked. Flat under flat, and it picks up real tilt when it goes live.
            YolkCard(face: face, width: width,
                     interactive: revealed,
                     frozenAt: revealed ? nil : .zero)

            if !revealed {
                panel
            }
        }
        .rotation3DEffect(.degrees(flip * 180), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        // The flip's second half would show the card mirrored, so the content is
        // counter-rotated once past the halfway point. Standard card-flip trick: two
        // rotations that cancel, applied to different layers.
        .rotation3DEffect(.degrees(flip >= 0.5 ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .frame(width: width, height: height)
        // `isEnabled:` rather than a ternary to nil. The optional form type-checks but is
        // ambiguous about what it attaches, and this reads as what it means.
        .gesture(scratchGesture, isEnabled: !revealed)
        .onAppear {
            // Reduce Motion gets the card, not a puzzle. Scratching is a motion-based
            // interaction and there is no accessible version of "keep rubbing"; the
            // reasonable accommodation is to skip it.
            if reduceMotion { reveal(animated: false) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(revealed ? "revealed" : "a card to scratch")
        .accessibilityHint("double tap to reveal")
        .accessibilityAction { reveal(animated: !reduceMotion) }
    }

    // MARK: The panel

    private var panel: some View {
        // Flat, matching the card beneath it. A small fixed pose is passed only so the
        // engraving still reads as pressed rather than vanishing at dead zero.
        YolkCardBack(rarity: face.kind == .bond ? nil : face.rarity,
                     width: width, pose: CGPoint(x: -0.12, y: -0.1))
            .overlay { hint }
            .mask(scratchMask)
            .transition(.opacity)
    }

    /// The mask: opaque everywhere, then the strokes punched out of it.
    ///
    /// `destinationOut` inside the `Canvas` is what does the erasing. Drawing the strokes
    /// in white on black and inverting would also work, but this way the shape of the
    /// stroke is the shape of the hole, with the round cap and join for free, which is
    /// what makes it look like a fingertip rather than a rectangle.
    private var scratchMask: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            ctx.blendMode = .destinationOut
            for stroke in strokes {
                guard let first = stroke.first else { continue }
                var path = Path()
                path.move(to: first)
                for p in stroke.dropFirst() { path.addLine(to: p) }
                // A single tap is one point and has no length, so stroking it draws
                // nothing. Give it a dot of its own.
                if stroke.count == 1 {
                    ctx.fill(Path(ellipseIn: CGRect(x: first.x - brush / 2, y: first.y - brush / 2,
                                                    width: brush, height: brush)),
                             with: .color(.white))
                } else {
                    ctx.stroke(path, with: .color(.white),
                               style: StrokeStyle(lineWidth: brush, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    /// Fades out as soon as the first stroke lands, because after that the affordance is
    /// self-evident and a label sitting on top of it is just in the way.
    @ViewBuilder private var hint: some View {
        if strokes.isEmpty {
            VStack(spacing: 6 * u) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 26 * u, weight: .medium))
                Text("scratch it")
                    .font(.system(size: 13 * u, weight: .bold, design: .rounded))
            }
            .foregroundStyle(YolkColor.ink.opacity(0.3))
            .transition(.opacity)
        }
    }

    // MARK: Behaviour

    private var scratchGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                add(value.location)
            }
            .onEnded { _ in
                lastPoint = nil
                if coverage >= Self.threshold { reveal(animated: true) }
            }
    }

    private func add(_ point: CGPoint) {
        // Start a new stroke on first contact, so lifting the finger and touching down
        // somewhere else does not draw a scratch across everything in between.
        if lastPoint == nil { strokes.append([]) }
        strokes[strokes.count - 1].append(point)

        // Grid cell for coverage. Clamped, because a drag can travel outside the card.
        let cx = min(max(Int(point.x / width * CGFloat(Self.cols)), 0), Self.cols - 1)
        let cy = min(max(Int(point.y / height * CGFloat(Self.rows)), 0), Self.rows - 1)
        scratched.insert(cy * Self.cols + cx)

        // Haptic texture, keyed to DISTANCE rather than to event count. Drag events arrive
        // at whatever rate the display runs at, so ticking per event makes a slow careful
        // scratch feel identical to a fast one. Per unit of travel, it feels like paper.
        if let last = lastPoint {
            sinceTick += hypot(point.x - last.x, point.y - last.y)
            if sinceTick > 13 * u {
                sinceTick = 0
                Haptics.shared.tick()
            }
        }
        lastPoint = point

        // Finish as soon as they have clearly seen it, without waiting for them to lift.
        if coverage >= Self.threshold { reveal(animated: true) }
    }

    private func reveal(animated: Bool) {
        guard !revealed else { return }
        guard animated else {
            revealed = true
            onRevealed()
            return
        }
        Haptics.shared.pop()
        // Clear the last of the panel, THEN turn it over. Overlapping the two reads as a
        // glitch: you would see half a scratch panel rotating away.
        withAnimation(.easeOut(duration: 0.22)) { revealed = true }
        withAnimation(.spring(duration: 0.7, bounce: 0.28).delay(0.14)) { flip = 1 }
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            Haptics.shared.reward()
            onRevealed()
        }
    }
}
