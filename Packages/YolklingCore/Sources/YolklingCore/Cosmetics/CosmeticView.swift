import SwiftUI

/// Draws one cosmetic, centred on its slot anchor. Built-in items are code;
/// later, `.svg` / `.lottie` kinds render here too (see docs/COSMETICS.md).
/// `size` is the host creature's size; everything is relative to it.
public struct CosmeticView: View {
    public let kind: Cosmetic.Kind
    public var size: CGFloat = 220

    public var body: some View {
        switch kind {
        // spring bloom season
        case .blossomCrown:   blossomCrown
        case .butterflyPerch: butterflyPerch
        case .wateringCan:    wateringCan
        case .petalLashes:    petalLashes
        case .rainCape:       rainCape
        case .cloverChain:    cloverChain

        case .beanie:       beanie
        case .partyHat:     partyHat
        case .gradCap:      gradCap
        case .crown:        crown
        case .flowerCrown:  flowerCrown
        case .chunkyBeanie: chunkyBeanie
        case .catEars:      catEars
        case .bunnyEars:    bunnyEars
        case .bearEars:     bearEars
        case .foxEars:      foxEars
        case .strawberryHat: strawberryHat
        case .mushroomHat:  mushroomHat
        case .santaHat:     santaHat
        case .witchHat:     witchHat
        case .topHat:       topHat
        case .beret:        beret
        case .bowOnHead:    bowOnHead
        case .bobbleHat:    bobbleHat
        case .earflapHat:   earflapHat
        case .leafHat:      leafHat
        case .singleFlower: singleFlower
        case .snowHat:      snowHat
        case .friedEggHat:  friedEggHat
        case .pumpkinHat:   pumpkinHat
        case .acornCap:     acornCap
        case .bucketHat:    bucketHat
        case .cupcakeHat:   cupcakeHat
        case .wizardHat:    wizardHat
        case .chefHat:      chefHat
        case .cowboyHat:    cowboyHat
        case .headphones:   headphones
        case .tiara:        tiara
        case .littleHorns:  littleHorns
        case .softHalo:     softHalo
        case .propellerCap: propellerCap
        case .roundGlasses: glasses(filled: false)
        case .sunglasses:   glasses(filled: true)
        case .starShades:   starShades
        case .roundReadingGlasses: roundReadingGlasses
        case .squareGlasses: squareGlasses
        case .catEyeGlasses: catEyeGlasses
        case .halfMoonGlasses: halfMoonGlasses
        case .heartGlasses: heartGlasses
        case .aviatorSunglasses: aviatorSunglasses
        case .roundSunglasses: roundSunglasses
        case .visorShades:  visorShades
        case .monocle:      monocle
        case .threeDGlasses: threeDGlasses
        case .swimGoggles:  swimGoggles
        case .sleepMask:    sleepMask
        case .dominoMask:   dominoMask
        case .eyepatch:     eyepatch
        case .sparkleEyes:  sparkleEyes
        case .eyebrows:     eyebrows
        case .unibrow:      unibrow
        case .googlyEyes:   googlyEyes
        case .eyeFlower:    eyeFlower
        case .freckles:     freckles
        case .faceGem:      faceGem
        case .bow:          bow(width: size * 0.34)
        case .bowtie:       bow(width: size * 0.22)
        case .scarf:        scarf
        case .knitScarf:    knitScarf
        case .stripedScarf: stripedScarf
        case .chunkyCowl:   chunkyCowl
        case .infinityScarf: infinityScarf
        case .dapperBowtie: dapperBowtie
        case .polkaBowtie:  polkaBowtie
        case .necktie:      necktie
        case .bandana:      bandana
        case .bellCollar:   bellCollar
        case .ruffCollar:   ruffCollar
        case .pearlNecklace: pearlNecklace
        case .pendantNecklace: pendantNecklace
        case .starPendant:  starPendant
        case .flowerLei:    flowerLei
        case .cape:         cape
        case .medalRibbon:  medalRibbon
        case .locket:       locket
        case .babyBib:      babyBib
        case .backpackStrap: backpackStrap
        case .sash:         sash
        }
    }

    // MARK: Hats (origin = top of head)

    private var beanie: some View {
        let w = size * 0.54
        let h = size * 0.3
        let knit = Color(hex: 0xE05A6E)
        return ZStack {
            Ellipse().fill(knit).frame(width: w * 0.94, height: h).offset(y: -h * 0.22)
            Capsule().fill(Color(hex: 0xF2D8DC)).frame(width: w, height: h * 0.3).offset(y: h * 0.06)
            Circle().fill(.white).frame(width: w * 0.18, height: w * 0.18).offset(y: -h * 0.78)
        }
    }

    private var partyHat: some View {
        let w = size * 0.34
        let h = size * 0.42
        return ZStack {
            Triangle().fill(Color(hex: 0x7B5CF0)).frame(width: w, height: h).offset(y: -h * 0.18)
            Circle().fill(Color(hex: 0xFFC23B)).frame(width: w * 0.22, height: w * 0.22).offset(y: -h * 0.7)
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(.white.opacity(0.8))
                    .frame(width: w * 0.12, height: w * 0.12)
                    .offset(y: -h * 0.1 + CGFloat(i) * h * 0.14)
            }
        }
    }

    private var flowerCrown: some View {
        let band = size * 0.52
        return ZStack {
            Capsule().fill(Color(hex: 0x86D38C)).frame(width: band, height: size * 0.05).offset(y: size * 0.02)
            ForEach(0..<3, id: \.self) { i in
                flower.offset(x: CGFloat(i - 1) * band * 0.34, y: -size * 0.02)
            }
        }
    }

    private var flower: some View {
        let petal = size * 0.05
        return ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(Color(hex: 0xFF94C2))
                    .frame(width: petal, height: petal)
                    .offset(y: -petal * 0.6)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle().fill(Color(hex: 0xFFD25A)).frame(width: petal * 0.7, height: petal * 0.7)
        }
    }

    private var gradCap: some View {
        let w = size * 0.5
        let ink = Color(hex: 0x2A241B)
        let gold = Color(hex: 0xFFC23B)
        return ZStack {
            Capsule().fill(ink).frame(width: w * 0.5, height: size * 0.11).offset(y: size * 0.03)   // head cap
            Diamond().fill(ink).frame(width: w, height: w * 0.44).offset(y: -size * 0.02)            // flat board
            Circle().fill(gold).frame(width: size * 0.045, height: size * 0.045).offset(y: -size * 0.02) // button
            Capsule().fill(gold).frame(width: size * 0.014, height: size * 0.13).offset(x: w * 0.3, y: size * 0.04) // tassel cord
            Circle().fill(gold).frame(width: size * 0.05, height: size * 0.05).offset(x: w * 0.3, y: size * 0.11)   // tassel
        }
    }

    private var crown: some View {
        let w = size * 0.46
        let h = size * 0.24
        let gold = Color(hex: 0xFFC23B)
        let deep = Color(hex: 0xE0A02E)
        let gem = Color(hex: 0xFF6FA3)
        return ZStack {
            CrownShape().fill(gold)
                .overlay(CrownShape().stroke(deep, lineWidth: size * 0.008))
                .frame(width: w, height: h)
            Circle().fill(gem).frame(width: size * 0.04, height: size * 0.04).offset(x: -w * 0.33, y: -h * 0.34)
            Circle().fill(gem).frame(width: size * 0.05, height: size * 0.05).offset(y: -h * 0.34)
            Circle().fill(gem).frame(width: size * 0.04, height: size * 0.04).offset(x: w * 0.33, y: -h * 0.34)
        }
    }

    // MARK: Hats batch 1 (docs/cosmetics/hats.md)

    private var chunkyBeanie: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xE8C9A0)).frame(width: size * 0.5, height: size * 0.3).offset(y: -size * 0.06)
            Capsule().fill(Color(hex: 0xD8B488).opacity(0.6)).frame(width: size * 0.04, height: size * 0.22).offset(y: -size * 0.06)
            Capsule().fill(Color(hex: 0xD8B488)).frame(width: size * 0.52, height: size * 0.11).offset(y: size * 0.07)
            Capsule().fill(Color(hex: 0xF0DCC0).opacity(0.7)).frame(width: size * 0.5, height: size * 0.035).offset(y: size * 0.045)
        }
    }

    private var catEars: some View {
        ZStack {
            Triangle().fill(Color(hex: 0x3A3A3A)).frame(width: size * 0.18, height: size * 0.2).offset(x: -size * 0.16, y: -size * 0.02)
            Triangle().fill(Color(hex: 0x3A3A3A)).frame(width: size * 0.18, height: size * 0.2).offset(x: size * 0.16, y: -size * 0.02)
            Triangle().fill(Color(hex: 0xF4A6B8)).frame(width: size * 0.1, height: size * 0.11).offset(x: -size * 0.16, y: 0)
            Triangle().fill(Color(hex: 0xF4A6B8)).frame(width: size * 0.1, height: size * 0.11).offset(x: size * 0.16, y: 0)
        }
    }

    private var bunnyEars: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xFBF3E8)).frame(width: size * 0.1, height: size * 0.34).rotationEffect(.degrees(-8)).offset(x: -size * 0.1, y: -size * 0.14)
            Capsule().fill(Color(hex: 0xFBF3E8)).frame(width: size * 0.1, height: size * 0.34).rotationEffect(.degrees(10)).offset(x: size * 0.1, y: -size * 0.13)
            Capsule().fill(Color(hex: 0xF6C0CE)).frame(width: size * 0.045, height: size * 0.24).rotationEffect(.degrees(-8)).offset(x: -size * 0.1, y: -size * 0.14)
            Capsule().fill(Color(hex: 0xF6C0CE)).frame(width: size * 0.045, height: size * 0.24).rotationEffect(.degrees(10)).offset(x: size * 0.1, y: -size * 0.13)
        }
    }

    private var bearEars: some View {
        ZStack {
            Circle().fill(Color(hex: 0xA9743F)).frame(width: size * 0.2, height: size * 0.2).offset(x: -size * 0.2, y: -size * 0.04)
            Circle().fill(Color(hex: 0xA9743F)).frame(width: size * 0.2, height: size * 0.2).offset(x: size * 0.2, y: -size * 0.04)
            Circle().fill(Color(hex: 0xD7A877)).frame(width: size * 0.1, height: size * 0.1).offset(x: -size * 0.2, y: -size * 0.04)
            Circle().fill(Color(hex: 0xD7A877)).frame(width: size * 0.1, height: size * 0.1).offset(x: size * 0.2, y: -size * 0.04)
        }
    }

    private var foxEars: some View {
        ZStack {
            Triangle().fill(Color(hex: 0xE07B3C)).frame(width: size * 0.16, height: size * 0.26).offset(x: -size * 0.17, y: -size * 0.06)
            Triangle().fill(Color(hex: 0xE07B3C)).frame(width: size * 0.16, height: size * 0.26).offset(x: size * 0.17, y: -size * 0.06)
            Triangle().fill(Color(hex: 0xFBF1E2)).frame(width: size * 0.07, height: size * 0.12).offset(x: -size * 0.17, y: -size * 0.02)
            Triangle().fill(Color(hex: 0xFBF1E2)).frame(width: size * 0.07, height: size * 0.12).offset(x: size * 0.17, y: -size * 0.02)
            Triangle().fill(Color(hex: 0x2A2A2A)).frame(width: size * 0.09, height: size * 0.1).offset(x: -size * 0.17, y: -size * 0.14)
            Triangle().fill(Color(hex: 0x2A2A2A)).frame(width: size * 0.09, height: size * 0.1).offset(x: size * 0.17, y: -size * 0.14)
        }
    }

    private var strawberryHat: some View {
        let seeds: [(CGFloat, CGFloat)] = [(-0.14, 0.02), (-0.05, 0.06), (0.05, 0.04), (0.14, 0.01), (-0.1, -0.06), (0, -0.03), (0.1, -0.05)]
        return ZStack {
            Ellipse().fill(Color(hex: 0xE23B4E)).frame(width: size * 0.46, height: size * 0.34).offset(y: -size * 0.03)
            ForEach(0..<seeds.count, id: \.self) { i in
                Capsule().fill(Color(hex: 0xFCE38A)).frame(width: size * 0.018, height: size * 0.04)
                    .rotationEffect(.degrees(i.isMultiple(of: 2) ? -15 : 15))
                    .offset(x: size * seeds[i].0, y: size * seeds[i].1)
            }
            LeafShape().fill(Color(hex: 0x4FAF63)).frame(width: size * 0.1, height: size * 0.12).rotationEffect(.degrees(-35)).offset(x: -size * 0.06, y: -size * 0.2)
            LeafShape().fill(Color(hex: 0x4FAF63)).frame(width: size * 0.1, height: size * 0.12).offset(y: -size * 0.22)
            LeafShape().fill(Color(hex: 0x4FAF63)).frame(width: size * 0.1, height: size * 0.12).rotationEffect(.degrees(35)).offset(x: size * 0.06, y: -size * 0.2)
            Capsule().fill(Color(hex: 0x3E8E50)).frame(width: size * 0.02, height: size * 0.05).offset(y: -size * 0.26)
        }
    }

    private var mushroomHat: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xF3E7D4)).frame(width: size * 0.56, height: size * 0.09).offset(y: size * 0.07)
            Ellipse().fill(Color(hex: 0xE0463F)).frame(width: size * 0.56, height: size * 0.34).offset(y: -size * 0.05)
            Circle().fill(Color(hex: 0xFBF4E8)).frame(width: size * 0.1, height: size * 0.1).offset(y: -size * 0.1)
            Circle().fill(Color(hex: 0xFBF4E8)).frame(width: size * 0.08, height: size * 0.08).offset(x: -size * 0.16, y: -size * 0.02)
            Circle().fill(Color(hex: 0xFBF4E8)).frame(width: size * 0.08, height: size * 0.08).offset(x: size * 0.16, y: -size * 0.03)
            Circle().fill(Color(hex: 0xFBF4E8)).frame(width: size * 0.06, height: size * 0.06).offset(x: -size * 0.08, y: size * 0.02)
            Circle().fill(Color(hex: 0xFBF4E8)).frame(width: size * 0.06, height: size * 0.06).offset(x: size * 0.1, y: size * 0.01)
        }
    }

    private var santaHat: some View {
        ZStack {
            SantaHatShape().fill(Color(hex: 0xD8323E)).frame(width: size * 0.5, height: size * 0.42).offset(x: size * 0.04, y: -size * 0.14)
            SantaHatShape().fill(Color(hex: 0xB82531).opacity(0.5)).frame(width: size * 0.5, height: size * 0.42).offset(x: size * 0.05, y: -size * 0.13)
            Capsule().fill(Color(hex: 0xFBF6EE)).frame(width: size * 0.52, height: size * 0.12).offset(y: size * 0.06)
            Circle().fill(Color(hex: 0xFBF6EE)).frame(width: size * 0.13, height: size * 0.13).offset(x: size * 0.22, y: -size * 0.26)
        }
    }

    private var witchHat: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x3A2A56)).frame(width: size * 0.64, height: size * 0.14).offset(y: size * 0.08)
            Ellipse().fill(Color(hex: 0x4A3768).opacity(0.7)).frame(width: size * 0.58, height: size * 0.08).offset(y: size * 0.07)
            WitchConeShape().fill(Color(hex: 0x46326A)).frame(width: size * 0.34, height: size * 0.46).offset(y: -size * 0.18)
            Capsule().fill(Color(hex: 0x2A1E40)).frame(width: size * 0.3, height: size * 0.07).offset(y: size * 0.02)
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.01).fill(Color(hex: 0xF4C84A)).frame(width: size * 0.07, height: size * 0.07)
                RoundedRectangle(cornerRadius: size * 0.005).fill(Color(hex: 0x2A1E40)).frame(width: size * 0.035, height: size * 0.035)
            }
            .offset(y: size * 0.02)
        }
    }

    private var topHat: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x1F1B16)).frame(width: size * 0.56, height: size * 0.1).offset(y: size * 0.08)
            Ellipse().fill(Color(hex: 0x3A332A).opacity(0.6)).frame(width: size * 0.5, height: size * 0.05).offset(y: size * 0.075)
            RoundedRectangle(cornerRadius: size * 0.03).fill(Color(hex: 0x26221C)).frame(width: size * 0.32, height: size * 0.36).offset(y: -size * 0.1)
            Ellipse().fill(Color(hex: 0x1F1B16)).frame(width: size * 0.32, height: size * 0.07).offset(y: -size * 0.27)
            Capsule().fill(Color(hex: 0x4A4238).opacity(0.5)).frame(width: size * 0.04, height: size * 0.24).offset(x: -size * 0.08, y: -size * 0.1)
            Capsule().fill(Color(hex: 0xC0394A)).frame(width: size * 0.32, height: size * 0.07).offset(y: size * 0.02)
        }
    }

    private var beret: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xD24B58)).frame(width: size * 0.5, height: size * 0.26).rotationEffect(.degrees(-12)).offset(x: size * 0.04, y: -size * 0.05)
            Ellipse().fill(Color(hex: 0xB83C49).opacity(0.6)).frame(width: size * 0.4, height: size * 0.12).rotationEffect(.degrees(-12)).offset(x: size * 0.06, y: 0)
            Capsule().fill(Color(hex: 0xA83340)).frame(width: size * 0.42, height: size * 0.07).offset(y: size * 0.06)
            Capsule().fill(Color(hex: 0xA83340)).frame(width: size * 0.025, height: size * 0.05).rotationEffect(.degrees(-12)).offset(x: size * 0.04, y: -size * 0.18)
        }
    }

    private var bowOnHead: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xF06A95)).frame(width: size * 0.2, height: size * 0.26).rotationEffect(.degrees(-26)).offset(x: -size * 0.12, y: -size * 0.02)
            Ellipse().fill(Color(hex: 0xF06A95)).frame(width: size * 0.2, height: size * 0.26).rotationEffect(.degrees(26)).offset(x: size * 0.12, y: -size * 0.02)
            Ellipse().fill(Color(hex: 0xD8497A).opacity(0.5)).frame(width: size * 0.1, height: size * 0.16).rotationEffect(.degrees(-26)).offset(x: -size * 0.1, y: 0)
            Ellipse().fill(Color(hex: 0xD8497A).opacity(0.5)).frame(width: size * 0.1, height: size * 0.16).rotationEffect(.degrees(26)).offset(x: size * 0.1, y: 0)
            RoundedRectangle(cornerRadius: size * 0.02).fill(Color(hex: 0xF06A95)).frame(width: size * 0.06, height: size * 0.14).rotationEffect(.degrees(-16)).offset(x: -size * 0.06, y: size * 0.1)
            RoundedRectangle(cornerRadius: size * 0.02).fill(Color(hex: 0xF06A95)).frame(width: size * 0.06, height: size * 0.14).rotationEffect(.degrees(16)).offset(x: size * 0.06, y: size * 0.1)
            Circle().fill(Color(hex: 0xD8497A)).frame(width: size * 0.1, height: size * 0.1).offset(y: -size * 0.02)
        }
    }

    // MARK: Hats batch 2a

    private var bobbleHat: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xD94F6A)).frame(width: size * 0.48, height: size * 0.3).offset(y: -size * 0.05)
            Capsule().fill(Color(hex: 0xC03F58)).frame(width: size * 0.5, height: size * 0.1).offset(y: size * 0.07)
            Circle().fill(Color(hex: 0xFBEFE0)).frame(width: size * 0.16, height: size * 0.16).offset(y: -size * 0.28)
            Circle().fill(Color(hex: 0xE9D7C2).opacity(0.7)).frame(width: size * 0.07, height: size * 0.07).offset(x: size * 0.03, y: -size * 0.25)
        }
    }

    private var earflapHat: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x3FA6A0)).frame(width: size * 0.5, height: size * 0.3).offset(y: -size * 0.05)
            Capsule().fill(Color(hex: 0xF2E6CE)).frame(width: size * 0.52, height: size * 0.1).offset(y: size * 0.06)
            RoundedRectangle(cornerRadius: size * 0.05).fill(Color(hex: 0x3FA6A0)).frame(width: size * 0.12, height: size * 0.2).offset(x: -size * 0.22, y: size * 0.16)
            RoundedRectangle(cornerRadius: size * 0.05).fill(Color(hex: 0x3FA6A0)).frame(width: size * 0.12, height: size * 0.2).offset(x: size * 0.22, y: size * 0.16)
            Circle().fill(Color(hex: 0xF2E6CE)).frame(width: size * 0.1, height: size * 0.1).offset(x: -size * 0.22, y: size * 0.24)
            Circle().fill(Color(hex: 0xF2E6CE)).frame(width: size * 0.1, height: size * 0.1).offset(x: size * 0.22, y: size * 0.24)
            Capsule().fill(Color(hex: 0xE8DCC0)).frame(width: size * 0.02, height: size * 0.1).offset(x: -size * 0.22, y: size * 0.31)
            Capsule().fill(Color(hex: 0xE8DCC0)).frame(width: size * 0.02, height: size * 0.1).offset(x: size * 0.22, y: size * 0.31)
        }
    }

    private var leafHat: some View {
        ZStack {
            LeafShape().fill(Color(hex: 0x5BAE5A)).frame(width: size * 0.5, height: size * 0.34).rotationEffect(.degrees(-10)).offset(y: -size * 0.04)
            Capsule().fill(Color(hex: 0x3C8240)).frame(width: size * 0.012, height: size * 0.3).rotationEffect(.degrees(-10)).offset(y: -size * 0.04)
            Capsule().fill(Color(hex: 0x3C8240)).frame(width: size * 0.016, height: size * 0.06).rotationEffect(.degrees(-10)).offset(x: -size * 0.2, y: size * 0.08)
        }
    }

    private var singleFlower: some View {
        ZStack {
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(.white).frame(width: size * 0.12, height: size * 0.12).offset(y: -size * 0.1).rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Color(hex: 0xFFD25A)).frame(width: size * 0.1, height: size * 0.1)
            }
            .offset(x: -size * 0.16, y: -size * 0.02)
            LeafShape().fill(Color(hex: 0x5BAE5A)).frame(width: size * 0.12, height: size * 0.08).rotationEffect(.degrees(40)).offset(x: -size * 0.02, y: size * 0.04)
        }
    }

    private var snowHat: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xF4FAFF)).frame(width: size * 0.5, height: size * 0.26)
            Ellipse().fill(Color(hex: 0xDCEAF6).opacity(0.7)).frame(width: size * 0.46, height: size * 0.1).offset(y: size * 0.06)
            Circle().fill(Color(hex: 0xF4FAFF)).frame(width: size * 0.16, height: size * 0.16).offset(x: -size * 0.14, y: -size * 0.03)
            Circle().fill(Color(hex: 0xF4FAFF)).frame(width: size * 0.14, height: size * 0.14).offset(x: size * 0.15, y: -size * 0.02)
            StarShape(innerRatio: 0.3).fill(Color(hex: 0xBFE0F5)).frame(width: size * 0.06, height: size * 0.06).offset(x: -size * 0.1, y: -size * 0.2)
            StarShape(innerRatio: 0.3).fill(Color(hex: 0xBFE0F5)).frame(width: size * 0.05, height: size * 0.05).offset(x: size * 0.12, y: -size * 0.16)
        }
    }

    private var friedEggHat: some View {
        ZStack {
            EggWhiteShape().fill(Color(hex: 0xFCFAF2)).frame(width: size * 0.54, height: size * 0.34).offset(y: -size * 0.02)
            EggWhiteShape().fill(Color(hex: 0xECE6D2).opacity(0.5)).frame(width: size * 0.54, height: size * 0.34).offset(y: size * 0.005)
            Circle().fill(Color(hex: 0xFBC02D)).frame(width: size * 0.2, height: size * 0.2).offset(y: -size * 0.04)
            Circle().fill(Color(hex: 0xF4A81E).opacity(0.6)).frame(width: size * 0.16, height: size * 0.16).offset(y: -size * 0.02)
            Circle().fill(.white.opacity(0.85)).frame(width: size * 0.05, height: size * 0.05).offset(x: -size * 0.04, y: -size * 0.08)
        }
    }

    private var pumpkinHat: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xEE8B2E)).frame(width: size * 0.56, height: size * 0.32).offset(y: -size * 0.02)
            Ellipse().fill(Color(hex: 0xD97620).opacity(0.5)).frame(width: size * 0.2, height: size * 0.3).offset(x: -size * 0.14, y: -size * 0.02)
            Ellipse().fill(Color(hex: 0xD97620).opacity(0.5)).frame(width: size * 0.2, height: size * 0.3).offset(x: size * 0.14, y: -size * 0.02)
            Ellipse().fill(Color(hex: 0xFBA64A).opacity(0.6)).frame(width: size * 0.16, height: size * 0.3).offset(y: -size * 0.02)
            RoundedRectangle(cornerRadius: size * 0.02).fill(Color(hex: 0x6E5230)).frame(width: size * 0.08, height: size * 0.1).offset(y: -size * 0.2)
            VineShape().stroke(Color(hex: 0x7A9A45), style: .init(lineWidth: size * 0.018, lineCap: .round)).frame(width: size * 0.12, height: size * 0.12).offset(x: size * 0.08, y: -size * 0.22)
        }
    }

    private var acornCap: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xD9A45E)).frame(width: size * 0.42, height: size * 0.3).offset(y: size * 0.04)
            Ellipse().fill(Color(hex: 0xC28A45).opacity(0.6)).frame(width: size * 0.3, height: size * 0.16).offset(y: size * 0.08)
            AcornCupShape().fill(Color(hex: 0x8A5A2E)).frame(width: size * 0.46, height: size * 0.2).offset(y: -size * 0.04)
            Capsule().fill(Color(hex: 0x5E3E1E)).frame(width: size * 0.022, height: size * 0.06).offset(y: -size * 0.16)
        }
    }

    private var bucketHat: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12).fill(Color(hex: 0x8FAE6A)).frame(width: size * 0.38, height: size * 0.22).offset(y: -size * 0.04)
            Ellipse().fill(Color(hex: 0x9CBC76)).frame(width: size * 0.38, height: size * 0.1).offset(y: -size * 0.12)
            BucketBrimShape().fill(Color(hex: 0x7C9C58)).frame(width: size * 0.6, height: size * 0.16).offset(y: size * 0.08)
            Ellipse().stroke(Color(hex: 0x6A8A48).opacity(0.7), style: .init(lineWidth: size * 0.008, dash: [size * 0.03, size * 0.02])).frame(width: size * 0.5, height: size * 0.12).offset(y: size * 0.06)
        }
    }

    // MARK: Hats batch 2b

    private var cupcakeHat: some View {
        ZStack {
            FlutedLinerShape().fill(Color(hex: 0xF0A03C)).frame(width: size * 0.4, height: size * 0.2).offset(y: size * 0.08)
            FrostingSwirlShape().fill(Color(hex: 0xFF9EC4)).frame(width: size * 0.42, height: size * 0.3).offset(y: -size * 0.08)
            Ellipse().fill(Color(hex: 0xFFC2DC).opacity(0.8)).frame(width: size * 0.12, height: size * 0.06).offset(x: -size * 0.06, y: -size * 0.12)
            Circle().fill(Color(hex: 0xD63A52)).frame(width: size * 0.1, height: size * 0.1).offset(y: -size * 0.24)
            Circle().fill(.white.opacity(0.8)).frame(width: size * 0.03, height: size * 0.03).offset(x: -size * 0.02, y: -size * 0.26)
            Capsule().fill(Color(hex: 0x6E8F3E)).frame(width: size * 0.014, height: size * 0.05).rotationEffect(.degrees(18)).offset(x: size * 0.02, y: -size * 0.3)
            Capsule().fill(Color(hex: 0x7BD0F0)).frame(width: size * 0.012, height: size * 0.035).rotationEffect(.degrees(-30)).offset(x: -size * 0.1, y: -size * 0.06)
            Capsule().fill(Color(hex: 0xFFE27A)).frame(width: size * 0.012, height: size * 0.035).rotationEffect(.degrees(25)).offset(x: size * 0.08, y: -size * 0.1)
            Capsule().fill(Color(hex: 0x9EE6A0)).frame(width: size * 0.012, height: size * 0.035).rotationEffect(.degrees(60)).offset(x: size * 0.12, y: -size * 0.04)
        }
    }

    private var wizardHat: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x2A2E58)).frame(width: size * 0.6, height: size * 0.12).offset(y: size * 0.09)
            WitchConeShape().fill(Color(hex: 0x33386E)).frame(width: size * 0.36, height: size * 0.54).offset(y: -size * 0.22)
            WitchConeShape().fill(Color(hex: 0x262A52).opacity(0.5)).frame(width: size * 0.36, height: size * 0.54).offset(x: size * 0.02, y: -size * 0.21)
            CrescentShape().fill(Color(hex: 0xFBD24A), style: FillStyle(eoFill: true)).frame(width: size * 0.08, height: size * 0.08).offset(x: size * 0.02, y: -size * 0.04)
            StarShape(innerRatio: 0.42).fill(Color(hex: 0xFBD24A)).frame(width: size * 0.1, height: size * 0.1).offset(x: size * 0.06, y: -size * 0.44)
            StarShape(innerRatio: 0.42).fill(Color(hex: 0xFBD24A)).frame(width: size * 0.07, height: size * 0.07).offset(x: -size * 0.05, y: -size * 0.12)
            StarShape(innerRatio: 0.42).fill(Color(hex: 0xFBD24A)).frame(width: size * 0.05, height: size * 0.05).offset(x: size * 0.05, y: -size * 0.24)
            StarShape(innerRatio: 0.42).fill(Color(hex: 0xFBD24A)).frame(width: size * 0.045, height: size * 0.045).offset(x: -size * 0.07, y: -size * 0.32)
        }
    }

    private var chefHat: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xFBFBF8)).frame(width: size * 0.42, height: size * 0.12).offset(y: size * 0.06)
            Capsule().fill(Color(hex: 0xE6E6E0).opacity(0.7)).frame(width: size * 0.008, height: size * 0.1).offset(x: -size * 0.12, y: size * 0.06)
            Capsule().fill(Color(hex: 0xE6E6E0).opacity(0.7)).frame(width: size * 0.008, height: size * 0.1).offset(x: -size * 0.04, y: size * 0.06)
            Capsule().fill(Color(hex: 0xE6E6E0).opacity(0.7)).frame(width: size * 0.008, height: size * 0.1).offset(x: size * 0.04, y: size * 0.06)
            Capsule().fill(Color(hex: 0xE6E6E0).opacity(0.7)).frame(width: size * 0.008, height: size * 0.1).offset(x: size * 0.12, y: size * 0.06)
            CloudShape().fill(.white).frame(width: size * 0.5, height: size * 0.34).offset(y: -size * 0.1)
            Ellipse().fill(Color(hex: 0xECECE4).opacity(0.6)).frame(width: size * 0.4, height: size * 0.08)
        }
    }

    private var cowboyHat: some View {
        ZStack {
            CowboyBrimShape().fill(Color(hex: 0xC8924E)).frame(width: size * 0.72, height: size * 0.18).offset(y: size * 0.06)
            CowboyBrimShape().stroke(Color(hex: 0xA9762F), lineWidth: size * 0.01).frame(width: size * 0.72, height: size * 0.18).offset(y: size * 0.06)
            CowboyCrownShape().fill(Color(hex: 0xD49C56)).frame(width: size * 0.34, height: size * 0.26).offset(y: -size * 0.08)
            Capsule().fill(Color(hex: 0x8A5A2E)).frame(width: size * 0.34, height: size * 0.05)
            RoundedRectangle(cornerRadius: size * 0.006).fill(Color(hex: 0xF0C24A)).frame(width: size * 0.04, height: size * 0.03).offset(x: size * 0.1)
        }
    }

    private var headphones: some View {
        ZStack {
            ArcBandShape().stroke(Color(hex: 0x3A3F4A), style: .init(lineWidth: size * 0.05, lineCap: .round)).frame(width: size * 0.5, height: size * 0.3).offset(y: -size * 0.02)
            ArcBandShape().stroke(Color(hex: 0x586070), style: .init(lineWidth: size * 0.018, lineCap: .round)).frame(width: size * 0.5, height: size * 0.3).offset(y: -size * 0.025)
            RoundedRectangle(cornerRadius: size * 0.06).fill(Color(hex: 0x3A3F4A)).frame(width: size * 0.14, height: size * 0.18).offset(x: -size * 0.24, y: size * 0.06)
            RoundedRectangle(cornerRadius: size * 0.06).fill(Color(hex: 0x3A3F4A)).frame(width: size * 0.14, height: size * 0.18).offset(x: size * 0.24, y: size * 0.06)
            Ellipse().fill(Color(hex: 0xE66B8A)).frame(width: size * 0.08, height: size * 0.12).offset(x: -size * 0.22, y: size * 0.06)
            Ellipse().fill(Color(hex: 0xE66B8A)).frame(width: size * 0.08, height: size * 0.12).offset(x: size * 0.22, y: size * 0.06)
        }
    }

    private var tiara: some View {
        ZStack {
            TiaraShape().fill(Color(hex: 0xE9EEF4)).frame(width: size * 0.46, height: size * 0.2).offset(y: size * 0.02)
            TiaraShape().stroke(Color(hex: 0xB9C4D2), lineWidth: size * 0.006).frame(width: size * 0.46, height: size * 0.2).offset(y: size * 0.02)
            TeardropShape().fill(Color(hex: 0x7EC8F0)).frame(width: size * 0.07, height: size * 0.1).offset(y: -size * 0.06)
            Circle().fill(Color(hex: 0xF39ED0)).frame(width: size * 0.045, height: size * 0.045).offset(x: -size * 0.15, y: -size * 0.04)
            Circle().fill(Color(hex: 0xF39ED0)).frame(width: size * 0.045, height: size * 0.045).offset(x: size * 0.15, y: -size * 0.04)
            StarShape(innerRatio: 0.4).fill(.white.opacity(0.9)).frame(width: size * 0.03, height: size * 0.03).offset(x: -size * 0.08)
            StarShape(innerRatio: 0.4).fill(.white.opacity(0.9)).frame(width: size * 0.03, height: size * 0.03).offset(x: size * 0.08)
        }
    }

    private var littleHorns: some View {
        ZStack {
            HornShape().fill(Color(hex: 0xD85A5A)).frame(width: size * 0.1, height: size * 0.2).rotationEffect(.degrees(-14)).offset(x: -size * 0.13, y: -size * 0.08)
            HornShape().fill(Color(hex: 0xD85A5A)).frame(width: size * 0.1, height: size * 0.2).scaleEffect(x: -1).rotationEffect(.degrees(14)).offset(x: size * 0.13, y: -size * 0.08)
            Ellipse().fill(Color(hex: 0xBE4747)).frame(width: size * 0.06, height: size * 0.03).offset(x: -size * 0.13, y: size * 0.01)
            Ellipse().fill(Color(hex: 0xBE4747)).frame(width: size * 0.06, height: size * 0.03).offset(x: size * 0.13, y: size * 0.01)
        }
    }

    private var softHalo: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xFFE9A0).opacity(0.35)).frame(width: size * 0.4, height: size * 0.16).blur(radius: size * 0.03).offset(y: -size * 0.24)
            Ellipse().stroke(Color(hex: 0xFBD24A), lineWidth: size * 0.04).frame(width: size * 0.34, height: size * 0.12).offset(y: -size * 0.24)
            Ellipse().stroke(Color(hex: 0xFFF0BE).opacity(0.8), lineWidth: size * 0.014).frame(width: size * 0.34, height: size * 0.12).offset(y: -size * 0.245)
            StarShape(innerRatio: 0.38).fill(.white.opacity(0.9)).frame(width: size * 0.045, height: size * 0.045).offset(x: size * 0.14, y: -size * 0.2)
            StarShape(innerRatio: 0.38).fill(.white.opacity(0.9)).frame(width: size * 0.03, height: size * 0.03).offset(x: -size * 0.13, y: -size * 0.28)
        }
    }

    private var propellerCap: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x3FA0E0)).frame(width: size * 0.46, height: size * 0.28).offset(y: -size * 0.02)
            Capsule().fill(Color(hex: 0x2C7CB8).opacity(0.5)).frame(width: size * 0.01, height: size * 0.24).offset(x: -size * 0.12, y: -size * 0.02)
            Capsule().fill(Color(hex: 0x2C7CB8).opacity(0.5)).frame(width: size * 0.01, height: size * 0.24).offset(y: -size * 0.02)
            Capsule().fill(Color(hex: 0x2C7CB8).opacity(0.5)).frame(width: size * 0.01, height: size * 0.24).offset(x: size * 0.12, y: -size * 0.02)
            Capsule().fill(Color(hex: 0xE55B5B)).frame(width: size * 0.5, height: size * 0.06).offset(y: size * 0.08)
            Circle().fill(Color(hex: 0xE55B5B)).frame(width: size * 0.07, height: size * 0.07).offset(y: -size * 0.16)
            PropellerBladeShape().fill(Color(hex: 0xE55B5B)).frame(width: size * 0.34, height: size * 0.06).offset(y: -size * 0.18)
            PropellerBladeShape().fill(Color(hex: 0xF2C03C)).frame(width: size * 0.34, height: size * 0.06).rotationEffect(.degrees(90)).offset(y: -size * 0.18)
            Circle().fill(Color(hex: 0x2A241B)).frame(width: size * 0.04, height: size * 0.04).offset(y: -size * 0.18)
        }
    }

    // MARK: Eyes (origin = eye line)

    private func glasses(filled: Bool) -> some View {
        let lens = size * 0.22
        let dx = size * 0.2
        let frame = Color(hex: 0x2A241B)
        return ZStack {
            Rectangle().fill(frame).frame(width: dx * 0.7, height: size * 0.022)
            lensView(filled: filled, lens: lens, frame: frame).offset(x: -dx)
            lensView(filled: filled, lens: lens, frame: frame).offset(x: dx)
        }
    }

    @ViewBuilder
    private func lensView(filled: Bool, lens: CGFloat, frame: Color) -> some View {
        if filled {
            Circle().fill(frame.opacity(0.85)).frame(width: lens, height: lens)
        } else {
            Circle().stroke(frame, lineWidth: size * 0.022).frame(width: lens, height: lens)
        }
    }

    private var starShades: some View {
        let dx = size * 0.2
        let pink = Color(hex: 0xFF6FA3)
        return ZStack {
            Rectangle().fill(Color(hex: 0x2A241B)).frame(width: dx * 0.7, height: size * 0.022)
            star(pink).offset(x: -dx)
            star(pink).offset(x: dx)
        }
    }

    private func star(_ c: Color) -> some View {
        StarShape(innerRatio: 0.42).fill(c)
            .overlay(StarShape(innerRatio: 0.42).stroke(.white.opacity(0.55), lineWidth: size * 0.006))
            .frame(width: size * 0.26, height: size * 0.26)
    }

    // MARK: Eyes (docs/cosmetics/eyes.md)

    private var roundReadingGlasses: some View {
        let ink = Color(hex: 0x2A241B)
        return ZStack {
            Rectangle().fill(ink).frame(width: size * 0.14, height: size * 0.022)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    Rectangle().fill(ink).frame(width: size * 0.06, height: size * 0.018).rotationEffect(.degrees(s * 8)).offset(x: s * size * 0.11, y: -size * 0.01)
                    Circle().stroke(ink, lineWidth: size * 0.022).frame(width: size * 0.22, height: size * 0.22)
                    Ellipse().fill(.white.opacity(0.45)).frame(width: size * 0.05, height: size * 0.035).offset(x: -size * 0.05, y: -size * 0.05)
                }
                .offset(x: s * size * 0.2)
            }
        }
    }

    private var squareGlasses: some View {
        let ink = Color(hex: 0x2A241B)
        return ZStack {
            Rectangle().fill(ink).frame(width: size * 0.13, height: size * 0.022).offset(y: -size * 0.02)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.03).stroke(ink, lineWidth: size * 0.022).frame(width: size * 0.24, height: size * 0.19)
                    Capsule().fill(.white.opacity(0.4)).frame(width: size * 0.02, height: size * 0.07).rotationEffect(.degrees(22)).offset(x: -s * size * 0.04, y: -size * 0.04)
                }
                .offset(x: s * size * 0.2)
            }
        }
    }

    private var catEyeGlasses: some View {
        let ink = Color(hex: 0x2A241B)
        func lens(_ flip: CGFloat) -> some View {
            ZStack {
                CatEyeLens().fill(Color(hex: 0xF4A6C0).opacity(0.25))
                CatEyeLens().stroke(ink, lineWidth: size * 0.022)
            }
            .frame(width: size * 0.22, height: size * 0.16).scaleEffect(x: flip)
        }
        return ZStack {
            Rectangle().fill(ink).frame(width: size * 0.14, height: size * 0.022).offset(y: -size * 0.01)
            lens(-1).offset(x: -size * 0.2)
            lens(1).offset(x: size * 0.2)
        }
    }

    private var halfMoonGlasses: some View {
        let gold = Color(hex: 0xC9962E)
        return ZStack {
            Rectangle().fill(gold).frame(width: size * 0.12, height: size * 0.018).offset(y: size * 0.02)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    HalfMoonLens().fill(.white.opacity(0.18))
                    HalfMoonLens().stroke(gold, lineWidth: size * 0.02)
                }
                .frame(width: size * 0.2, height: size * 0.11).offset(x: s * size * 0.2, y: size * 0.02)
            }
        }
    }

    private var heartGlasses: some View {
        let pink = Color(hex: 0xE0567E)
        return ZStack {
            Rectangle().fill(pink).frame(width: size * 0.1, height: size * 0.02)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    HeartShape().fill(Color(hex: 0xFF8FB3).opacity(0.55))
                    HeartShape().stroke(pink, lineWidth: size * 0.02)
                }
                .frame(width: size * 0.22, height: size * 0.2).offset(x: s * size * 0.2)
            }
            StarShape(innerRatio: 0.4).fill(.white.opacity(0.7)).frame(width: size * 0.05, height: size * 0.05).offset(x: -size * 0.16, y: -size * 0.03)
        }
    }

    private var aviatorSunglasses: some View {
        let gold = Color(hex: 0xC9962E)
        return ZStack {
            Capsule().fill(gold).frame(width: size * 0.1, height: size * 0.016).offset(y: -size * 0.04)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.06).fill(LinearGradient(colors: [Color(hex: 0x3A4A66), Color(hex: 0x1E2738)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.24, height: size * 0.2)
                    RoundedRectangle(cornerRadius: size * 0.06).stroke(gold, lineWidth: size * 0.014).frame(width: size * 0.24, height: size * 0.2)
                    Capsule().fill(.white.opacity(0.35)).frame(width: size * 0.02, height: size * 0.08).rotationEffect(.degrees(28)).offset(x: -s * size * 0.05, y: -size * 0.04)
                }
                .offset(x: s * size * 0.2)
            }
        }
    }

    private var roundSunglasses: some View {
        let ink = Color(hex: 0x2A241B)
        return ZStack {
            Rectangle().fill(ink).frame(width: size * 0.14, height: size * 0.022)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(hex: 0x5B3A8C), Color(hex: 0x2A1B45)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.22, height: size * 0.22)
                    Circle().stroke(ink, lineWidth: size * 0.018).frame(width: size * 0.22, height: size * 0.22)
                    Ellipse().fill(.white.opacity(0.3)).frame(width: size * 0.06, height: size * 0.04).offset(x: -s * size * 0.04, y: -size * 0.05)
                }
                .offset(x: s * size * 0.2)
            }
        }
    }

    private var visorShades: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF7A59), Color(hex: 0xE03A6E)], startPoint: .leading, endPoint: .trailing)).frame(width: size * 0.56, height: size * 0.2)
            Capsule().fill(Color(hex: 0x2A241B)).frame(width: size * 0.58, height: size * 0.04).offset(y: -size * 0.09)
            Capsule().fill(.white.opacity(0.3)).frame(width: size * 0.04, height: size * 0.13).rotationEffect(.degrees(24)).offset(x: -size * 0.14, y: -size * 0.01)
            Capsule().fill(.white.opacity(0.2)).frame(width: size * 0.025, height: size * 0.1).rotationEffect(.degrees(24)).offset(x: -size * 0.05)
        }
    }

    private var monocle: some View {
        let gold = Color(hex: 0xC9962E)
        return ZStack {
            Circle().fill(.white.opacity(0.12)).frame(width: size * 0.22, height: size * 0.22).offset(x: size * 0.2)
            Circle().stroke(gold, lineWidth: size * 0.024).frame(width: size * 0.22, height: size * 0.22).offset(x: size * 0.2)
            Ellipse().fill(.white.opacity(0.5)).frame(width: size * 0.05, height: size * 0.035).offset(x: size * 0.25, y: -size * 0.05)
            Circle().fill(gold).frame(width: size * 0.02, height: size * 0.02).offset(x: size * 0.29, y: size * 0.12)
            Circle().fill(gold).frame(width: size * 0.02, height: size * 0.02).offset(x: size * 0.31, y: size * 0.18)
            Circle().fill(gold).frame(width: size * 0.02, height: size * 0.02).offset(x: size * 0.34, y: size * 0.24)
        }
    }

    private var threeDGlasses: some View {
        let ink = Color(hex: 0x2A241B)
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.03).fill(Color(hex: 0xE0383C).opacity(0.7)).frame(width: size * 0.24, height: size * 0.16).offset(x: -size * 0.2)
            RoundedRectangle(cornerRadius: size * 0.03).fill(Color(hex: 0x2E78D6).opacity(0.7)).frame(width: size * 0.24, height: size * 0.16).offset(x: size * 0.2)
            RoundedRectangle(cornerRadius: size * 0.04).stroke(ink, lineWidth: size * 0.02).frame(width: size * 0.56, height: size * 0.2)
            Rectangle().fill(ink).frame(width: size * 0.018, height: size * 0.2)
        }
    }

    private var swimGoggles: some View {
        let blue = Color(hex: 0x2E9CC4)
        return ZStack {
            Capsule().fill(blue).frame(width: size * 0.62, height: size * 0.035).offset(y: -size * 0.02)
            Capsule().fill(blue).frame(width: size * 0.1, height: size * 0.03)
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    Circle().fill(Color(hex: 0x7FD7E8).opacity(0.5)).frame(width: size * 0.22, height: size * 0.22)
                    Circle().stroke(blue, lineWidth: size * 0.03).frame(width: size * 0.22, height: size * 0.22)
                    Ellipse().fill(.white.opacity(0.55)).frame(width: size * 0.06, height: size * 0.04).offset(x: -s * size * 0.04, y: -size * 0.05)
                }
                .offset(x: s * size * 0.2)
            }
        }
    }

    private var sleepMask: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x7E63B8)).frame(width: size * 0.62, height: size * 0.03).offset(y: -size * 0.08)
            Capsule().fill(Color(hex: 0x9B7FD4)).frame(width: size * 0.58, height: size * 0.22)
            Capsule().fill(Color(hex: 0xB9A3E6).opacity(0.6)).frame(width: size * 0.5, height: size * 0.06).offset(y: -size * 0.04)
            Capsule().fill(Color(hex: 0x3A2F5A)).frame(width: size * 0.08, height: size * 0.012).offset(x: -size * 0.2, y: size * 0.01)
            Capsule().fill(Color(hex: 0x3A2F5A)).frame(width: size * 0.08, height: size * 0.012).offset(x: size * 0.2, y: size * 0.01)
            Capsule().fill(.white.opacity(0.7)).frame(width: size * 0.04, height: size * 0.012).rotationEffect(.degrees(-20)).offset(x: size * 0.16, y: -size * 0.06)
            Capsule().fill(.white.opacity(0.7)).frame(width: size * 0.03, height: size * 0.01).rotationEffect(.degrees(-20)).offset(x: size * 0.2, y: -size * 0.1)
        }
    }

    private var dominoMask: some View {
        let red = Color(hex: 0xE0383C)
        return ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.1).fill(red).frame(width: size * 0.6, height: size * 0.24)
                Ellipse().fill(.black).frame(width: size * 0.18, height: size * 0.13).offset(x: -size * 0.2).blendMode(.destinationOut)
                Ellipse().fill(.black).frame(width: size * 0.18, height: size * 0.13).offset(x: size * 0.2).blendMode(.destinationOut)
            }
            .compositingGroup()
            RoundedRectangle(cornerRadius: size * 0.1).stroke(Color(hex: 0xA81F22), lineWidth: size * 0.012).frame(width: size * 0.6, height: size * 0.24)
            Triangle().fill(red).frame(width: size * 0.1, height: size * 0.08).rotationEffect(.degrees(-15)).offset(x: -size * 0.28, y: -size * 0.08)
            Triangle().fill(red).frame(width: size * 0.1, height: size * 0.08).rotationEffect(.degrees(15)).offset(x: size * 0.28, y: -size * 0.08)
        }
    }

    private var eyepatch: some View {
        let ink = Color(hex: 0x2A241B)
        return ZStack {
            Capsule().fill(ink).frame(width: size * 0.64, height: size * 0.025).rotationEffect(.degrees(-6)).offset(y: -size * 0.04)
            RoundedRectangle(cornerRadius: size * 0.05).fill(ink).frame(width: size * 0.22, height: size * 0.24).offset(x: -size * 0.2)
            Capsule().fill(Color(hex: 0x4A4036).opacity(0.6)).frame(width: size * 0.03, height: size * 0.12).rotationEffect(.degrees(18)).offset(x: -size * 0.2)
        }
    }

    private var sparkleEyes: some View {
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { s in
                ZStack {
                    Ellipse().fill(LinearGradient(colors: [Color(hex: 0x6FB8FF), Color(hex: 0x2E5FC4)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.18, height: size * 0.22)
                    Ellipse().stroke(Color(hex: 0x1E3E8A), lineWidth: size * 0.01).frame(width: size * 0.18, height: size * 0.22)
                    Circle().fill(.white).frame(width: size * 0.07, height: size * 0.07).offset(x: -s * size * 0.03, y: -size * 0.05)
                    Circle().fill(.white).frame(width: size * 0.035, height: size * 0.035).offset(x: s * size * 0.03, y: size * 0.03)
                    StarShape(innerRatio: 0.35).fill(.white.opacity(0.9)).frame(width: size * 0.05, height: size * 0.05).offset(x: -s * size * 0.05, y: -size * 0.08)
                }
                .offset(x: s * size * 0.2)
            }
            StarShape(innerRatio: 0.35).fill(.white.opacity(0.9)).frame(width: size * 0.035, height: size * 0.035).offset(y: -size * 0.14)
        }
    }

    private var eyebrows: some View {
        let brown = Color(hex: 0x5A3D2B)
        return ZStack {
            Capsule().fill(brown).frame(width: size * 0.18, height: size * 0.04).rotationEffect(.degrees(10)).offset(x: -size * 0.2, y: -size * 0.16)
            Capsule().fill(brown).frame(width: size * 0.18, height: size * 0.04).rotationEffect(.degrees(-10)).offset(x: size * 0.2, y: -size * 0.16)
        }
    }

    private var unibrow: some View {
        let brown = Color(hex: 0x4A3322)
        let dark = Color(hex: 0x3A2618)
        return ZStack {
            Capsule().fill(brown).frame(width: size * 0.5, height: size * 0.045).offset(y: -size * 0.16)
            Capsule().fill(brown).frame(width: size * 0.16, height: size * 0.06).offset(y: -size * 0.17)
            Capsule().fill(dark).frame(width: size * 0.02, height: size * 0.05).offset(x: -size * 0.1, y: -size * 0.19)
            Capsule().fill(dark).frame(width: size * 0.02, height: size * 0.05).offset(y: -size * 0.19)
            Capsule().fill(dark).frame(width: size * 0.02, height: size * 0.05).offset(x: size * 0.1, y: -size * 0.19)
        }
    }

    private var googlyEyes: some View {
        func eye(_ px: CGFloat, _ py: CGFloat) -> some View {
            ZStack {
                Circle().fill(.white).frame(width: size * 0.2, height: size * 0.2)
                Circle().stroke(Color(hex: 0xD8D2C8), lineWidth: size * 0.006).frame(width: size * 0.2, height: size * 0.2)
                Circle().fill(Color(hex: 0x1A1714)).frame(width: size * 0.09, height: size * 0.09).offset(x: px, y: py)
            }
        }
        return ZStack {
            eye(size * 0.02, size * 0.03).offset(x: -size * 0.2)
            eye(-size * 0.03, -size * 0.02).offset(x: size * 0.2)
        }
    }

    private var eyeFlower: some View {
        ZStack {
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(Color(hex: 0xFF94C2)).frame(width: size * 0.09, height: size * 0.09).offset(y: -size * 0.07).rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Color(hex: 0xFFD25A)).frame(width: size * 0.07, height: size * 0.07)
            }
            .offset(x: -size * 0.2, y: -size * 0.04)
            Triangle().fill(Color(hex: 0x86D38C)).frame(width: size * 0.06, height: size * 0.08).rotationEffect(.degrees(-30)).offset(x: -size * 0.27, y: size * 0.04)
        }
    }

    private var freckles: some View {
        let c = Color(hex: 0xC97A4A)
        let dots: [(CGFloat, CGFloat, CGFloat)] = [(-0.04, 0.0, 0.022), (0.0, 0.03, 0.026), (0.03, -0.02, 0.018), (-0.01, 0.06, 0.02)]
        return ZStack {
            ForEach(0..<dots.count, id: \.self) { i in
                Circle().fill(c).frame(width: size * dots[i].2, height: size * dots[i].2).offset(x: -size * 0.22 + size * dots[i].0, y: size * 0.06 + size * dots[i].1)
                Circle().fill(c).frame(width: size * dots[i].2, height: size * dots[i].2).offset(x: size * 0.22 - size * dots[i].0, y: size * 0.06 + size * dots[i].1)
            }
        }
    }

    private var faceGem: some View {
        ZStack {
            Diamond().fill(LinearGradient(colors: [Color(hex: 0xFF6FA3), Color(hex: 0xC23E78)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.07, height: size * 0.1).offset(y: -size * 0.1)
            Capsule().fill(.white.opacity(0.5)).frame(width: size * 0.012, height: size * 0.06).offset(y: -size * 0.1)
            StarShape(innerRatio: 0.3).fill(.white.opacity(0.9)).frame(width: size * 0.05, height: size * 0.05).offset(x: size * 0.03, y: -size * 0.13)
            Circle().fill(Color(hex: 0xFFD25A)).frame(width: size * 0.018, height: size * 0.018).offset(x: -size * 0.05, y: -size * 0.06)
            Circle().fill(Color(hex: 0xFFD25A)).frame(width: size * 0.018, height: size * 0.018).offset(x: size * 0.05, y: -size * 0.06)
        }
    }

    // MARK: Neck (origin = lower body)

    private func bow(width w: CGFloat) -> some View {
        let loop = Color(hex: 0xE0567E)
        return ZStack {
            Ellipse().fill(loop).frame(width: w * 0.55, height: w * 0.72)
                .rotationEffect(.degrees(-28)).offset(x: -w * 0.26)
            Ellipse().fill(loop).frame(width: w * 0.55, height: w * 0.72)
                .rotationEffect(.degrees(28)).offset(x: w * 0.26)
            Circle().fill(Color(hex: 0xC23E63)).frame(width: w * 0.24, height: w * 0.24)
        }
    }

    /// A wrapped scarf.
    ///
    /// The previous version was a plain capsule at y = 0 with a rectangular tail and a
    /// circle for a knot. At thumbnail size that passes; on the card, where the creature
    /// is drawn at 118pt, it read as a blue plank laid across the belly with a stick
    /// hanging off it. Two things were wrong and both are worth keeping fixed:
    ///
    /// 1. **It sat too low.** Every other neck piece offsets up (`necktie` -0.08,
    ///    `bandana` -0.06); this one sat on the centre line, which on a round body is the
    ///    middle of the stomach rather than a neck.
    /// 2. **It had no thickness.** A single flat capsule cannot read as cloth. The wrap is
    ///    now two capsules, the back one darker and a shade lower, so there is an under-
    ///    edge — the same trick the creature's own body uses to look round.
    private var scarf: some View {
        let col = Color(hex: 0x5FA9E0)
        let shade = Color(hex: 0x4A8CC2)
        // Slim. The original was 0.56 x 0.10, against a necktie's 0.3 x 0.05 and a bell
        // collar's 0.34 — nearly double the weight of anything else in the slot, which is
        // why it read as a plank rather than as cloth however it was positioned.
        let band = size * 0.42
        let bandH = size * 0.072
        let neck = -size * 0.05
        return ZStack {
            // The tail is drawn FIRST so the band lands on top of it. That overlap is
            // what reads as a knot — an explicit circle for one turned the whole piece
            // into a keyhole, and a gap between tail and band turned it into a figure
            // with legs. Cloth emerging from under cloth needs neither.
            TieBlade().fill(shade)
                .frame(width: size * 0.068, height: size * 0.17)
                .rotationEffect(.degrees(6))
                .offset(x: size * 0.125, y: neck + size * 0.085)

            // The wrap: an under-edge peeking below the front, so it has thickness.
            Capsule().fill(shade)
                .frame(width: band, height: bandH)
                .offset(y: neck + size * 0.012)
            Capsule().fill(col)
                .frame(width: band, height: bandH * 0.86)
                .offset(y: neck)
        }
    }

    // MARK: Neck batch (docs/cosmetics/neck.md)

    private var knitScarf: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xC56B7A)).frame(width: size * 0.58, height: size * 0.11).offset(y: -size * 0.01)
            ForEach([-1.0, 0.0, 1.0], id: \.self) { s in
                Capsule().stroke(Color(hex: 0xA8525F), lineWidth: size * 0.012).frame(width: size * 0.02, height: size * 0.1).offset(x: s * size * 0.14, y: -size * 0.01)
            }
            RoundedRectangle(cornerRadius: size * 0.03).fill(Color(hex: 0xC56B7A)).frame(width: size * 0.11, height: size * 0.2).offset(x: size * 0.14, y: size * 0.15)
            Circle().fill(Color(hex: 0xB25C6A)).frame(width: size * 0.12, height: size * 0.12).offset(x: size * 0.14, y: size * 0.005)
        }
    }

    private var stripedScarf: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xE86A6A)).frame(width: size * 0.58, height: size * 0.1).offset(y: -size * 0.01)
                .overlay(
                    ZStack {
                        ForEach([-0.18, -0.06, 0.06, 0.18], id: \.self) { x in
                            Capsule().fill(Color(hex: 0xF7F0E2)).frame(width: size * 0.045, height: size * 0.13).rotationEffect(.degrees(28)).offset(x: size * x, y: -size * 0.01)
                        }
                    }
                    .clipShape(Capsule())
                )
            RoundedRectangle(cornerRadius: size * 0.025).fill(Color(hex: 0xE86A6A)).frame(width: size * 0.09, height: size * 0.16).offset(x: -size * 0.12, y: size * 0.13)
            RoundedRectangle(cornerRadius: size * 0.025).fill(Color(hex: 0xE86A6A)).frame(width: size * 0.09, height: size * 0.16).offset(x: size * 0.12, y: size * 0.16)
        }
    }

    private var chunkyCowl: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xF3E4CC), Color(hex: 0xE3D0B2)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.62, height: size * 0.34).offset(y: size * 0.02)
            ForEach([-0.2, -0.1, 0.0, 0.1, 0.2], id: \.self) { x in
                Capsule().stroke(Color(hex: 0xD8C29E), lineWidth: size * 0.012).frame(width: size * 0.02, height: size * 0.24).rotationEffect(.degrees(x * 60)).offset(x: size * x, y: size * 0.04)
            }
            Ellipse().fill(Color(hex: 0xD8C29E)).frame(width: size * 0.4, height: size * 0.16).offset(y: -size * 0.05)
        }
    }

    private var infinityScarf: some View {
        ZStack {
            Ellipse().stroke(Color(hex: 0x7FB3A3), lineWidth: size * 0.05).frame(width: size * 0.34, height: size * 0.22).offset(y: size * 0.06)
            Ellipse().stroke(Color(hex: 0x9BC9BA), lineWidth: size * 0.05).frame(width: size * 0.5, height: size * 0.2).offset(y: -size * 0.05)
            Capsule().fill(Color(hex: 0x7FB3A3)).frame(width: size * 0.14, height: size * 0.07).rotationEffect(.degrees(35)).offset(x: size * 0.02)
        }
    }

    private var dapperBowtie: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x3E5C8A)).frame(width: size * 0.13, height: size * 0.17).rotationEffect(.degrees(-28)).offset(x: -size * 0.06)
            Ellipse().fill(Color(hex: 0x3E5C8A)).frame(width: size * 0.13, height: size * 0.17).rotationEffect(.degrees(28)).offset(x: size * 0.06)
            Capsule().fill(Color(hex: 0x2E466B)).frame(width: size * 0.05, height: size * 0.09)
        }
    }

    private var polkaBowtie: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xE06A8C)).frame(width: size * 0.14, height: size * 0.18).rotationEffect(.degrees(-28)).offset(x: -size * 0.065)
            Ellipse().fill(Color(hex: 0xE06A8C)).frame(width: size * 0.14, height: size * 0.18).rotationEffect(.degrees(28)).offset(x: size * 0.065)
            Circle().fill(Color(hex: 0xFBE9EF)).frame(width: size * 0.028, height: size * 0.028).offset(x: -size * 0.085, y: -size * 0.02)
            Circle().fill(Color(hex: 0xFBE9EF)).frame(width: size * 0.028, height: size * 0.028).offset(x: -size * 0.05, y: size * 0.02)
            Circle().fill(Color(hex: 0xFBE9EF)).frame(width: size * 0.028, height: size * 0.028).offset(x: size * 0.085, y: -size * 0.02)
            Circle().fill(Color(hex: 0xFBE9EF)).frame(width: size * 0.028, height: size * 0.028).offset(x: size * 0.05, y: size * 0.02)
            Circle().fill(Color(hex: 0xC8557A)).frame(width: size * 0.07, height: size * 0.07)
        }
    }

    private var necktie: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xF4ECDD)).frame(width: size * 0.3, height: size * 0.05).offset(y: -size * 0.08)
            Diamond().fill(Color(hex: 0x9B3F4E)).frame(width: size * 0.1, height: size * 0.1).offset(y: -size * 0.04)
            TieBlade().fill(Color(hex: 0xB24A5B)).frame(width: size * 0.13, height: size * 0.26).offset(y: size * 0.13)
            Capsule().fill(Color(hex: 0x8A3644)).frame(width: size * 0.1, height: size * 0.018).rotationEffect(.degrees(-18)).offset(y: size * 0.06)
        }
    }

    private var bandana: some View {
        ZStack {
            Triangle().fill(Color(hex: 0xD85B5B)).rotationEffect(.degrees(180)).frame(width: size * 0.42, height: size * 0.24).offset(y: size * 0.05)
            ForEach(Array([(-0.1, 0.02), (0.0, 0.04), (0.1, 0.02), (-0.05, 0.1), (0.05, 0.1)].enumerated()), id: \.offset) { _, pt in
                Circle().fill(Color(hex: 0xF6E7C9)).frame(width: size * 0.025, height: size * 0.025).offset(x: size * pt.0, y: size * pt.1)
            }
            Capsule().fill(Color(hex: 0xC24E4E)).frame(width: size * 0.34, height: size * 0.05).offset(y: -size * 0.06)
            Circle().fill(Color(hex: 0xA84141)).frame(width: size * 0.07, height: size * 0.07).offset(y: -size * 0.06)
        }
    }

    private var bellCollar: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xE0567E)).frame(width: size * 0.54, height: size * 0.06).offset(y: -size * 0.02)
            RoundedRectangle(cornerRadius: size * 0.01).stroke(Color(hex: 0xC9C2B4), lineWidth: size * 0.012).frame(width: size * 0.05, height: size * 0.05).offset(x: -size * 0.12, y: -size * 0.02)
            Circle().fill(LinearGradient(colors: [Color(hex: 0xFFD25A), Color(hex: 0xE0A02E)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.11, height: size * 0.11).offset(y: size * 0.06)
            Capsule().fill(Color(hex: 0xC98E1E)).frame(width: size * 0.06, height: size * 0.014).offset(y: size * 0.09)
            Circle().fill(Color(hex: 0xFFF0C0)).frame(width: size * 0.025, height: size * 0.025).offset(x: -size * 0.02, y: size * 0.04)
        }
    }

    private var ruffCollar: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xF7F0E6)).frame(width: size * 0.44, height: size * 0.22).offset(y: size * 0.02)
            ForEach(0..<12, id: \.self) { i in
                let a = Double(i) / 12 * 2 * .pi
                Circle().fill(Color(hex: 0xF7F0E6)).overlay(Circle().stroke(Color(hex: 0xE4D8C4), lineWidth: size * 0.007))
                    .frame(width: size * 0.072, height: size * 0.072)
                    .offset(x: CGFloat(cos(a)) * size * 0.21, y: size * 0.02 + CGFloat(sin(a)) * size * 0.11)
            }
            ForEach(0..<8, id: \.self) { i in
                Capsule().stroke(Color(hex: 0xE4D8C4), lineWidth: size * 0.007).frame(width: size * 0.012, height: size * 0.09).rotationEffect(.degrees(Double(i) * 45)).offset(y: size * 0.02)
            }
            Ellipse().fill(Color(hex: 0xE8DCC8)).frame(width: size * 0.24, height: size * 0.11).offset(y: -size * 0.02)
        }
    }

    private var pearlNecklace: some View {
        let pts: [(CGFloat, CGFloat)] = [(-0.18, -0.01), (-0.12, 0.015), (-0.06, 0.03), (0, 0.04), (0.06, 0.03), (0.12, 0.015), (0.18, -0.01)]
        return ZStack {
            // a soft cord ties the strand together so it reads on any background
            ChainArc().stroke(Color(hex: 0xC9B89A), lineWidth: size * 0.008).frame(width: size * 0.4, height: size * 0.12).offset(y: -size * 0.004)
            ForEach(0..<pts.count, id: \.self) { i in
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xFFFDF8), Color(hex: 0xDED1DE)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().stroke(Color(hex: 0xB4A286), lineWidth: size * 0.009))
                    .frame(width: size * 0.056, height: size * 0.056)
                    .offset(x: size * pts[i].0, y: size * pts[i].1)
                Circle().fill(.white).frame(width: size * 0.018, height: size * 0.018).offset(x: size * pts[i].0 - size * 0.013, y: size * pts[i].1 - size * 0.013)
            }
        }
    }

    private var pendantNecklace: some View {
        ZStack {
            ChainArc().stroke(Color(hex: 0xE3B23C), lineWidth: size * 0.012).frame(width: size * 0.36, height: size * 0.12).offset(y: -size * 0.01)
            Circle().stroke(Color(hex: 0xE3B23C), lineWidth: size * 0.01).frame(width: size * 0.035, height: size * 0.035).offset(y: size * 0.04)
            HeartShape().fill(LinearGradient(colors: [Color(hex: 0xFF8FB0), Color(hex: 0xE0567E)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.11, height: size * 0.1).offset(y: size * 0.1)
            Circle().fill(Color(hex: 0xFFD7E3)).frame(width: size * 0.02, height: size * 0.02).offset(x: -size * 0.02, y: size * 0.08)
        }
    }

    private var starPendant: some View {
        ZStack {
            ChainArc().stroke(Color(hex: 0xC9C2B4), lineWidth: size * 0.012).frame(width: size * 0.36, height: size * 0.12).offset(y: -size * 0.01)
            Circle().stroke(Color(hex: 0xC9C2B4), lineWidth: size * 0.01).frame(width: size * 0.035, height: size * 0.035).offset(y: size * 0.04)
            StarShape(innerRatio: 0.45).fill(LinearGradient(colors: [Color(hex: 0xFFE08A), Color(hex: 0xE0A02E)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.14, height: size * 0.14).offset(y: size * 0.11)
            StarShape(innerRatio: 0.3).fill(.white).frame(width: size * 0.03, height: size * 0.03).offset(x: size * 0.04, y: size * 0.06)
        }
    }

    private var flowerLei: some View {
        let pts: [(CGFloat, CGFloat)] = [(-0.2, -0.02), (-0.14, 0.04), (-0.07, 0.08), (0, 0.1), (0.07, 0.08), (0.14, 0.04), (0.2, -0.02)]
        let cols: [UInt] = [0xFF94C2, 0xFFC6DD, 0xFFE08A]
        return ZStack {
            ChainArc().stroke(Color(hex: 0x86D38C), lineWidth: size * 0.02).frame(width: size * 0.5, height: size * 0.22).offset(y: size * 0.02)
            ForEach(0..<pts.count, id: \.self) { f in
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        Circle().fill(Color(hex: cols[f % 3])).frame(width: size * 0.04, height: size * 0.04).offset(y: -size * 0.024).rotationEffect(.degrees(Double(i) * 72))
                    }
                    Circle().fill(Color(hex: 0xFFD25A)).frame(width: size * 0.025, height: size * 0.025)
                }
                .offset(x: size * pts[f].0, y: size * pts[f].1)
            }
        }
    }

    private var cape: some View {
        // Drawn behind the body (see Cosmetic.Kind.rendersBehindBody), so it is widened
        // past the body so the fabric shows on both sides and flares below the feet.
        ZStack {
            CapeShape().fill(LinearGradient(colors: [Color(hex: 0x7B3FA0), Color(hex: 0x5C2E7D)], startPoint: .top, endPoint: .bottom)).frame(width: size * 1.08, height: size * 0.6).offset(y: size * 0.12)
            CapeShape().fill(Color(hex: 0xB98FD6)).frame(width: size * 0.82, height: size * 0.44).offset(y: size * 0.14)
            // gold collar clasp, riding at the top of the cape behind the shoulders
            Capsule().fill(Color(hex: 0xE0A02E)).frame(width: size * 0.3, height: size * 0.016).offset(y: -size * 0.12)
            Circle().fill(LinearGradient(colors: [Color(hex: 0xFFD25A), Color(hex: 0xE0A02E)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.07, height: size * 0.07).offset(x: -size * 0.16, y: -size * 0.12)
            Circle().fill(LinearGradient(colors: [Color(hex: 0xFFD25A), Color(hex: 0xE0A02E)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.07, height: size * 0.07).offset(x: size * 0.16, y: -size * 0.12)
        }
    }

    private var medalRibbon: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x4A7FC0)).frame(width: size * 0.05, height: size * 0.2).rotationEffect(.degrees(18)).offset(x: -size * 0.06, y: -size * 0.04)
            Capsule().fill(Color(hex: 0x3E6BA8)).frame(width: size * 0.05, height: size * 0.2).rotationEffect(.degrees(-18)).offset(x: size * 0.06, y: -size * 0.04)
            Circle().fill(LinearGradient(colors: [Color(hex: 0xFFE08A), Color(hex: 0xE0A02E)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.16, height: size * 0.16).offset(y: size * 0.1)
            Circle().stroke(Color(hex: 0xC98E1E), lineWidth: size * 0.012).frame(width: size * 0.11, height: size * 0.11).offset(y: size * 0.1)
            StarShape(innerRatio: 0.45).fill(Color(hex: 0xC98E1E)).frame(width: size * 0.08, height: size * 0.08).offset(y: size * 0.1)
        }
    }

    private var locket: some View {
        ZStack {
            ChainArc().stroke(Color(hex: 0xE3B23C), lineWidth: size * 0.012).frame(width: size * 0.32, height: size * 0.1).offset(y: -size * 0.02)
            Ellipse().fill(LinearGradient(colors: [Color(hex: 0xF4C95A), Color(hex: 0xD49A2A)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.13, height: size * 0.16).offset(y: size * 0.11)
            Capsule().fill(Color(hex: 0xC98E1E)).frame(width: size * 0.11, height: size * 0.008).offset(y: size * 0.11)
            HeartShape().stroke(Color(hex: 0xC98E1E), lineWidth: size * 0.008).frame(width: size * 0.06, height: size * 0.055).offset(y: size * 0.09)
        }
    }

    private var babyBib: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.1).fill(Color(hex: 0xA7D8E8)).frame(width: size * 0.42, height: size * 0.34).offset(y: size * 0.1)
            ForEach([-0.15, -0.05, 0.05, 0.15], id: \.self) { x in
                Circle().fill(Color(hex: 0xA7D8E8)).overlay(Circle().stroke(Color(hex: 0x88C2D6), lineWidth: size * 0.008)).frame(width: size * 0.08, height: size * 0.08).offset(x: size * x, y: size * 0.24)
            }
            HeartShape().fill(Color(hex: 0xF08FB0)).frame(width: size * 0.12, height: size * 0.11).offset(y: size * 0.12)
            Capsule().fill(Color(hex: 0x88C2D6)).frame(width: size * 0.04, height: size * 0.07).rotationEffect(.degrees(-20)).offset(x: -size * 0.16, y: -size * 0.04)
            Capsule().fill(Color(hex: 0x88C2D6)).frame(width: size * 0.04, height: size * 0.07).rotationEffect(.degrees(20)).offset(x: size * 0.16, y: -size * 0.04)
        }
    }

    private var backpackStrap: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xE0A24A)).frame(width: size * 0.07, height: size * 0.42).rotationEffect(.degrees(12)).offset(x: -size * 0.13, y: size * 0.06)
            Capsule().fill(Color(hex: 0xE0A24A)).frame(width: size * 0.07, height: size * 0.42).rotationEffect(.degrees(-12)).offset(x: size * 0.13, y: size * 0.06)
            Capsule().fill(Color(hex: 0xC2842F)).frame(width: size * 0.24, height: size * 0.04).offset(y: size * 0.04)
            RoundedRectangle(cornerRadius: size * 0.008).fill(Color(hex: 0x6B4A1F)).frame(width: size * 0.05, height: size * 0.05).offset(y: size * 0.04)
        }
    }

    private var sash: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [Color(hex: 0xC0405A), Color(hex: 0x9B2E47)], startPoint: .leading, endPoint: .trailing)).frame(width: size * 0.66, height: size * 0.13).rotationEffect(.degrees(-30)).offset(x: size * 0.02, y: size * 0.04)
            Capsule().stroke(Color(hex: 0xFFD25A), lineWidth: size * 0.01).frame(width: size * 0.6, height: size * 0.09).rotationEffect(.degrees(-30)).offset(x: size * 0.02, y: size * 0.04)
            RoundedRectangle(cornerRadius: size * 0.015).fill(Color(hex: 0x9B2E47)).frame(width: size * 0.05, height: size * 0.16).offset(x: -size * 0.21, y: size * 0.24)
            RoundedRectangle(cornerRadius: size * 0.015).fill(Color(hex: 0x9B2E47)).frame(width: size * 0.05, height: size * 0.16).offset(x: -size * 0.11, y: size * 0.24)
            StarShape(innerRatio: 0.7).fill(Color(hex: 0xFFD25A)).frame(width: size * 0.16, height: size * 0.16).offset(x: -size * 0.16, y: size * 0.14)
            Circle().fill(Color(hex: 0xC0405A)).frame(width: size * 0.07, height: size * 0.07).offset(x: -size * 0.16, y: size * 0.14)
            Circle().fill(Color(hex: 0xFFD25A)).frame(width: size * 0.03, height: size * 0.03).offset(x: -size * 0.16, y: size * 0.14)
        }
    }
}

/// A simple upward triangle for the party hat.
private struct Triangle: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A flat diamond, the mortarboard top of the grad cap.
private struct Diamond: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// A little three-point crown: a band with peaks and valleys.
private struct CrownShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 3
        let step = r.width / CGFloat(n)
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        for i in 0..<n {
            let x0 = r.minX + CGFloat(i) * step
            p.addLine(to: CGPoint(x: x0 + step * 0.5, y: r.minY))
            p.addLine(to: CGPoint(x: x0 + step, y: r.midY))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A pointed leaf (two arcs meeting at top and bottom tips).
private struct LeafShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.maxX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// A cone that curves and droops to one side (the Santa hat).
private struct SantaHatShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.05, y: r.minY + r.height * 0.25), control: CGPoint(x: r.maxX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.05), control: CGPoint(x: r.maxX - r.width * 0.02, y: r.minY + r.height * 0.12))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.15, y: r.minY + r.height * 0.4), control: CGPoint(x: r.maxX - r.width * 0.3, y: r.minY + r.height * 0.15))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// A tall, slightly bent cone (witch + wizard hats).
private struct WitchConeShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX + r.width * 0.08, y: r.minY), control: CGPoint(x: r.maxX - r.width * 0.05, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.minX + r.width * 0.05, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// An irregular soft blob, wider than tall (fried-egg white).
private struct EggWhiteShape: Shape {
    public func path(in r: CGRect) -> Path {
        let c = CGPoint(x: r.midX, y: r.midY)
        let rx = r.width * 0.5, ry = r.height * 0.5
        let mult: [CGFloat] = [1.0, 0.85, 1.05, 0.95, 1.1, 0.8]
        var pts: [CGPoint] = []
        for i in 0..<6 {
            let a = Double(i) * 60 * .pi / 180
            pts.append(CGPoint(x: c.x + CGFloat(cos(a)) * rx * mult[i], y: c.y + CGFloat(sin(a)) * ry * mult[i]))
        }
        var p = Path()
        p.move(to: pts[0])
        for i in 0..<6 {
            let next = pts[(i + 1) % 6]
            let mid = CGPoint(x: (pts[i].x + next.x) / 2, y: (pts[i].y + next.y) / 2)
            let push = CGPoint(x: c.x + (mid.x - c.x) * 1.08, y: c.y + (mid.y - c.y) * 1.08)
            p.addQuadCurve(to: next, control: push)
        }
        p.closeSubpath()
        return p
    }
}

/// A small open curl (pumpkin vine), stroked.
private struct VineShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.3), control1: CGPoint(x: r.midX, y: r.maxY), control2: CGPoint(x: r.maxX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX + r.width * 0.2, y: r.minY), control1: CGPoint(x: r.maxX, y: r.minY), control2: CGPoint(x: r.midX + r.width * 0.3, y: r.minY))
        return p
    }
}

/// A dome with a scalloped lower rim (the acorn cup).
private struct AcornCupShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.1))
        let n = 5
        let rimY = r.midY + r.height * 0.1
        let step = r.width / CGFloat(n)
        var x = r.maxX
        for _ in 0..<n {
            let nx = x - step
            p.addQuadCurve(to: CGPoint(x: nx, y: rimY), control: CGPoint(x: (x + nx) / 2, y: r.maxY))
            x = nx
        }
        p.closeSubpath()
        return p
    }
}

/// A downward-sloping ring brim (front dips lower than the sides) for the bucket hat.
private struct BucketBrimShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: w * 0.25, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: w * 0.75, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.3), control: CGPoint(x: w * 0.75, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: w * 0.25, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// The cupcake paper liner: a trapezoid with a scalloped bottom edge.
private struct FlutedLinerShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        let bottomY = r.maxY - r.height * 0.15
        p.move(to: CGPoint(x: r.minX + r.width * 0.12, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: bottomY))
        let n = 5
        let step = r.width / CGFloat(n)
        var x = r.maxX
        for _ in 0..<n {
            let nx = x - step
            p.addQuadCurve(to: CGPoint(x: nx, y: bottomY), control: CGPoint(x: (x + nx) / 2, y: r.maxY))
            x = nx
        }
        p.closeSubpath()
        return p
    }
}

/// A soft piped-frosting mound that tapers to a small peak.
private struct FrostingSwirlShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.1, y: r.minY + h * 0.45), control: CGPoint(x: r.maxX, y: r.minY + h * 0.55))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.12, y: r.minY + h * 0.18), control: CGPoint(x: r.maxX - w * 0.18, y: r.minY + h * 0.18))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.12, y: r.minY + h * 0.18), control: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.1, y: r.minY + h * 0.45), control: CGPoint(x: r.minX + w * 0.18, y: r.minY + h * 0.18))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.minX, y: r.minY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

/// A puffy cloud with bumps along the top (chef-hat puff).
private struct CloudShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.22, y: r.minY + h * 0.25), control: CGPoint(x: r.maxX + w * 0.02, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.1), control: CGPoint(x: r.maxX - w * 0.3, y: r.minY - h * 0.05))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.22, y: r.minY + h * 0.25), control: CGPoint(x: r.minX + w * 0.3, y: r.minY - h * 0.05))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.minX - w * 0.02, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// A wide flat brim whose left and right edges curl upward (cowboy hat).
private struct CowboyBrimShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX + w * 0.05, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: w * 0.25, y: r.maxY + h * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.05, y: r.midY), control: CGPoint(x: w * 0.75, y: r.maxY + h * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.2), control: CGPoint(x: w * 0.75, y: r.minY - h * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.05, y: r.midY), control: CGPoint(x: w * 0.25, y: r.minY - h * 0.1))
        p.closeSubpath()
        return p
    }
}

/// A rounded crown with a centre pinch on top (cowboy hat).
private struct CowboyCrownShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.18, y: r.minY + h * 0.1), control: CGPoint(x: r.minX, y: r.minY + h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.35), control: CGPoint(x: r.midX - w * 0.1, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.18, y: r.minY + h * 0.1), control: CGPoint(x: r.midX + w * 0.1, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.minY + h * 0.2))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A half-ring arc over the head (headphones band), stroked.
private struct ArcBandShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.2))
        return p
    }
}

/// A gentle band that rises into three soft points (tiara), centre tallest.
private struct TiaraShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.22, y: r.midY), control: CGPoint(x: r.minX + w * 0.1, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.1, y: r.midY + h * 0.1), control: CGPoint(x: r.minX + w * 0.22, y: r.maxY - h * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.midX - w * 0.05, y: r.minY + h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.1, y: r.midY + h * 0.1), control: CGPoint(x: r.midX + w * 0.05, y: r.minY + h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.22, y: r.midY), control: CGPoint(x: r.maxX - w * 0.22, y: r.maxY - h * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.maxX - w * 0.1, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.midX, y: r.maxY - h * 0.06))
        p.closeSubpath()
        return p
    }
}

/// A teardrop gem, point down, round top.
private struct TeardropShape: Shape {
    public func path(in r: CGRect) -> Path {
        let h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.3), control: CGPoint(x: r.minX, y: r.maxY - h * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.3), control: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY - h * 0.2))
        p.closeSubpath()
        return p
    }
}

/// A short cone that curves outward with a rounded tip (little horns). Left horn; mirror for right.
private struct HornShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.maxY + h * 0.06))
        p.addQuadCurve(to: CGPoint(x: r.midX + w * 0.15, y: r.minY + h * 0.1), control: CGPoint(x: r.maxX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX - w * 0.15, y: r.minY + h * 0.1), control: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY), control: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// Two tapered blades from a centre hub (propeller). Caller rotates a copy 90 deg.
private struct PropellerBladeShape: Shape {
    public func path(in r: CGRect) -> Path {
        let h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.midY - h * 0.5), control: CGPoint(x: r.width * 0.25, y: r.midY - h * 0.4))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.width * 0.75, y: r.midY - h * 0.4))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.midY + h * 0.5), control: CGPoint(x: r.width * 0.75, y: r.midY + h * 0.4))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: r.width * 0.25, y: r.midY + h * 0.4))
        p.closeSubpath()
        return p
    }
}

/// A crescent moon (wizard hat), drawn as two arcs and filled even-odd.
private struct CrescentShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.midY), radius: r.width * 0.5, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        p.addArc(center: CGPoint(x: r.midX + r.width * 0.28, y: r.midY), radius: r.width * 0.42, startAngle: .degrees(360), endAngle: .degrees(0), clockwise: true)
        return p
    }
}

/// A heart (heart glasses, and reusable).
private struct HeartShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.midX - w * 0.1, y: r.maxY - h * 0.1),
                   control2: CGPoint(x: r.minX, y: r.midY))
        p.addArc(center: CGPoint(x: r.minX + w * 0.25, y: r.minY + h * 0.28), radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: r.maxX - w * 0.25, y: r.minY + h * 0.28), radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.midY),
                   control2: CGPoint(x: r.midX + w * 0.1, y: r.maxY - h * 0.1))
        p.closeSubpath()
        return p
    }
}

/// An upswept cat-eye lens (point at the right side; mirror for the other eye).
private struct CatEyeLens: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - w * 0.1, y: r.minY - h * 0.28), control: CGPoint(x: r.maxX + w * 0.1, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY), control: CGPoint(x: r.midX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// The bottom half of a circle (half-moon reading glasses), flat edge on top.
private struct HalfMoonLens: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 1.6))
        p.closeSubpath()
        return p
    }
}

/// A shallow downward arc (necklace chain / garland vine), stroked not filled.
private struct ChainArc: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 1.4))
        return p
    }
}

/// A draped cape: narrow at the shoulders, flaring with a wavy hem.
private struct CapeShape: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width
        var p = Path()
        p.move(to: CGPoint(x: r.minX + w * 0.28, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.28, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY * 0.92))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.midX + w * 0.25, y: r.maxY * 0.86))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY * 0.92), control: CGPoint(x: r.midX - w * 0.25, y: r.maxY * 0.86))
        p.closeSubpath()
        return p
    }
}

/// The hanging blade of a necktie, coming to a downward point.
private struct TieBlade: Shape {
    public func path(in r: CGRect) -> Path {
        let w = r.width
        var p = Path()
        p.move(to: CGPoint(x: r.midX - w * 0.32, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + w * 0.32, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY * 0.72))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY * 0.72))
        p.closeSubpath()
        return p
    }
}
