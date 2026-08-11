import SwiftUI
import YolklingCore

/// A warm, direct line to the maker. Writes to Supabase (write-only RPC). Reached
/// from the profile sheet. No account needed; tagged with the install/Apple id so
/// a reply path exists later.
struct FeedbackView: View {
    let vibe: Vibe
    let userID: String

    @Environment(\.dismiss) private var dismiss
    @State private var kind = "idea"
    @State private var message = ""
    @State private var working = false
    @State private var sent = false

    private let kinds = ["idea", "bug", "love", "other"]
    private var trimmed: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Capsule().fill(YolkColor.line).frame(width: 40, height: 5).padding(.top, YolkSpace.sm)
            if sent { thankYou } else { form }
            Spacer(minLength: 0)
        }
        .background(YolkColor.shell)
    }

    private var form: some View {
        VStack(spacing: YolkSpace.lg) {
            VStack(spacing: 6) {
                Text("share a thought")
                    .font(YolkType.heading).foregroundStyle(YolkColor.ink)
                Text("this goes straight to the one person who makes yolkling.")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: YolkSpace.sm) {
                ForEach(kinds, id: \.self) { k in
                    let on = kind == k
                    Button { kind = k; Haptics.shared.tick() } label: {
                        Text(k).font(YolkType.body.weight(.semibold))
                            .foregroundStyle(on ? YolkColor.shell : YolkColor.inkSoft)
                            .padding(.vertical, 8).padding(.horizontal, 16)
                            .background(on ? YolkColor.ink : YolkColor.shell2, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("what's on your mind?", text: $message, axis: .vertical)
                .lineLimit(4...8)
                .font(YolkType.body).foregroundStyle(YolkColor.ink).tint(YolkColor.ink)
                .padding(YolkSpace.md)
                .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, YolkSpace.lg)

            Button { Task { await send() } } label: {
                Text(working ? "sending..." : "send")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(YolkColor.ink.opacity(trimmed.isEmpty ? 0.3 : 1), in: Capsule())
            }
            .buttonStyle(.plain).disabled(trimmed.isEmpty || working)
            .padding(.horizontal, YolkSpace.lg)
        }
        .padding(.top, YolkSpace.sm)
    }

    private var thankYou: some View {
        VStack(spacing: YolkSpace.md) {
            YolklingView(vibe: vibe, expression: .affectionate, size: 130).frame(height: 160)
            Text("thank you. truly.")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("every note gets read by a real person.")
                .font(YolkType.body).foregroundStyle(YolkColor.muted)
            Button { dismiss() } label: {
                Text("done").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(YolkColor.ink, in: Capsule())
            }
            .buttonStyle(.plain).padding(.horizontal, YolkSpace.lg).padding(.top, YolkSpace.sm)
        }
        .padding(.top, YolkSpace.xl)
    }

    private func send() async {
        guard !trimmed.isEmpty, !working else { return }
        working = true
        let ok = await SupabaseClient.shared.submitFeedback(userID: userID, kind: kind, message: trimmed, version: appVersion)
        working = false
        if ok {
            Haptics.shared.reward()
            withAnimation(.easeInOut(duration: 0.3)) { sent = true }
        } else {
            Haptics.shared.warn()
        }
    }
}
