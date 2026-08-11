import SwiftUI
import YolklingCore

/// A yolkling as a collectible card — the kind you tilt toward the light.
///
/// The card turns in real 3D toward the phone's own tilt (or your finger), and a foil
/// sheet above the printed surface slides as it moves, lagging behind the card because
/// laminate has mass. The creature sits *under* the foil the way the art window on a
/// trading card does, so it shimmers; the type sits *above* it, because a foil is light
/// landing on the print and light does not land on what is written over it.
///
/// **Rarity is the material.** A common creature is pearl — a fine near-neutral pitch you
/// have to look for. A legendary is cosmos, three star plates at different rates. You can
/// tell them apart across a room without reading a word, which is the entire point of
/// building this rather than printing "LEGENDARY" in gold.
///
/// Everything here is drawn: no image assets, no textures, no data URIs. That is the same
/// bet the creature renderer makes, and it pays the same way — the card is resolution-free,
/// recolours per species for nothing, and adds no bytes to the download.
struct YolkCard: View {
    let face: YolkCardFace
    var width: CGFloat = 300
    /// Off for a card in a grid or a snapshot: no sensor, no gesture, one fixed pose.
    var interactive: Bool = true
    /// Freeze at a specific pose instead of reading motion. Used by the share renderer and
    /// by the grid, where a dozen live gyroscope loops would be absurd.
    var frozenAt: CGPoint? = nil

    @State private var tilt = CardTilt()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A real trading card is 63 × 88 mm. Matching it is most of why this reads as a card
    /// and not as a poster.
    static let aspect: CGFloat = 63.0 / 88.0

    /// A flattering fixed pose: off-centre enough that the material is clearly up, near
    /// enough to the sweet spot that it is catching.
    static let posed = CGPoint(x: -0.34, y: -0.28)

    private var height: CGFloat { width / Self.aspect }
    /// One unit of the card's own scale, so every number below is proportional and the
    /// card is legible at 120pt in a grid and at 340pt full screen.
    private var u: CGFloat { width / 300 }

    private var pose: CGPoint { frozenAt ?? (interactive ? tilt.tilt : Self.posed) }
    private var sheet: CGPoint { frozenAt ?? (interactive ? tilt.sheet : Self.posed) }
    private var material: HoloMaterial { face.material }

    var body: some View {
        surface
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 18 * u, style: .continuous))
            .overlay(edgeCatch)
            .overlay(rim)
            // Two rotations rather than one arbitrary axis: they compose to the same
            // thing, and keeping them separate means the pitch and roll numbers stay
            // readable. Perspective is shallow — a deep one turns a tilt into a fold.
            .rotation3DEffect(.degrees(-pose.y * Holo.maxTilt), axis: (1, 0, 0), perspective: 0.5)
            .rotation3DEffect(.degrees(pose.x * Holo.maxTilt), axis: (0, 1, 0), perspective: 0.5)
            // The shadow moves against the card, so the card reads as lifted off the page
            // rather than painted onto it.
            .shadow(color: .black.opacity(0.18),
                    radius: 22 * u,
                    x: -pose.x * 14 * u, y: 10 * u - pose.y * 10 * u)
            .contentShape(RoundedRectangle(cornerRadius: 18 * u, style: .continuous))
            .gesture(interactive && frozenAt == nil ? drag : nil)
            .onAppear { syncTilt() }
            // `interactive` is not fixed for the life of the card. A scratch card mounts
            // covered and inert, and only becomes live once you have uncovered it — so an
            // `onAppear`-only start ran while `interactive` was still false and the
            // gyroscope never started at all. The card looked frozen after the reveal,
            // which is the one moment it most needs to move.
            .onChange(of: interactive) { _, _ in syncTilt() }
            .onDisappear { tilt.stop() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
    }

    /// Start or stop reading motion to match the card's current state. Idempotent at both
    /// ends (`CardTilt.start` no-ops if already running, `stop` if already stopped), so it
    /// is safe to call from every lifecycle hook that could change the answer.
    private func syncTilt() {
        if interactive, frozenAt == nil {
            tilt.start(reduceMotion: reduceMotion)
        } else {
            tilt.stop()
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { tilt.drag(to: $0.location, in: CGSize(width: width, height: height)) }
            .onEnded { _ in tilt.releaseDrag() }
    }

    // MARK: The stack

    /// Print, then foil, then light, then type. The order *is* the physics.
    private var surface: some View {
        ZStack {
            printedSurface
            revealField
            foilStack
            smear
            sweetSpotFlare
            grain
            glare
            content
        }
        // One group, so every `blendMode` above composites against the accumulated card
        // rather than against whatever happens to be behind the card on screen.
        .compositingGroup()
    }

    // MARK: Print

    /// The card's own print. Fixed for every material — see the note on `HoloMaterial`:
    /// only the foil changes, never the card underneath it.
    private var printedSurface: some View {
        ZStack {
            // A MID-TONE, not a pale one. The first version printed the card at roughly
            // shell white, and every foil layer blew straight out — `overlay` and
            // `colorDodge` against near-white have nowhere to go but whiter, so the whole
            // card became one flat pastel smear with the creature invisible underneath.
            // Foil is light landing on ink; it needs ink to land on.
            LinearGradient(colors: [
                face.vibe.body.opacity(0.92),
                face.vibe.body.opacity(0.66),
                face.vibe.deep.opacity(0.58),
                face.vibe.deep.opacity(0.86),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .background(YolkColor.shell2)

            // A soft vignette so the card has a centre. Without it the print reads as a
            // flat swatch and the foil has nothing to sit on.
            RadialGradient(colors: [.clear, face.vibe.deep.opacity(0.3)],
                           center: .center, startRadius: width * 0.25, endRadius: width * 1.0)
        }
    }

    // MARK: The foil

    private var foilStack: some View {
        let off = Holo.offAxis(sheet)
        let spot = Holo.spot(sheet)
        // A very slow resting cycle at two incommensurate periods, so a still card is not
        // a frozen one and the loop never becomes visible.
        let t = tilt.time
        let breath = 0.5 + 0.5 * sin(t * 0.5) * cos(t * 0.31)

        return ZStack {
            ForEach(Array(material.layers.enumerated()), id: \.offset) { i, layer in
                let travel = material.parallax * layer.rate
                var o = max(0, layer.base + off * layer.gain * (material.bloom / 0.5))
                // The sweet spot lifts every layer at once. That simultaneity is what
                // makes it read as the material *aligning* rather than one sheet getting
                // brighter. Modest, because it multiplies a stack: at the 1.85 this
                // started on, three layers all hit full opacity together and the card
                // whited out at the one angle it was supposed to look best.
                let _ = (o *= 1 + spot * 0.3)
                let _ = (o *= 0.94 + breath * 0.06)

                paint(layer.paint, layer: i)
                    .frame(width: width * layer.scale, height: height * layer.scale)
                    .offset(x: sheet.x * travel * width, y: sheet.y * travel * height)
                    // Collapse the layout size back to the card AFTER drawing oversized.
                    // Without this the ZStack sizes to its largest child — a sheet at 4×
                    // makes the stack 1200pt wide — and every sibling, including the type
                    // and the creature, gets laid out against that and lands off-card.
                    .frame(width: width, height: height)
                    .saturation(layer.saturation)
                    .contrast(layer.contrast)
                    .brightness(layer.brightness)
                    .mask(pool)
                    .opacity(min(1, o))
                    .blendMode(layer.blend)
            }
        }
        .allowsHitTesting(false)
    }

    /// Where the foil is actually catching.
    ///
    /// The first version painted every sheet edge to edge at full strength, and the card
    /// lost its own identity completely: a lilac creature came out as the same rainbow
    /// barcode as a yellow one, because the foil was covering 100% of the print 100% of
    /// the time. Real foil does not do that — it pools where the light strikes and leaves
    /// the rest of the card as printed stock.
    ///
    /// So each layer is masked to a soft pool that rides toward the edge you turned
    /// toward, over a floor that keeps the material faintly present everywhere. The floor
    /// matters: at zero the foil would visibly switch on and off.
    ///
    /// Applied **per layer**, not to the stack. Masking the whole group would force it
    /// into its own compositing pass, and every `overlay` / `colorDodge` in it would then
    /// blend against transparency instead of against the print — which is to say, not at
    /// all.
    private var pool: some View {
        ZStack {
            Color.white.opacity(0.34)
            RadialGradient(colors: [.white, .white.opacity(0.5), .clear],
                           center: UnitPoint(x: Holo.remap(sheet.x, -1, 1, 0.92, 0.08),
                                             y: Holo.remap(sheet.y, -1, 1, 0.92, 0.08)),
                           startRadius: 0, endRadius: width * 1.15)
        }
    }

    @ViewBuilder
    private func paint(_ p: HoloLayer.Paint, layer: Int) -> some View {
        switch p {
        case let .spectrum(angle, cycles, hues):
            let (s, e) = Holo.ends(angle)
            LinearGradient(stops: Holo.stops(hues, cycles: cycles), startPoint: s, endPoint: e)

        case let .conic(hues, spin):
            // A conic wraps the spectrum around a point instead of running it across, so
            // tilting SPINS the colour. Turning the start angle is the equivalent of
            // sliding a linear ramp.
            AngularGradient(gradient: Gradient(colors: hues + [hues[0]]),
                            center: .center,
                            angle: .degrees((sheet.x * 90 + sheet.y * 45) * spin))

        case let .lines(angle, pitch):
            HoloLines(cycles: pitch).rotationEffect(.degrees(angle))

        case let .glitter(count):
            HoloSparkles(count: count, salt: UInt64(0x5A + layer))

        case let .stars(count):
            HoloStars(count: count, salt: UInt64(0xC3 + layer))

        case let .grain(count):
            HoloGrain(count: count, salt: UInt64(0x11 + layer))
        }
    }

    // MARK: The reveal

    /// The marks that are only there when you turn it.
    ///
    /// Not a fade from zero — a **threshold**. Below `from` the card is perfectly clean,
    /// and past it the field ramps in over the remaining travel. That gap is the whole
    /// trick: a decoration that is always faintly visible is just decoration, where one
    /// that is absent and then arrives reads as something the surface was hiding until it
    /// caught the light.
    ///
    /// And it appears only **where the light is**. Revealing the whole field at once was
    /// the obvious first version and it looked wrong: turn the left edge toward you and
    /// marks appeared across the entire card, including the far side that is angled away
    /// and should be catching nothing. So it is masked to a soft pool that rides out
    /// toward the edge you turned, and travels across the card as you move.
    ///
    /// Driven by the **sheet**, not the card: a varnish catching light belongs to the
    /// surface, not to the card's geometry, and reading the fast value made the pool swing
    /// into place before the marks had faded up — two separate things happening.
    private var revealField: some View {
        let from = 0.34
        let soft = Holo.offAxis(sheet)
        let reveal = Holo.smoothstep((soft - from) / (1 - from)) * 0.9

        return HoloSparkles(count: 34, salt: 0x9E, hearts: true)
            .foregroundStyle(face.vibe.accent ?? face.vibe.deep)
            .frame(width: width * 1.15, height: height * 1.15)
            .frame(width: width, height: height)
            .mask(
                RadialGradient(colors: [.white, .white.opacity(0.55), .clear],
                               center: UnitPoint(x: Holo.remap(sheet.x, -1, 1, 0.85, 0.15),
                                                 y: Holo.remap(sheet.y, -1, 1, 0.85, 0.15)),
                               startRadius: 0, endRadius: width * 0.95)
            )
            .opacity(reveal)
            .blendMode(.softLight)
            .allowsHitTesting(false)
    }

    // MARK: Light

    /// A specular highlight. Tracks the input **directly**, with no lag — a highlight is
    /// simply where the light is, so lagging it would look like a mistake.
    private var glare: some View {
        RadialGradient(colors: [.white.opacity(0.55 * material.glare), .clear],
                       center: UnitPoint(x: Holo.remap(pose.x, -1, 1, 0.12, 0.88),
                                         y: Holo.remap(pose.y, -1, 1, 0.12, 0.88)),
                       startRadius: 0, endRadius: width * 0.72)
            .blendMode(.softLight)
            .allowsHitTesting(false)
    }

    /// The flare when the material lines up. Broad, and gone almost everywhere else.
    private var sweetSpotFlare: some View {
        let s = Holo.spot(sheet)
        return RadialGradient(colors: [.white.opacity(0.4), .clear],
                              center: .init(x: 0.42, y: 0.36),
                              startRadius: 0, endRadius: width)
            .opacity(s)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    /// The streak. A fast pass smears the highlight along the direction of travel; a slow
    /// one leaves it round. The clearest read of velocity available, and it costs one
    /// gradient angle plus a length.
    private var smear: some View {
        let v = tilt.velocity
        let angle = atan2(v.y, v.x) * 180 / .pi
        let (s, e) = Holo.ends(angle)
        return LinearGradient(colors: [.clear, .white.opacity(0.5), .clear],
                              startPoint: s, endPoint: e)
            .opacity(min(1, tilt.speed) * 0.5)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    /// Print grain, shared by the whole card, so the type and the creature read as being
    /// on the same piece of stock.
    private var grain: some View {
        HoloGrain(count: 700, salt: 0x7E)
            .opacity(0.07)
            .blendMode(.overlay)
            .allowsHitTesting(false)
    }

    /// Each border lights independently by how much it faces you, so the card reads as
    /// having thickness instead of a uniform rim.
    private var edgeCatch: some View {
        let r = RoundedRectangle(cornerRadius: 18 * u, style: .continuous)
        return ZStack {
            r.trim(from: 0.5, to: 0.75).stroke(.white.opacity(max(0, -pose.x)), lineWidth: 2 * u)
            r.trim(from: 0.0, to: 0.25).stroke(.white.opacity(max(0, pose.x)), lineWidth: 2 * u)
            r.trim(from: 0.75, to: 1.0).stroke(.white.opacity(max(0, -pose.y)), lineWidth: 2 * u)
            r.trim(from: 0.25, to: 0.5).stroke(.white.opacity(max(0, pose.y)), lineWidth: 2 * u)
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    private var rim: some View {
        RoundedRectangle(cornerRadius: 18 * u, style: .continuous)
            .strokeBorder(YolkColor.ink.opacity(0.14), lineWidth: 1)
            .allowsHitTesting(false)
    }

    // MARK: Content

    /// The printed content, above the foil.
    ///
    /// The creature is the exception: it sits in the art window *under* the sheet, which
    /// is exactly where the art sits on a real holo card, and is why turning the card
    /// makes the creature shimmer rather than just its frame.
    private var content: some View {
        VStack(spacing: 0) {
            header
            // The window takes whatever is left rather than a fixed height with a spacer
            // under it. A fixed one left a band of empty print between the art and the
            // stats that read as a layout mistake — and a full-bleed window is what a
            // modern card looks like anyway.
            artWindow
            plate
        }
        .padding(14 * u)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(face.name)
                .font(YolkType.display(21 * u, .heavy))
                .foregroundStyle(YolkColor.ink)
                // EMBOSSING. Highlight on the opposite side to the shadow, both driven by
                // tilt, so the letters catch light as though pressed into the stock. Under
                // a pixel of travel — an emboss you can measure is a bevel.
                .shadow(color: .white.opacity(0.7), radius: 0, x: pose.x * 0.9, y: pose.y * 0.9)
                .shadow(color: .black.opacity(0.22), radius: 0, x: -pose.x * 0.9, y: -pose.y * 0.9)
                .lineLimit(1).minimumScaleFactor(0.6)
            Spacer(minLength: 4 * u)
            cornerMark
        }
    }

    /// Rarity on a found species; "yours" on the one you made.
    ///
    /// A bond card must not print a rarity, and not because the field is empty — because
    /// rarity is a fact about a *species*, and the creature you made is not one. Stamping
    /// "common" on it would say something false about the only card in here that is
    /// actually yours.
    @ViewBuilder private var cornerMark: some View {
        if face.kind == .bond {
            chip(icon: "heart.fill", text: "yours")
        } else {
            chip(icon: rarityIcon, text: face.rarity.rawValue)
        }
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 3 * u) {
            Image(systemName: icon).font(.system(size: 8 * u, weight: .black))
            Text(text)
                .font(.system(size: 9 * u, weight: .black, design: .rounded))
        }
        .foregroundStyle(YolkColor.ink.opacity(0.75))
        .padding(.horizontal, 8 * u).padding(.vertical, 4 * u)
        .background(.white.opacity(0.42), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1))
    }

    private var rarityIcon: String {
        switch face.rarity {
        case .common:    "circle.fill"
        case .rare:      "diamond.fill"
        case .epic:      "star.fill"
        case .legendary: "sparkles"
        case .founding:  "crown.fill"
        }
    }

    /// The art window. Inset and framed, so it reads as a window onto the creature rather
    /// than as the creature floating on the card.
    private var artWindow: some View {
        ZStack {
            // Bright, because the print underneath it is now a real mid-tone. The art
            // window's job on a trading card is to be the one calm place the eye can land.
            RoundedRectangle(cornerRadius: 12 * u, style: .continuous)
                .fill(.white.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 12 * u, style: .continuous)
                        .strokeBorder(.white.opacity(0.55), lineWidth: 1.5 * u)
                )

            YolklingView(vibe: face.vibe, expression: face.expression,
                         size: 118 * u, outfit: face.outfit,
                         frozenAt: interactive && frozenAt == nil ? nil : YolklingView.posedT)
                // The creature drifts very slightly against the card face, so the two
                // planes read as separate depths. A fraction of the foil's travel: enough
                // to separate them, not enough to look detached.
                .offset(x: sheet.x * 5 * u, y: sheet.y * 4 * u)
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, 8 * u)
    }

    /// Species line, flavour, and the stat block.
    ///
    /// On its own scrim. Small type directly over a live foil is unreadable at exactly the
    /// angles the foil is most interesting, and "legible except when the card is doing the
    /// thing it exists to do" is not legible.
    private var plate: some View {
        plateContent
            .padding(.horizontal, 8 * u)
            .padding(.vertical, 7 * u)
            .background(
                RoundedRectangle(cornerRadius: 12 * u, style: .continuous)
                    .fill(.white.opacity(0.5))
            )
    }

    private var plateContent: some View {
        VStack(spacing: 6 * u) {
            if let species = face.species {
                HStack(spacing: 4 * u) {
                    Text(species)
                        .font(.system(size: 12 * u, weight: .bold, design: .rounded))
                        .foregroundStyle(YolkColor.ink.opacity(0.82))
                    if let family = face.family {
                        Text("· \(family)")
                            .font(.system(size: 11 * u, design: .rounded))
                            .foregroundStyle(YolkColor.ink.opacity(0.45))
                    }
                }
                .lineLimit(1).minimumScaleFactor(0.7)
            }

            if let flavour = face.flavour {
                Text(flavour)
                    .font(.system(size: 10 * u, design: .rounded).italic())
                    .foregroundStyle(YolkColor.ink.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }

            if !face.stats.isEmpty {
                Rectangle().fill(YolkColor.ink.opacity(0.1)).frame(height: 1)
                    .padding(.vertical, 2 * u)
                statGrid
            }

            if face.serial != nil || face.dateline != nil {
                HStack {
                    Text(face.serial ?? "")
                    Spacer()
                    Text(face.dateline ?? "")
                }
                .font(.system(size: 8 * u, weight: .medium, design: .monospaced))
                .foregroundStyle(YolkColor.ink.opacity(0.36))
                .padding(.top, 2 * u)
            }
        }
    }

    private var statGrid: some View {
        // Two columns. Four stats is the ceiling the type allows before this stops being
        // glanceable, which is why `Stat` is capped by convention rather than by layout.
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6 * u),
                            GridItem(.flexible(), spacing: 6 * u)], spacing: 5 * u) {
            ForEach(face.stats) { s in
                HStack(spacing: 4 * u) {
                    if let icon = s.icon {
                        Image(systemName: icon)
                            .font(.system(size: 9 * u, weight: .bold))
                            .foregroundStyle(YolkColor.ink.opacity(0.4))
                            .frame(width: 11 * u)
                    }
                    Text(s.label)
                        .font(.system(size: 9 * u, design: .rounded))
                        .foregroundStyle(YolkColor.ink.opacity(0.45))
                    Spacer(minLength: 2 * u)
                    Text(s.value)
                        .font(.system(size: 11 * u, weight: .bold, design: .rounded))
                        .foregroundStyle(YolkColor.ink.opacity(0.8))
                }
                .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
    }

    private var accessibilityText: String {
        var parts = ["\(face.name), a \(face.rarity.rawValue) card"]
        if let s = face.species { parts.append(s) }
        parts.append(contentsOf: face.stats.map { "\($0.label) \($0.value)" })
        return parts.joined(separator: ", ")
    }
}

// MARK: - Drawn plates
//
// Every texture below is a `Canvas` rather than an image. Positions come from the same
// stateless SplitMix64 hash the creature and the rarity aura use, so a plate is identical
// on every device and in every snapshot — which is what lets a card be rendered to a PNG
// for sharing and come out looking like the card on screen.

/// Diffraction ridges. Real foil is iridescent *because* it is physically ridged.
private struct HoloLines: View {
    let cycles: Double

    var body: some View {
        Canvas { ctx, size in
            let period = size.height / cycles
            guard period > 0.4 else { return }
            var y = 0.0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: period * 0.34)),
                         with: .color(.white.opacity(0.5)))
                ctx.fill(Path(CGRect(x: 0, y: y + period * 0.52, width: size.width, height: period * 0.26)),
                         with: .color(.black.opacity(0.2)))
                y += period
            }
        }
        // Rotated as a view rather than in the context, so the canvas stays axis-aligned
        // and the band maths above stays trivial.
        .scaleEffect(1.5)
    }
}

/// Four-point sparkles, scattered. `hearts` swaps in a rounder mark for the reveal field,
/// which wants to read as cute rather than as metal.
private struct HoloSparkles: View {
    let count: Int
    let salt: UInt64
    var hearts: Bool = false

    var body: some View {
        Canvas { ctx, size in
            for i in 0..<count {
                let x = Holo.hash01(i, salt: salt) * size.width
                let y = Holo.hash01(i, salt: salt &+ 1) * size.height
                let r = (hearts ? 3.0 : 2.0) + Holo.hash01(i, salt: salt &+ 2) * (hearts ? 4 : 5)
                let o = 0.45 + Holo.hash01(i, salt: salt &+ 3) * 0.55
                let c = CGPoint(x: x, y: y)
                if hearts && i % 3 == 0 {
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 1.1,
                                                    width: r * 2, height: r * 2.2)),
                             with: .color(.white.opacity(o)))
                } else {
                    ctx.fill(sparkle(at: c, r: r), with: .color(.white.opacity(o)))
                }
            }
        }
    }

    /// A four-point star: four quadratic curves through the centre. Pinched waists are
    /// what make it read as a glint rather than as a diamond.
    private func sparkle(at c: CGPoint, r: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: c)
        p.closeSubpath()
        return p
    }
}

/// A star field. Mostly pinpricks with a few bright ones, because a field of identical
/// dots reads as noise rather than as depth.
private struct HoloStars: View {
    let count: Int
    let salt: UInt64

    var body: some View {
        Canvas { ctx, size in
            for i in 0..<count {
                let x = Holo.hash01(i, salt: salt) * size.width
                let y = Holo.hash01(i, salt: salt &+ 1) * size.height
                let big = Holo.hash01(i, salt: salt &+ 2) > 0.9
                let r = big ? 1.4 + Holo.hash01(i, salt: salt &+ 4) * 0.8
                            : 0.4 + Holo.hash01(i, salt: salt &+ 4) * 0.5
                let o = big ? 0.95 : 0.3 + Holo.hash01(i, salt: salt &+ 3) * 0.5
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                         with: .color(.white.opacity(o)))
            }
        }
    }
}

/// Fine monochrome print grain.
private struct HoloGrain: View {
    let count: Int
    let salt: UInt64

    var body: some View {
        Canvas { ctx, size in
            for i in 0..<count {
                let x = Holo.hash01(i, salt: salt) * size.width
                let y = Holo.hash01(i, salt: salt &+ 1) * size.height
                let g = Holo.hash01(i, salt: salt &+ 2)
                ctx.fill(Path(CGRect(x: x, y: y, width: 1.1, height: 1.1)),
                         with: .color(Color(white: g, opacity: 0.5)))
            }
        }
    }
}
