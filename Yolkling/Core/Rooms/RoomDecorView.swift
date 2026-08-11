import SwiftUI
import YolklingCore

/// Draws a single room decor piece into the frame it is given (`pw` x `ph`). All
/// shapes are pure SwiftUI vectors, offsets/sizes are fractions of the piece frame.
/// RoomView sizes + positions the frame; this only fills it. See docs/rooms/decor.md.
struct RoomDecorView: View {
    let kind: RoomDecor.Kind

    var body: some View {
        GeometryReader { geo in
            let pw = geo.size.width
            let ph = geo.size.height
            piece(pw, ph).frame(width: pw, height: ph)
        }
    }

    @ViewBuilder private func piece(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        switch kind {
        case .posterSun:      posterSun(pw, ph)
        case .wallClock:      wallClock(pw, ph)
        case .pennantGarland: garland(pw, ph)
        case .bookshelf:      bookshelf(pw, ph)
        case .cozyBed:        cozyBed(pw, ph)
        case .beanbag:        beanbag(pw, ph)
        case .woodStool:      stool(pw, ph)
        case .cactus:         cactus(pw, ph)
        case .mushroom:       mushroom(pw, ph)
        case .flowerVase:     vase(pw, ph)
        case .tableLamp:      lamp(pw, ph)
        case .candle:         candle(pw, ph)
        case .balloonBunch:   balloons(pw, ph)
        case .toyChest:       toyChest(pw, ph)
        case .framedPhotos:   framedPhotos(pw, ph)
        case .wallShelf:      wallShelf(pw, ph)
        case .fairyLights:    fairyLights(pw, ph)
        case .heartMirror:    heartMirror(pw, ph)
        case .wallCalendar:   wallCalendar(pw, ph)
        case .wallVines:      wallVines(pw, ph)
        case .floorCushion:   floorCushion(pw, ph)
        case .teaTable:       teaTable(pw, ph)
        case .yolkTower:      yolkTower(pw, ph)
        case .ballPit:        ballPit(pw, ph)
        case .recordPlayer:   recordPlayer(pw, ph)
        case .hangingPlant:   hangingPlant(pw, ph)
        case .monstera:       monstera(pw, ph)
        case .paperLantern:   paperLantern(pw, ph)
        case .fireplace:      fireplace(pw, ph)
        case .nightStars:     nightStars(pw, ph)
        case .playTent:       playTent(pw, ph)
        case .fishTank:       fishTank(pw, ph)
        case .birdCage:       birdCage(pw, ph)
        case .hammock:        hammock(pw, ph)
        }
    }

    // MARK: Wall

    private func posterSun(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Color(hex: 0xFFFDF6)
            Rectangle().fill(Color(hex: 0xCFE9F5)).frame(width: pw * 0.86, height: ph * 0.42).offset(y: -ph * 0.22)
            DStar(points: 12, innerRatio: 0.7).fill(Color(hex: 0xFFD25A).opacity(0.5)).frame(width: pw * 0.5, height: pw * 0.5).offset(y: -ph * 0.16)
            Circle().fill(Color(hex: 0xFFD25A)).frame(width: pw * 0.34, height: pw * 0.34).offset(y: -ph * 0.16)
            Ellipse().fill(Color(hex: 0x9CCB86)).frame(width: pw * 0.9, height: ph * 0.4).offset(y: ph * 0.3)
        }
        .frame(width: pw, height: ph)
        .clipShape(RoundedRectangle(cornerRadius: pw * 0.08))
        .overlay(RoundedRectangle(cornerRadius: pw * 0.08).strokeBorder(Color(hex: 0xE7D6BC), lineWidth: pw * 0.03))
    }

    private func wallClock(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        let s = min(pw, ph)
        return ZStack {
            Circle().fill(Color(hex: 0xC97E54)).frame(width: s, height: s)
            Circle().fill(Color(hex: 0xFFF3DA)).frame(width: s * 0.84, height: s * 0.84)
            ForEach(0..<4, id: \.self) { i in
                let off: [CGSize] = [.init(width: 0, height: -s * 0.32), .init(width: 0, height: s * 0.32),
                                     .init(width: -s * 0.32, height: 0), .init(width: s * 0.32, height: 0)]
                Circle().fill(Color(hex: 0xB5895E)).frame(width: s * 0.05, height: s * 0.05).offset(off[i])
            }
            Capsule().fill(Color(hex: 0x6B5644)).frame(width: s * 0.06, height: s * 0.3).rotationEffect(.degrees(40)).offset(y: -s * 0.06)
            Capsule().fill(Color(hex: 0x6B5644)).frame(width: s * 0.05, height: s * 0.42).rotationEffect(.degrees(-20)).offset(y: -s * 0.05)
            Circle().fill(Color(hex: 0xE89BB0)).frame(width: s * 0.1, height: s * 0.1)
        }
        .frame(width: pw, height: ph)
    }

    private func garland(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        let xs: [CGFloat] = [-0.4, -0.27, -0.13, 0, 0.13, 0.27, 0.4]
        let ys: [CGFloat] = [-0.06, 0, 0.06, 0.08, 0.06, 0, -0.06]
        let cols: [UInt] = [0xE89BB0, 0xF2C36B, 0x7FC98A, 0xCFE9F5, 0xE89BB0, 0xF2C36B, 0x7FC98A]
        return ZStack {
            SwagLine(sag: 0.5).stroke(Color(hex: 0x8A6A4A), lineWidth: max(1, pw * 0.006)).frame(width: pw, height: ph * 0.5).offset(y: -ph * 0.1)
            ForEach(0..<7, id: \.self) { i in
                PennantShape().fill(Color(hex: cols[i])).frame(width: pw * 0.1, height: ph * 0.32).offset(x: pw * xs[i], y: ph * ys[i])
            }
        }
        .frame(width: pw, height: ph)
    }

    // MARK: Furniture

    private func bookshelf(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        let topCols: [UInt] = [0xE89BB0, 0x7FC98A, 0xF2C36B, 0xCFE9F5, 0xE8A6C0, 0x6FB07A]
        let botCols: [UInt] = [0xF2C36B, 0xE89BB0, 0x9CCB86, 0xCFE9F5, 0xF2C3D2]
        return ZStack {
            RoundedRectangle(cornerRadius: pw * 0.04).fill(Color(hex: 0x9A7B5A)).frame(width: pw, height: ph * 0.92).offset(y: ph * 0.02)
            Rectangle().fill(Color(hex: 0x7A5E44)).frame(width: pw * 0.86, height: ph * 0.8).offset(y: ph * 0.02)
            Rectangle().fill(Color(hex: 0xB5895E)).frame(width: pw * 0.86, height: ph * 0.04).offset(y: -ph * 0.02)
            Rectangle().fill(Color(hex: 0xB5895E)).frame(width: pw * 0.86, height: ph * 0.04).offset(y: ph * 0.38)
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: pw * 0.01).fill(Color(hex: topCols[i]))
                    .frame(width: pw * 0.1, height: ph * 0.28)
                    .rotationEffect(.degrees(i == 5 ? 14 : 0))
                    .offset(x: pw * (-0.34 + CGFloat(i) * 0.136), y: -ph * 0.22)
            }
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: pw * 0.01).fill(Color(hex: botCols[i]))
                    .frame(width: pw * 0.12, height: ph * 0.28)
                    .offset(x: pw * (-0.32 + CGFloat(i) * 0.16), y: ph * 0.2)
            }
            RoundedRectangle(cornerRadius: pw * 0.04).fill(Color(hex: 0x7A5E44)).frame(width: pw * 0.08, height: ph * 0.06).offset(x: -pw * 0.38, y: ph * 0.5)
            RoundedRectangle(cornerRadius: pw * 0.04).fill(Color(hex: 0x7A5E44)).frame(width: pw * 0.08, height: ph * 0.06).offset(x: pw * 0.38, y: ph * 0.5)
        }
        .frame(width: pw, height: ph)
    }

    private func cozyBed(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: pw * 0.06).fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.16, height: ph * 0.9).offset(x: -pw * 0.42, y: -ph * 0.05)
            RoundedRectangle(cornerRadius: pw * 0.04).fill(Color(hex: 0xB5895E)).frame(width: pw * 0.92, height: ph * 0.5).offset(x: pw * 0.02, y: ph * 0.22)
            RoundedRectangle(cornerRadius: pw * 0.08).fill(Color(hex: 0xCFE9F5)).frame(width: pw * 0.84, height: ph * 0.46).offset(x: pw * 0.04, y: ph * 0.05)
            Capsule().fill(Color(hex: 0xBFE3F2)).frame(width: pw * 0.6, height: ph * 0.1).offset(x: pw * 0.12, y: -ph * 0.08)
            RoundedRectangle(cornerRadius: pw * 0.1).fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.26, height: ph * 0.24).rotationEffect(.degrees(-6)).offset(x: -pw * 0.28, y: -ph * 0.06)
            Capsule().fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.2, height: ph * 0.03).rotationEffect(.degrees(-6)).offset(x: -pw * 0.28, y: -ph * 0.06)
            RoundedRectangle(cornerRadius: pw * 0.03).fill(Color(hex: 0x7A5E44)).frame(width: pw * 0.05, height: ph * 0.12).offset(x: pw * 0.36, y: ph * 0.44)
        }
        .frame(width: pw, height: ph)
    }

    private func beanbag(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.08)).frame(width: pw * 0.9, height: ph * 0.12).offset(y: ph * 0.46)
            Ellipse().fill(Color(hex: 0xE8A6C0)).frame(width: pw, height: ph * 0.86).offset(y: ph * 0.06)
            Capsule().fill(Color(hex: 0xD27E97).opacity(0.5)).frame(width: pw * 0.03, height: ph * 0.5).rotationEffect(.degrees(-18)).offset(x: -pw * 0.22, y: ph * 0.1)
            Capsule().fill(Color(hex: 0xD27E97).opacity(0.5)).frame(width: pw * 0.03, height: ph * 0.5).rotationEffect(.degrees(18)).offset(x: pw * 0.22, y: ph * 0.1)
            Ellipse().fill(Color(hex: 0xF2C3D2)).frame(width: pw * 0.7, height: ph * 0.4).offset(y: -ph * 0.24)
            Ellipse().fill(Color(hex: 0xD98AAE).opacity(0.6)).frame(width: pw * 0.34, height: ph * 0.16).offset(y: -ph * 0.2)
        }
        .frame(width: pw, height: ph)
    }

    private func stool(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.08, height: ph * 0.6).rotationEffect(.degrees(12)).offset(x: -pw * 0.26, y: ph * 0.18)
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.08, height: ph * 0.6).rotationEffect(.degrees(-12)).offset(x: pw * 0.26, y: ph * 0.18)
            Capsule().fill(Color(hex: 0x8A6A4A)).frame(width: pw * 0.08, height: ph * 0.58).offset(y: ph * 0.2)
            Ellipse().fill(Color(hex: 0xA9683F)).frame(width: pw * 0.9, height: ph * 0.3).offset(y: -ph * 0.12)
            Ellipse().fill(Color(hex: 0xC97E54)).frame(width: pw * 0.9, height: ph * 0.3).offset(y: -ph * 0.18)
        }
        .frame(width: pw, height: ph)
    }

    private func toyChest(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.16, height: pw * 0.16).offset(x: pw * 0.22, y: -ph * 0.34)
            DStar(points: 5, innerRatio: 0.4).fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.16, height: pw * 0.16).offset(x: -pw * 0.2, y: -ph * 0.36)
            RoundedRectangle(cornerRadius: pw * 0.06).fill(Color(hex: 0xC97E54)).frame(width: pw, height: ph * 0.6).offset(y: ph * 0.2)
            Capsule().fill(Color(hex: 0xD68E63)).frame(width: pw * 1.02, height: ph * 0.4).offset(y: -ph * 0.16)
            Rectangle().fill(Color(hex: 0xA9683F)).frame(width: pw, height: ph * 0.05).offset(y: 0)
            Rectangle().fill(Color(hex: 0xA9683F)).frame(width: pw * 0.04, height: ph * 0.7).offset(x: -pw * 0.28, y: ph * 0.05)
            Rectangle().fill(Color(hex: 0xA9683F)).frame(width: pw * 0.04, height: ph * 0.7).offset(x: pw * 0.28, y: ph * 0.05)
            HeartShape().fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.12, height: pw * 0.12).offset(y: ph * 0.04)
        }
        .frame(width: pw, height: ph)
    }

    // MARK: Plants

    private func cactus(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Trap(topRatio: 0.8).fill(Color(hex: 0xC97E54)).frame(width: pw * 0.7, height: ph * 0.3).offset(y: ph * 0.34)
            Ellipse().fill(Color(hex: 0xD68E63)).frame(width: pw * 0.78, height: ph * 0.1).offset(y: ph * 0.2)
            Capsule().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.18, height: ph * 0.32).rotationEffect(.degrees(30)).offset(x: pw * 0.24, y: -ph * 0.06)
            Capsule().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.5, height: ph * 0.7).offset(y: -ph * 0.06)
            DStar(points: 6, innerRatio: 0.45).fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.22, height: pw * 0.22).offset(y: -ph * 0.34)
            Circle().fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.07, height: pw * 0.07).offset(y: -ph * 0.34)
        }
        .frame(width: pw, height: ph)
    }

    private func mushroom(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x7FC98A).opacity(0.7)).frame(width: pw * 0.5, height: ph * 0.08).offset(y: ph * 0.46)
            Capsule().fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.36, height: ph * 0.5).offset(y: ph * 0.22)
            Ellipse().fill(Color(hex: 0xF6D2C9)).frame(width: pw * 0.86, height: ph * 0.16).offset(y: 0)
            Ellipse().fill(Color(hex: 0xE07A6E)).frame(width: pw, height: ph * 0.6).offset(y: -ph * 0.16)
            Circle().fill(Color(hex: 0xFFFDF6)).frame(width: pw * 0.18, height: pw * 0.18).offset(x: -pw * 0.1, y: -ph * 0.18)
            Circle().fill(Color(hex: 0xFFFDF6)).frame(width: pw * 0.12, height: pw * 0.12).offset(x: pw * 0.18, y: -ph * 0.12)
            Circle().fill(Color(hex: 0xFFFDF6)).frame(width: pw * 0.1, height: pw * 0.1).offset(x: pw * 0.02, y: -ph * 0.26)
        }
        .frame(width: pw, height: ph)
    }

    private func vase(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.02, height: ph * 0.5).rotationEffect(.degrees(-10)).offset(x: -pw * 0.12, y: -ph * 0.1)
            Capsule().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.02, height: ph * 0.5).offset(y: -ph * 0.16)
            Capsule().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.02, height: ph * 0.5).rotationEffect(.degrees(10)).offset(x: pw * 0.12, y: -ph * 0.1)
            DStar(points: 5, innerRatio: 0.5).fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.26, height: pw * 0.26).offset(x: -pw * 0.12, y: -ph * 0.28)
            DStar(points: 5, innerRatio: 0.5).fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.26, height: pw * 0.26).offset(y: -ph * 0.34)
            DStar(points: 5, innerRatio: 0.5).fill(Color(hex: 0xE8A6C0)).frame(width: pw * 0.26, height: pw * 0.26).offset(x: pw * 0.12, y: -ph * 0.28)
            RoundedRectangle(cornerRadius: pw * 0.1).fill(Color(hex: 0xCFE9F5).opacity(0.85)).frame(width: pw * 0.24, height: ph * 0.16).offset(y: ph * 0.06)
            RoundedRectangle(cornerRadius: pw * 0.2).fill(Color(hex: 0xCFE9F5).opacity(0.85)).frame(width: pw * 0.4, height: ph * 0.4).offset(y: ph * 0.28)
            Capsule().fill(Color(hex: 0xBFE3F2)).frame(width: pw * 0.34, height: ph * 0.02).offset(y: ph * 0.22)
        }
        .frame(width: pw, height: ph)
    }

    // MARK: Light

    private func lamp(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFE9A8).opacity(0.4)).frame(width: pw * 1.3, height: pw * 1.3).blur(radius: 12).offset(y: -ph * 0.18)
            Ellipse().fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.46, height: ph * 0.1).offset(y: ph * 0.42)
            Capsule().fill(Color(hex: 0xB5895E)).frame(width: pw * 0.08, height: ph * 0.36).offset(y: ph * 0.18)
            Trap(topRatio: 0.55).fill(LinearGradient(colors: [Color(hex: 0xFFF1C8), Color(hex: 0xF6D98A)], startPoint: .top, endPoint: .bottom))
                .frame(width: pw * 0.66, height: ph * 0.36).offset(y: -ph * 0.18)
            Capsule().fill(Color(hex: 0xE8C672)).frame(width: pw * 0.66, height: ph * 0.04).offset(y: 0)
        }
        .frame(width: pw, height: ph)
    }

    private func candle(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFE9A8).opacity(0.5)).frame(width: pw * 0.9, height: pw * 0.9).blur(radius: 8).offset(y: -ph * 0.3)
            Ellipse().fill(Color(hex: 0xD6C3A6)).frame(width: pw * 0.9, height: ph * 0.14).offset(y: ph * 0.4)
            RoundedRectangle(cornerRadius: pw * 0.15).fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.5, height: ph * 0.6).offset(y: ph * 0.12)
            Ellipse().fill(Color(hex: 0xFCEFCD)).frame(width: pw * 0.5, height: ph * 0.12).offset(y: -ph * 0.16)
            Capsule().fill(Color(hex: 0x6B5644)).frame(width: pw * 0.03, height: ph * 0.06).offset(y: -ph * 0.18)
            FlameShape().fill(LinearGradient(colors: [Color(hex: 0xFFF1C8), Color(hex: 0xFFB347)], startPoint: .top, endPoint: .bottom))
                .frame(width: pw * 0.18, height: ph * 0.3).offset(y: -ph * 0.32)
        }
        .frame(width: pw, height: ph)
    }

    // MARK: Fun

    private func balloons(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: max(0.8, pw * 0.008), height: ph * 0.4).rotationEffect(.degrees(-6)).offset(x: -pw * 0.18, y: ph * 0.12)
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: max(0.8, pw * 0.008), height: ph * 0.4).offset(x: pw * 0.05, y: ph * 0.05)
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: max(0.8, pw * 0.008), height: ph * 0.4).rotationEffect(.degrees(6)).offset(x: pw * 0.26, y: ph * 0.12)
            BalloonShape().fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.4, height: ph * 0.5).offset(x: -pw * 0.22, y: -ph * 0.2)
            BalloonShape().fill(Color(hex: 0x9CC9E8)).frame(width: pw * 0.4, height: ph * 0.5).offset(x: pw * 0.26, y: -ph * 0.16)
            BalloonShape().fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.46, height: ph * 0.56).offset(x: pw * 0.05, y: -ph * 0.3)
            Ellipse().fill(.white.opacity(0.5)).frame(width: pw * 0.08, height: ph * 0.1).rotationEffect(.degrees(-20)).offset(x: -pw * 0.28, y: -ph * 0.26)
            Ellipse().fill(.white.opacity(0.5)).frame(width: pw * 0.09, height: ph * 0.11).rotationEffect(.degrees(-20)).offset(x: -pw * 0.04, y: -ph * 0.38)
        }
        .frame(width: pw, height: ph)
    }

    // MARK: Batch 2 (docs/rooms/decor.md)

    private func framedPhotos(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: pw * 0.02).fill(Color(hex: 0x8A6A4A)).frame(width: pw * 0.30, height: ph * 0.55).offset(x: -pw * 0.32, y: -ph * 0.08)
            Rectangle().fill(Color(hex: 0xF2C3D2)).frame(width: pw * 0.22, height: ph * 0.42).offset(x: -pw * 0.32, y: -ph * 0.08)
            Circle().fill(Color(hex: 0xFFD25A)).frame(width: pw * 0.1, height: pw * 0.1).offset(x: -pw * 0.32, y: -ph * 0.08)
            RoundedRectangle(cornerRadius: pw * 0.02).fill(Color(hex: 0xB5895E)).frame(width: pw * 0.34, height: ph * 0.46).offset(y: ph * 0.06)
            Rectangle().fill(Color(hex: 0xCFE9F5)).frame(width: pw * 0.26, height: ph * 0.34).offset(y: ph * 0.06)
            Ellipse().fill(Color(hex: 0x9CCB86)).frame(width: pw * 0.26, height: ph * 0.18).offset(y: ph * 0.14)
            RoundedRectangle(cornerRadius: pw * 0.02).fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.28, height: ph * 0.5).offset(x: pw * 0.33, y: -ph * 0.04)
            Rectangle().fill(Color(hex: 0xFFF1C8)).frame(width: pw * 0.2, height: ph * 0.38).offset(x: pw * 0.33, y: -ph * 0.04)
            HeartShape().fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.1, height: pw * 0.1).offset(x: pw * 0.33, y: -ph * 0.04)
        }
        .frame(width: pw, height: ph)
    }

    private func wallShelf(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: pw * 0.02).fill(Color(hex: 0x9A7B5A)).frame(width: pw, height: ph * 0.18).offset(y: ph * 0.34)
            Rectangle().fill(Color(hex: 0x7A5E44)).frame(width: pw, height: ph * 0.05).offset(y: ph * 0.46)
            RoundedRectangle(cornerRadius: pw * 0.01).fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.07, height: ph * 0.46).offset(x: -pw * 0.34, y: -ph * 0.04)
            RoundedRectangle(cornerRadius: pw * 0.01).fill(Color(hex: 0x7FC98A)).frame(width: pw * 0.07, height: ph * 0.52).offset(x: -pw * 0.26, y: -ph * 0.08)
            RoundedRectangle(cornerRadius: pw * 0.01).fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.07, height: ph * 0.44).rotationEffect(.degrees(12)).offset(x: -pw * 0.18, y: -ph * 0.03)
            Trap(topRatio: 0.8).fill(Color(hex: 0xC97E54)).frame(width: pw * 0.16, height: ph * 0.3).offset(x: pw * 0.28, y: ph * 0.04)
            ForEach(0..<3, id: \.self) { i in
                Ellipse().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.06, height: ph * 0.22).rotationEffect(.degrees(Double(i - 1) * 25)).offset(x: pw * 0.28, y: -ph * 0.16)
            }
        }
        .frame(width: pw, height: ph)
    }

    private func fairyLights(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            SwagLine(sag: 0.55).stroke(Color(hex: 0x6B5644), lineWidth: max(0.8, pw * 0.005)).frame(width: pw, height: ph * 0.5).offset(y: -ph * 0.12)
            ForEach(0..<9, id: \.self) { i in
                let t = CGFloat(i) / 8
                let u = 2 * t - 1
                let dip = 1 - u * u
                let x = pw * (-0.44 + 0.88 * t)
                let y = -ph * 0.22 + ph * 0.26 * dip
                ZStack {
                    Circle().fill(Color(hex: 0xFFE9A8).opacity(0.5)).frame(width: pw * 0.1, height: pw * 0.1).blur(radius: 6)
                    Circle().fill(Color(hex: 0xFFF1C8)).frame(width: pw * 0.045, height: pw * 0.045).offset(y: ph * 0.03)
                }
                .offset(x: x, y: y)
            }
        }
        .frame(width: pw, height: ph)
    }

    private func heartMirror(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Triangle().fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.1, height: ph * 0.08).offset(y: -ph * 0.5)
            HeartShape().fill(Color(hex: 0xF2C36B)).frame(width: pw, height: ph)
            HeartShape().fill(Color(hex: 0xD7E9EF)).frame(width: pw * 0.82, height: ph * 0.82).offset(y: ph * 0.01)
            Capsule().fill(.white.opacity(0.6)).frame(width: pw * 0.12, height: ph * 0.4).rotationEffect(.degrees(30)).offset(x: -pw * 0.16, y: -ph * 0.04)
            Capsule().fill(.white.opacity(0.45)).frame(width: pw * 0.07, height: ph * 0.24).rotationEffect(.degrees(30)).offset(x: -pw * 0.04, y: ph * 0.06)
        }
        .frame(width: pw, height: ph)
    }

    private func wallCalendar(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.1, height: pw * 0.1).offset(y: -ph * 0.52)
            ZStack {
                Color(hex: 0xFFFDF6)
                Rectangle().fill(Color(hex: 0xE89BB0)).frame(height: ph * 0.34).frame(maxHeight: .infinity, alignment: .top)
                RoundedRectangle(cornerRadius: pw * 0.06).fill(Color(hex: 0xF2C3D2)).frame(width: pw * 0.5, height: ph * 0.34).offset(y: ph * 0.1)
            }
            .frame(width: pw, height: ph)
            .clipShape(RoundedRectangle(cornerRadius: pw * 0.1))
        }
        .frame(width: pw, height: ph)
    }

    private func wallVines(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Trap(topRatio: 0.85).fill(Color(hex: 0xC97E54)).frame(width: pw * 0.5, height: ph * 0.16).offset(y: -ph * 0.42)
            Capsule().fill(Color(hex: 0x5A9E6E)).frame(width: pw * 0.04, height: ph * 0.8).offset(x: -pw * 0.08, y: ph * 0.06)
            Capsule().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.04, height: ph * 0.8).offset(x: pw * 0.12, y: ph * 0.06)
            ForEach(0..<10, id: \.self) { i in
                let left = i % 2 == 0
                let baseX = left ? -pw * 0.08 : pw * 0.12
                Ellipse().fill(Color(hex: left ? 0x7FC98A : 0x6FB07A))
                    .frame(width: pw * 0.18, height: ph * 0.1)
                    .rotationEffect(.degrees(left ? -40 : 40))
                    .offset(x: baseX + (left ? -pw * 0.06 : pw * 0.06), y: -ph * 0.28 + ph * 0.07 * CGFloat(i))
            }
        }
        .frame(width: pw, height: ph)
    }

    private func floorCushion(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xF2C36B)).frame(width: pw, height: ph * 0.9)
            Ellipse().strokeBorder(Color(hex: 0xD9A53F), lineWidth: max(1, pw * 0.03)).frame(width: pw, height: ph * 0.9)
            Ellipse().fill(Color(hex: 0xFFE0A0)).frame(width: pw * 0.7, height: ph * 0.4).offset(y: -ph * 0.12)
            Circle().fill(Color(hex: 0xD9A53F)).frame(width: pw * 0.12, height: pw * 0.12).offset(y: -ph * 0.04)
        }
        .frame(width: pw, height: ph)
    }

    private func teaTable(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x8A6A4A)).frame(width: pw * 0.4, height: ph * 0.08).offset(y: ph * 0.46)
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.1, height: ph * 0.6).offset(y: ph * 0.2)
            Ellipse().fill(Color(hex: 0xB5895E)).frame(width: pw * 0.9, height: ph * 0.16).offset(y: -ph * 0.06)
            Ellipse().fill(Color(hex: 0xC97E54)).frame(width: pw * 0.9, height: ph * 0.16).offset(y: -ph * 0.1)
            Ellipse().fill(Color(hex: 0xFFFDF6)).frame(width: pw * 0.34, height: ph * 0.06).offset(y: -ph * 0.16)
            Trap(topRatio: 1.2).fill(Color(hex: 0xF2C3D2)).frame(width: pw * 0.2, height: ph * 0.12).offset(y: -ph * 0.22)
            Circle().strokeBorder(Color(hex: 0xE89BB0), lineWidth: max(1, pw * 0.02)).frame(width: pw * 0.08, height: pw * 0.08).offset(x: pw * 0.12, y: -ph * 0.22)
        }
        .frame(width: pw, height: ph)
    }

    private func yolkTower(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xB5895E)).frame(width: pw * 0.9, height: ph * 0.12).offset(y: ph * 0.46)
            RoundedRectangle(cornerRadius: pw * 0.2).fill(Color(hex: 0xD6C3A6)).frame(width: pw * 0.22, height: ph * 0.86)
            ForEach(0..<5, id: \.self) { i in
                Capsule().fill(Color(hex: 0xC2A87E).opacity(0.7)).frame(width: pw * 0.24, height: ph * 0.04).offset(y: -ph * 0.32 + ph * 0.16 * CGFloat(i))
            }
            Ellipse().fill(Color(hex: 0xF2C3D2)).frame(width: pw * 0.7, height: ph * 0.12).offset(y: -ph * 0.02)
            Ellipse().fill(Color(hex: 0xE8A6C0)).frame(width: pw * 0.9, height: ph * 0.3).offset(y: -ph * 0.4)
            Ellipse().fill(Color(hex: 0xD98AAE)).frame(width: pw * 0.62, height: ph * 0.18).offset(y: -ph * 0.43)
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: max(0.8, pw * 0.015), height: ph * 0.16).offset(x: pw * 0.3, y: -ph * 0.27)
            Circle().fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.14, height: pw * 0.14).offset(x: pw * 0.3, y: -ph * 0.18)
        }
        .frame(width: pw, height: ph)
    }

    private func ballPit(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        let back: [UInt] = [0xE89BB0, 0xF2C36B, 0x7FC98A, 0xCFE9F5, 0xE8A6C0, 0xFFD25A]
        let front: [UInt] = [0x7FC98A, 0xE89BB0, 0xFFD25A, 0xCFE9F5, 0xF2C36B]
        return ZStack {
            Ellipse().fill(Color(hex: 0xB5895E)).frame(width: pw, height: ph * 0.7).offset(y: ph * 0.18)
            Ellipse().fill(Color(hex: 0xCFE9F5)).frame(width: pw, height: ph * 0.6).offset(y: ph * 0.1)
            ForEach(0..<6, id: \.self) { i in
                Circle().fill(Color(hex: back[i])).frame(width: pw * 0.13, height: pw * 0.13).offset(x: pw * (-0.36 + 0.144 * CGFloat(i)), y: -ph * 0.04)
            }
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(Color(hex: front[i])).frame(width: pw * 0.15, height: pw * 0.15).offset(x: pw * (-0.28 + 0.14 * CGFloat(i)), y: ph * 0.1)
            }
            Ellipse().strokeBorder(Color(hex: 0xBFE3F2), lineWidth: max(1, pw * 0.02)).frame(width: pw, height: ph * 0.6).offset(y: ph * 0.1)
        }
        .frame(width: pw, height: ph)
    }

    private func recordPlayer(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: pw * 0.05).fill(Color(hex: 0x8A6A4A)).frame(width: pw, height: ph * 0.6).offset(y: ph * 0.16)
            RoundedRectangle(cornerRadius: pw * 0.05).fill(Color(hex: 0xB5895E)).frame(width: pw, height: ph * 0.16).offset(y: -ph * 0.16)
            Circle().fill(Color(hex: 0x2E2A28)).frame(width: pw * 0.56, height: pw * 0.56).offset(x: -pw * 0.08, y: -ph * 0.04)
            Circle().fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.2, height: pw * 0.2).offset(x: -pw * 0.08, y: -ph * 0.04)
            Circle().fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.04, height: pw * 0.04).offset(x: -pw * 0.08, y: -ph * 0.04)
            Capsule().fill(Color(hex: 0xD6C3A6)).frame(width: pw * 0.04, height: ph * 0.4).rotationEffect(.degrees(-30)).offset(x: pw * 0.22, y: -ph * 0.08)
        }
        .frame(width: pw, height: ph)
    }

    private func hangingPlant(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(hex: 0xD6C3A6)).frame(width: max(0.8, pw * 0.012), height: ph * 0.5).rotationEffect(.degrees(8)).offset(x: -pw * 0.18, y: -ph * 0.26)
            Capsule().fill(Color(hex: 0xD6C3A6)).frame(width: max(0.8, pw * 0.012), height: ph * 0.5).offset(y: -ph * 0.28)
            Capsule().fill(Color(hex: 0xD6C3A6)).frame(width: max(0.8, pw * 0.012), height: ph * 0.5).rotationEffect(.degrees(-8)).offset(x: pw * 0.18, y: -ph * 0.26)
            Circle().fill(Color(hex: 0xC2A87E)).frame(width: pw * 0.08, height: pw * 0.08).offset(y: -ph * 0.48)
            Ellipse().fill(Color(hex: 0xB9A9C9)).frame(width: pw * 0.5, height: ph * 0.18).offset(y: ph * 0.1)
            Ellipse().fill(Color(hex: 0xCFC2E6)).frame(width: pw * 0.5, height: ph * 0.3).offset(y: ph * 0.02)
            Ellipse().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.6, height: ph * 0.3).offset(y: -ph * 0.1)
            ForEach(0..<4, id: \.self) { i in
                Capsule().fill(Color(hex: 0x7FC98A)).frame(width: max(0.8, pw * 0.03), height: ph * 0.3).offset(x: pw * (-0.18 + 0.12 * CGFloat(i)), y: ph * 0.28)
            }
        }
        .frame(width: pw, height: ph)
    }

    private func monstera(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Trap(topRatio: 1.2).fill(Color(hex: 0xC2A87E)).frame(width: pw * 0.5, height: ph * 0.22).offset(y: ph * 0.4)
            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(Color(hex: 0xA88A5E).opacity(0.6)).frame(width: pw * 0.5, height: ph * 0.02).offset(y: ph * 0.34 + ph * 0.05 * CGFloat(i))
            }
            ForEach(0..<5, id: \.self) { i in
                Ellipse().fill(Color(hex: i % 2 == 0 ? 0x6FB07A : 0x5A9E6E))
                    .frame(width: pw * 0.34, height: ph * 0.5)
                    .rotationEffect(.degrees(Double(i - 2) * 22))
                    .offset(y: -ph * 0.18)
            }
        }
        .frame(width: pw, height: ph)
    }

    private func paperLantern(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: max(0.8, pw * 0.012), height: ph * 0.3).offset(y: -ph * 0.36)
            Circle().fill(Color(hex: 0xFFD9A0).opacity(0.4)).frame(width: pw * 1.1, height: pw * 1.1).blur(radius: 10).offset(y: ph * 0.02)
            Ellipse().fill(Color(hex: 0xFFC98E)).frame(width: pw * 0.84, height: ph * 0.78)
            Trap(topRatio: 0.5).fill(Color(hex: 0xE07A6E)).frame(width: pw * 0.3, height: ph * 0.1).offset(y: -ph * 0.32)
            Ellipse().fill(Color(hex: 0xE07A6E)).frame(width: pw * 0.3, height: ph * 0.08).offset(y: ph * 0.32)
            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(Color(hex: 0xE89B5E).opacity(0.5)).frame(width: pw * 0.78, height: ph * 0.02).offset(y: -ph * 0.14 + ph * 0.14 * CGFloat(i))
            }
            Capsule().fill(Color(hex: 0xE07A6E)).frame(width: pw * 0.04, height: ph * 0.16).offset(y: ph * 0.44)
        }
        .frame(width: pw, height: ph)
    }

    private func fireplace(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: pw * 0.04).fill(Color(hex: 0xC98A6E)).frame(width: pw, height: ph * 0.92).offset(y: ph * 0.04)
            RoundedRectangle(cornerRadius: pw * 0.06).fill(Color(hex: 0x3A2E2A)).frame(width: pw * 0.66, height: ph * 0.6).offset(y: ph * 0.1)
            RoundedRectangle(cornerRadius: pw * 0.03).fill(Color(hex: 0x9A7B5A)).frame(width: pw * 1.1, height: ph * 0.12).offset(y: -ph * 0.4)
            Ellipse().fill(Color(hex: 0xFFB347).opacity(0.5)).frame(width: pw * 0.7, height: ph * 0.5).blur(radius: 14).offset(y: ph * 0.14)
            Capsule().fill(Color(hex: 0x7A5E44)).frame(width: pw * 0.34, height: ph * 0.07).rotationEffect(.degrees(-10)).offset(x: -pw * 0.05, y: ph * 0.28)
            Capsule().fill(Color(hex: 0x7A5E44)).frame(width: pw * 0.34, height: ph * 0.07).rotationEffect(.degrees(8)).offset(x: pw * 0.06, y: ph * 0.3)
            FlameShape().fill(Color(hex: 0xFFB347)).frame(width: pw * 0.16, height: ph * 0.26).offset(x: -pw * 0.1, y: ph * 0.06)
            FlameShape().fill(Color(hex: 0xFFD25A)).frame(width: pw * 0.2, height: ph * 0.34).offset(y: ph * 0.02)
            FlameShape().fill(Color(hex: 0xFF8A4A)).frame(width: pw * 0.14, height: ph * 0.22).offset(x: pw * 0.1, y: ph * 0.08)
        }
        .frame(width: pw, height: ph)
    }

    private func nightStars(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            DStar(points: 5).fill(Color(hex: 0xFFE9A8).opacity(0.5)).frame(width: pw * 0.5, height: pw * 0.5).blur(radius: 6).offset(x: -pw * 0.1, y: -ph * 0.1)
            DStar(points: 5).fill(Color(hex: 0xFFF1C8)).frame(width: pw * 0.36, height: pw * 0.36).offset(x: -pw * 0.1, y: -ph * 0.1)
            DStar(points: 5).fill(Color(hex: 0xFFE9A8)).frame(width: pw * 0.24, height: pw * 0.24).offset(x: pw * 0.3, y: -ph * 0.26)
            DStar(points: 4, innerRatio: 0.4).fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.12, height: pw * 0.12).offset(x: pw * 0.34, y: ph * 0.12)
            DStar(points: 4, innerRatio: 0.4).fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.12, height: pw * 0.12).offset(x: -pw * 0.34, y: ph * 0.2)
            DStar(points: 4, innerRatio: 0.4).fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.12, height: pw * 0.12).offset(x: pw * 0.04, y: ph * 0.3)
            ZStack {
                Circle().fill(Color(hex: 0xFFE9A8)).frame(width: pw * 0.3, height: pw * 0.3)
                Circle().fill(.black).frame(width: pw * 0.26, height: pw * 0.26).offset(x: pw * 0.08).blendMode(.destinationOut)
            }
            .compositingGroup()
            .offset(x: pw * 0.16, y: -ph * 0.02)
        }
        .frame(width: pw, height: ph)
    }

    private func playTent(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.08)).frame(width: pw * 0.95, height: ph * 0.1).offset(y: ph * 0.46)
            Triangle().fill(Color(hex: 0xE8A6C0)).frame(width: pw, height: ph * 0.92).offset(y: ph * 0.04)
            Triangle().fill(Color(hex: 0xD98AAE).opacity(0.5)).frame(width: pw * 0.5, height: ph * 0.92).offset(x: -pw * 0.25, y: ph * 0.04)
            Triangle().fill(Color(hex: 0x4A3B44)).frame(width: pw * 0.3, height: ph * 0.6).offset(y: ph * 0.16)
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: max(0.8, pw * 0.012), height: ph * 0.1).offset(y: -ph * 0.5)
            PennantShape().fill(Color(hex: 0xF2C36B)).frame(width: pw * 0.1, height: ph * 0.12).rotationEffect(.degrees(-90)).offset(x: pw * 0.07, y: -ph * 0.5)
        }
        .frame(width: pw, height: ph)
    }

    private func fishTank(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: pw * 0.04).fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.92, height: ph * 0.16).offset(y: ph * 0.42)
            RoundedRectangle(cornerRadius: pw * 0.1).fill(Color(hex: 0xBFE3F2).opacity(0.7)).frame(width: pw, height: ph * 0.74).offset(y: -ph * 0.04)
            RoundedRectangle(cornerRadius: pw * 0.05).fill(Color(hex: 0xD6C3A6)).frame(width: pw * 0.9, height: ph * 0.12).offset(y: ph * 0.24)
            ForEach(0..<3, id: \.self) { i in
                Ellipse().fill(Color(hex: 0x6FB07A)).frame(width: pw * 0.06, height: ph * 0.3).rotationEffect(.degrees(Double(i - 1) * 15)).offset(x: pw * 0.3, y: ph * 0.06)
            }
            Ellipse().fill(Color(hex: 0xF2A24A)).frame(width: pw * 0.2, height: ph * 0.13).offset(x: -pw * 0.1, y: -ph * 0.06)
            Triangle().fill(Color(hex: 0xF2A24A)).frame(width: pw * 0.1, height: ph * 0.12).rotationEffect(.degrees(-90)).offset(x: -pw * 0.22, y: -ph * 0.06)
            Circle().fill(Color(hex: 0x2E2A28)).frame(width: pw * 0.025, height: pw * 0.025).offset(x: -pw * 0.04, y: -ph * 0.07)
            Ellipse().fill(Color(hex: 0xE89BB0)).frame(width: pw * 0.14, height: ph * 0.1).offset(x: pw * 0.1, y: ph * 0.06)
            Capsule().fill(.white.opacity(0.4)).frame(width: pw * 0.12, height: ph * 0.4).rotationEffect(.degrees(12)).offset(x: -pw * 0.3, y: -ph * 0.06)
            RoundedRectangle(cornerRadius: pw * 0.1).strokeBorder(Color(hex: 0xCFE9F5), lineWidth: max(1, pw * 0.03)).frame(width: pw, height: ph * 0.74).offset(y: -ph * 0.04)
        }
        .frame(width: pw, height: ph)
    }

    private func birdCage(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            ArchShape().stroke(Color(hex: 0xC2A87E), lineWidth: max(1, pw * 0.025)).frame(width: pw * 0.7, height: ph * 0.4).offset(y: -ph * 0.18)
            RoundedRectangle(cornerRadius: pw * 0.06).stroke(Color(hex: 0xC2A87E), lineWidth: max(1, pw * 0.025)).frame(width: pw * 0.7, height: ph * 0.5).offset(y: ph * 0.1)
            ForEach(0..<4, id: \.self) { i in
                Capsule().fill(Color(hex: 0xC2A87E)).frame(width: max(0.8, pw * 0.012), height: ph * 0.5).offset(x: pw * (-0.21 + 0.14 * CGFloat(i)), y: ph * 0.1)
            }
            Ellipse().strokeBorder(Color(hex: 0xB5895E), lineWidth: max(1, pw * 0.03)).frame(width: pw * 0.7, height: ph * 0.1).offset(y: ph * 0.36)
            Capsule().fill(Color(hex: 0xC2A87E)).frame(width: pw * 0.4, height: ph * 0.02).offset(y: ph * 0.08)
            Circle().fill(Color(hex: 0x9CC9E8)).frame(width: pw * 0.2, height: pw * 0.2).offset(y: ph * 0.0)
            Triangle().fill(Color(hex: 0xF2A24A)).frame(width: pw * 0.05, height: pw * 0.05).rotationEffect(.degrees(90)).offset(x: pw * 0.12, y: ph * 0.0)
            Circle().fill(Color(hex: 0x2E2A28)).frame(width: pw * 0.025, height: pw * 0.025).offset(x: pw * 0.04, y: -ph * 0.01)
        }
        .frame(width: pw, height: ph)
    }

    private func hammock(_ pw: CGFloat, _ ph: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.05, height: ph * 0.9).rotationEffect(.degrees(-8)).offset(x: -pw * 0.46, y: -ph * 0.02)
            Capsule().fill(Color(hex: 0x9A7B5A)).frame(width: pw * 0.05, height: ph * 0.9).rotationEffect(.degrees(8)).offset(x: pw * 0.46, y: -ph * 0.02)
            Ellipse().fill(Color(hex: 0x8A6A4A)).frame(width: pw * 0.12, height: ph * 0.05).offset(x: -pw * 0.46, y: ph * 0.44)
            Ellipse().fill(Color(hex: 0x8A6A4A)).frame(width: pw * 0.12, height: ph * 0.05).offset(x: pw * 0.46, y: ph * 0.44)
            SwagLine(sag: 0.9).stroke(Color(hex: 0xE89BB0), style: StrokeStyle(lineWidth: ph * 0.22, lineCap: .round)).frame(width: pw * 0.84, height: ph * 0.3).offset(y: -ph * 0.02)
            SwagLine(sag: 0.9).stroke(Color(hex: 0xF2C3D2), style: StrokeStyle(lineWidth: max(1, pw * 0.01))).frame(width: pw * 0.84, height: ph * 0.3).offset(y: ph * 0.02)
            RoundedRectangle(cornerRadius: pw * 0.06).fill(Color(hex: 0xFFF3DA)).frame(width: pw * 0.18, height: ph * 0.12).rotationEffect(.degrees(-10)).offset(x: -pw * 0.2, y: -ph * 0.04)
        }
        .frame(width: pw, height: ph)
    }
}

// MARK: - Shapes (local to the room decor file)

/// Flat-top trapezoid, `topRatio` = top width / bottom width.
private struct Trap: Shape {
    var topRatio: CGFloat = 0.7
    func path(in r: CGRect) -> Path {
        var p = Path()
        let inset = r.width * (1 - topRatio) / 2
        p.move(to: CGPoint(x: r.minX + inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// An n-point star (local copy so the room file is self-contained).
private struct DStar: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.4
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let outer = min(r.width, r.height) / 2
        let inner = outer * innerRatio
        let step = Double.pi / Double(points)
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = Double(i) * step - .pi / 2
            let pt = CGPoint(x: c.x + radius * cos(angle), y: c.y + radius * sin(angle))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// Point-down isosceles triangle (bunting flag).
private struct PennantShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A single sagging swag line (garland / fairy-light wire).
private struct SwagLine: Shape {
    var sag: CGFloat = 0.6
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + r.height * sag))
        return p
    }
}

/// A teardrop flame (point-up) for candles.
private struct FlameShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY + r.height * 0.1),
                       control: CGPoint(x: r.maxX, y: r.minY + r.height * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY + r.height * 0.1),
                       control: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY + r.height * 0.2))
        p.closeSubpath()
        return p
    }
}

/// A heart (two top bumps, point at the bottom).
private struct HeartShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.midX, y: r.minY + h * 0.28))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.midX - w * 0.18, y: r.minY - h * 0.1),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.02))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.55),
                   control2: CGPoint(x: r.midX - w * 0.1, y: r.minY + h * 0.7))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.midX + w * 0.1, y: r.minY + h * 0.7),
                   control2: CGPoint(x: r.maxX, y: r.minY + h * 0.55))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.02),
                   control2: CGPoint(x: r.midX + w * 0.18, y: r.minY - h * 0.1))
        p.closeSubpath()
        return p
    }
}

/// A balloon (egg-ish ellipse with a tiny tie nub).
private struct BalloonShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height * 0.92))
        p.move(to: CGPoint(x: r.midX - r.width * 0.06, y: r.maxY - r.height * 0.06))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.06, y: r.maxY - r.height * 0.06))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Point-up triangle (tent body, fish tails, beaks, mirror hook).
private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A rounded-top arch (birdcage dome): flat sides, semicircle top.
private struct ArchShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let radius = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + radius), radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
