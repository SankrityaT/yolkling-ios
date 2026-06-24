import WidgetKit
import SwiftUI

struct YolkEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let phase: YolkExpression.DayPhase
}

struct YolkRoomProvider: TimelineProvider {
    func placeholder(in context: Context) -> YolkEntry {
        YolkEntry(date: Date(), snapshot: nil, phase: .day)
    }

    func getSnapshot(in context: Context, completion: @escaping (YolkEntry) -> Void) {
        let hour = Calendar.current.component(.hour, from: Date())
        completion(YolkEntry(date: Date(),
                             snapshot: WidgetSnapshot.read(),
                             phase: YolkExpression.phase(forHour: hour)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<YolkEntry>) -> Void) {
        let snap = WidgetSnapshot.read()
        let cal = Calendar.current
        let now = Date()
        // One entry now, then one at each phase boundary over ~24h so the room
        // re-tints and the yolk gets sleepy at night without the app running.
        let boundaryHours = [0, 5, 11, 18, 22]
        var dates: [Date] = [now]
        for dayOffset in 0...1 {
            let base = cal.date(byAdding: .day, value: dayOffset, to: now) ?? now
            for h in boundaryHours {
                if let d = cal.date(bySettingHour: h, minute: 0, second: 0, of: base), d > now {
                    dates.append(d)
                }
            }
        }
        let entries = dates.sorted().map { d in
            YolkEntry(date: d, snapshot: snap,
                      phase: YolkExpression.phase(forHour: cal.component(.hour, from: d)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct YolkRoomEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: YolkEntry

    private var room: RoomSnapshot? { entry.snapshot?.room }
    private var theme: RoomTheme { room?.theme ?? RoomThemes.cozy }
    private var vibe: Vibe { room?.makeVibe(name: entry.snapshot?.name ?? "yolk") ?? .yolk }
    private var expression: YolkExpression {
        let base = room?.expression ?? YolkExpression.content
        return base.atPhase(entry.phase, sleptWell: false)
    }
    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Scale the room up slightly for small so the yolk fills more of the frame.
            let scaleFactor: CGFloat = isSmall ? 1.15 : 1.0
            RoomView(vibe: vibe,
                     expression: expression,
                     theme: theme,
                     outfit: room?.outfit ?? [],
                     decor: room?.decor ?? [])
                .scaleEffect(scaleFactor)
                .frame(width: w, height: h)
                .clipped()
                .overlay(alignment: .bottom) {
                    if entry.snapshot == nil {
                        Text("open yolkling")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                            .padding(.bottom, 8)
                    }
                }
        }
        .containerBackground(for: .widget) {
            theme.wall
        }
    }
}

struct YolkRoomWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "YolkRoomWidget", provider: YolkRoomProvider()) { entry in
            YolkRoomEntryView(entry: entry)
        }
        .configurationDisplayName("Your Yolk")
        .description("your yolk, living in its little room.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
