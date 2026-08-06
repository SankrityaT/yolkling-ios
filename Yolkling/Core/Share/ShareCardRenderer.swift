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

        // A stable filename per creature keeps the temp directory from filling up with
        // one file per share, and lets the OS reuse the same item on a repeat share.
        let safeName = creatureName.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yolkling-\(safeName).png")

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
