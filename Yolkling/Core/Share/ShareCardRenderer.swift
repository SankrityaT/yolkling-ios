import SwiftUI
import UIKit

/// Rasterises a ``PostcardCard`` to a PNG on disk, ready for `ShareLink`.
///
/// Shares a **file URL rather than an `Image`** on purpose: Instagram, TikTok and
/// Messages all hand off a file far more reliably than an in-memory image, which several
/// of them silently refuse. `ShareLink(item: url)` is already proven twice in this
/// codebase (ReferralView, GrowFriendsView).
@MainActor
enum ShareCardRenderer {

    /// 3× the card's 360×450 points → 1080×1350 px, Instagram's largest feed slot.
    private static let scale: CGFloat = 3

    /// Render the card and write it to a temporary PNG.
    /// - Returns: the file URL, or nil if rasterisation failed.
    static func render(snapshot: RoomSnapshot,
                       creatureName: String,
                       phrase: String,
                       inviteCode: String) -> URL? {
        let card = PostcardCard(snapshot: snapshot,
                                creatureName: creatureName,
                                phrase: phrase,
                                inviteCode: inviteCode)

        let renderer = ImageRenderer(content: card)
        renderer.scale = scale
        renderer.isOpaque = true

        guard let image = renderer.uiImage, let data = image.pngData() else { return nil }

        return write(data, named: "yolkling-\(safe(creatureName))")
    }

    /// Render a holo card, framed for posting.
    ///
    /// A separate entry point rather than a generic `render(_ view:)` because the two cards
    /// disagree on the one thing that matters: `PostcardCard` is 360×450 and this frames a
    /// 63×88 card inside the same box. Sharing the 3× scale is the whole overlap.
    static func renderCard(face: YolkCardFace, inviteCode: String) -> URL? {
        let renderer = ImageRenderer(content: CardShareCard(face: face, inviteCode: inviteCode))
        renderer.scale = scale
        renderer.isOpaque = true

        guard let image = renderer.uiImage, let data = image.pngData() else { return nil }
        // A DIFFERENT filename prefix from the postcard. Both used to derive the name from
        // the creature, so sharing a card and then a postcard for the same creature wrote
        // over the same file and whichever the share sheet read second won.
        return write(data, named: "yolkling-card-\(safe(face.name))")
    }

    // MARK: Files

    /// The only sanitisation that matters here: a path separator would silently write into
    /// a directory that does not exist and the whole share would fail with no error.
    private static func safe(_ name: String) -> String {
        name.replacingOccurrences(of: "/", with: "-")
    }

    /// A stable filename keeps the temp directory from filling up with one file per share,
    /// and lets the OS reuse the same item on a repeat share.
    private static func write(_ data: Data, named name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
