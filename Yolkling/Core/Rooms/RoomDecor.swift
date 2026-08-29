import SwiftUI
import YolklingCore

/// A placeable room decoration, bought with earned Yolks (ownership lives in the
/// wallet, so it persists like every other purchase). Each piece is code-drawn by
/// RoomDecorView and placed by RoomView at its (px, py) with size (sw, sh), all as
/// fractions of the room. See docs/rooms/decor.md.
struct RoomDecor: Identifiable, Sendable {
    let id: String
    let name: String
    let kind: Kind
    let rarity: Rarity
    let cost: Int
    let px: CGFloat   // placement x, fraction of room width
    let py: CGFloat   // placement y, fraction of room height
    let sw: CGFloat   // size width, fraction of room width
    let sh: CGFloat   // size height, fraction of room height

    enum Kind: String, Sendable {
        case posterSun, wallClock, pennantGarland, bookshelf, cozyBed
        case beanbag, woodStool, cactus, mushroom, flowerVase
        case tableLamp, candle, balloonBunch, toyChest
        // batch 2 (docs/rooms/decor.md)
        case framedPhotos, wallShelf, fairyLights, heartMirror, wallCalendar
        case wallVines, floorCushion, teaTable, yolkTower, ballPit
        case recordPlayer, hangingPlant, monstera, paperLantern, fireplace
        case nightStars, playTent, fishTank, birdCage, hammock
    }
}

enum RoomDecorCatalog {
    static let all: [RoomDecor] = [
        d("decor-poster",    "Sunny Poster",  .posterSun,      .common, 90,  0.50, 0.18, 0.16, 0.22),
        d("decor-clock",     "Wall Clock",    .wallClock,      .common, 100, 0.62, 0.14, 0.10, 0.14),
        d("decor-garland",   "Garland",       .pennantGarland, .common, 95,  0.50, 0.10, 0.46, 0.10),
        d("decor-bookshelf", "Bookshelf",     .bookshelf,      .rare,   320, 0.14, 0.55, 0.20, 0.46),
        d("decor-bed",       "Cozy Bed",      .cozyBed,        .rare,   300, 0.30, 0.80, 0.30, 0.22),
        d("decor-beanbag",   "Beanbag",       .beanbag,        .common, 130, 0.82, 0.82, 0.20, 0.18),
        d("decor-stool",     "Wood Stool",    .woodStool,      .common, 90,  0.58, 0.83, 0.12, 0.14),
        d("decor-cactus",    "Cactus",        .cactus,         .common, 110, 0.42, 0.71, 0.10, 0.20),
        d("decor-mushroom",  "Toadstool",     .mushroom,       .common, 100, 0.34, 0.75, 0.10, 0.14),
        d("decor-vase",      "Flower Vase",   .flowerVase,     .common, 120, 0.50, 0.75, 0.10, 0.18),
        d("decor-lamp",      "Table Lamp",    .tableLamp,      .common, 130, 0.86, 0.69, 0.12, 0.18),
        d("decor-candle",    "Candle",        .candle,         .common, 80,  0.68, 0.75, 0.07, 0.13),
        d("decor-balloons",  "Balloons",      .balloonBunch,   .common, 110, 0.16, 0.22, 0.16, 0.30),
        d("decor-toychest",  "Toy Chest",     .toyChest,       .common, 140, 0.22, 0.85, 0.18, 0.14),
        // batch 2
        d("decor-photos",     "Framed Photos", .framedPhotos,  .common, 120, 0.40, 0.20, 0.26, 0.20),
        d("decor-shelf",      "Wall Shelf",    .wallShelf,     .rare,   260, 0.30, 0.30, 0.22, 0.10),
        d("decor-fairylights","Fairy Lights",  .fairyLights,   .rare,   280, 0.50, 0.12, 0.50, 0.12),
        d("decor-mirror",     "Heart Mirror",  .heartMirror,   .rare,   300, 0.79, 0.20, 0.13, 0.18),
        d("decor-calendar",   "Calendar",      .wallCalendar,  .common, 85,  0.63, 0.16, 0.09, 0.13),
        d("decor-vines",      "Wall Vines",    .wallVines,     .rare,   250, 0.92, 0.24, 0.12, 0.40),
        d("decor-cushion",    "Floor Cushion", .floorCushion,  .common, 80,  0.66, 0.87, 0.14, 0.07),
        d("decor-teatable",   "Tea Table",     .teaTable,      .rare,   270, 0.72, 0.78, 0.18, 0.20),
        d("decor-yolktower",  "Yolk Tower",    .yolkTower,     .epic,   480, 0.88, 0.64, 0.18, 0.46),
        d("decor-ballpit",    "Ball Pit",      .ballPit,       .rare,   330, 0.76, 0.87, 0.26, 0.14),
        d("decor-record",     "Record Player", .recordPlayer,  .epic,   460, 0.24, 0.80, 0.18, 0.16),
        d("decor-hangplant",  "Hanging Plant", .hangingPlant,  .rare,   250, 0.14, 0.28, 0.12, 0.30),
        d("decor-monstera",   "Monstera",      .monstera,      .rare,   290, 0.88, 0.58, 0.20, 0.42),
        d("decor-lantern",    "Paper Lantern", .paperLantern,  .rare,   260, 0.55, 0.14, 0.11, 0.18),
        d("decor-fireplace",  "Fireplace",     .fireplace,     .epic,   520, 0.50, 0.48, 0.26, 0.34),
        d("decor-nightstars", "Night Stars",   .nightStars,    .rare,   250, 0.80, 0.38, 0.24, 0.24),
        d("decor-tent",       "Play Tent",     .playTent,      .epic,   500, 0.32, 0.72, 0.32, 0.36),
        d("decor-fishtank",   "Fish Tank",     .fishTank,      .rare,   340, 0.74, 0.71, 0.20, 0.20),
        d("decor-birdcage",   "Bird Cage",     .birdCage,      .rare,   290, 0.18, 0.30, 0.12, 0.30),
        d("decor-hammock",    "Hammock",       .hammock,       .epic,   470, 0.50, 0.82, 0.36, 0.18),
    ]

    static func byID(_ id: String) -> RoomDecor? { all.first { $0.id == id } }

    private static func d(_ id: String, _ name: String, _ kind: RoomDecor.Kind, _ rarity: Rarity, _ cost: Int,
                          _ px: CGFloat, _ py: CGFloat, _ sw: CGFloat, _ sh: CGFloat) -> RoomDecor {
        RoomDecor(id: id, name: name, kind: kind, rarity: rarity, cost: cost, px: px, py: py, sw: sw, sh: sh)
    }
}
