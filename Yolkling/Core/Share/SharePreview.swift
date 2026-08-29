import SwiftUI
import YolklingCore

/// Screenshot seam (`YOLK_CARD=1`) for the share card.
///
/// Shows the card as SwiftUI renders it live, AND rasterises it through
/// `ShareCardRenderer` so the two can be compared. That comparison is the point: an
/// `ImageRenderer` pass can silently differ from the on-screen view — most obviously by
/// rendering the creature blank, since it cannot capture `TimelineView(.animation)`.
/// If the bottom image matches the top, the `frozenAt:` seam is doing its job.
struct SharePreview: View {
    private let snapshot = RoomSnapshot(
        colorHex: 0xFFC23B, styleRaw: "plain", accentHex: nil, patternRaw: "none",
        activeFoundingID: nil, moodRaw: "happy", themeID: "room-cozy",
        decorIDs: [], outfitIDs: []
    )

    @State private var rendered: UIImage?
    @State private var status = "rendering…"

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("live view").font(YolkType.label).foregroundStyle(YolkColor.muted)
                card.border(YolkColor.line)

                Text("ImageRenderer output").font(YolkType.label).foregroundStyle(YolkColor.muted)
                if let rendered {
                    Image(uiImage: rendered)
                        .resizable().scaledToFit()
                        .frame(width: PostcardCard.size.width)
                        .border(YolkColor.line)
                } else {
                    Rectangle().fill(YolkColor.shell2)
                        .frame(width: PostcardCard.size.width, height: PostcardCard.size.height)
                }
                Text(status).font(YolkType.label).foregroundStyle(YolkColor.inkSoft)
            }
            .padding(20)
        }
        .background(YolkColor.shell)
        .task {
            guard let url = ShareCardRenderer.render(
                snapshot: snapshot, creatureName: "Yolky",
                phrase: "came by to say hi", inviteCode: "YOLK-AB12"
            ) else { status = "RENDER FAILED"; return }

            let bytes = (try? Data(contentsOf: url).count) ?? 0
            rendered = UIImage(contentsOfFile: url.path)
            let px = rendered.map { "\(Int($0.size.width * $0.scale))x\(Int($0.size.height * $0.scale))" } ?? "?"
            status = "\(px) · \(bytes / 1024) KB\n\(url.path)"
        }
    }

    private var card: some View {
        PostcardCard(snapshot: snapshot, creatureName: "Yolky",
                     phrase: "came by to say hi", inviteCode: "YOLK-AB12")
    }
}
