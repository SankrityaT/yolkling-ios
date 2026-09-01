import SwiftUI
import YolklingCore

/// The Yolkling+ paywall. Free play is never gated — this is the supporter tier
/// ("only if you love it, it keeps the servers on"). Clear price, restore, and
/// terms/privacy, per App Store guidelines.
struct PlusView: View {
    @State var store: SubscriptionStore
    var vibe: Vibe = .yolk

    @Environment(\.dismiss) private var dismiss
    @State private var dialog: YolkDialog?
    @State private var selectedID: String?

    /// Only things that actually ship.
    ///
    /// This list previously advertised five features, **none of which were built**:
    /// cloud backup, a supporter glow, seasonal species, multiple creatures. Selling
    /// unimplemented functionality is an App Store Guideline 3.1.2 rejection, and it's a
    /// straightforward lie to the person paying. Anything added back here has to exist
    /// first. See docs/CLAIMS.md.
    ///
    /// The glow line survived that cleanup and was STILL not built: `isPlus` reached two
    /// text badges in Profile and this view's own footer, and never reached the creature.
    /// So the paywall promised a visible change to your yolk and buying it changed
    /// nothing you could see. It ships now, as `SupporterGlow` in Core/Creature, drawn at
    /// every place the app renders your own creature: here, Home, Profile and Focus.
    ///
    /// The other two lines are checked and true. The monthly Yolks are real via
    /// `SubscriptionStore.claimStipend()`, wired into HomeView, reading the RevenueCat
    /// virtual-currency balance. There is no ad SDK anywhere in the project.
    private let perks: [(String, String)] = [
        ("sparkles",   "a supporter glow on your yolk, so it's visibly yours"),
        ("leaf.fill",  "a monthly handful of Yolks, on the house"),
        ("heart.fill", "you keep this whole thing alive. no ads, ever"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: YolkSpace.lg) {
                    YolklingView(vibe: vibe, expression: .happy, size: 120, supporterGlow: store.isPlus).frame(height: 150)
                    // The real guard against shipping a Test Store key: it shows up in
                    // TestFlight and in App Review, where a human will see it. An
                    // `assert` cannot do this job — it's compiled out in release.
                    if RevenueCatConfig.isTestStore {
                        Text("TEST STORE — purchases here are simulated, not real")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: 0xE05A6E), in: RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(spacing: 6) {
                        Text("yolkling+").font(YolkType.title).foregroundStyle(YolkColor.ink)
                        Text("free to hatch, always. this is just for when you love it.")
                            .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: YolkSpace.md) {
                        ForEach(perks, id: \.1) { perk in
                            HStack(alignment: .top, spacing: YolkSpace.md) {
                                Image(systemName: perk.0).font(.title3).foregroundStyle(YolkColor.yolkDeep).frame(width: 30)
                                Text(perk.1).font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.horizontal, YolkSpace.sm)
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.top, YolkSpace.md)
            }
            footer
        }
        .background(YolkColor.shell)
        .yolkDialog($dialog)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft).padding(10).background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg).padding(.top, YolkSpace.sm)
    }

    @ViewBuilder private var footer: some View {
        VStack(spacing: YolkSpace.sm) {
            if store.isPlus {
                Text("you're a supporter ♥ thank you, truly.")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    .padding(.vertical, 14)
            } else {
                if store.loadState == .unavailable {
                    // Honest, and it does not blame the person or pretend to be
                    // loading. Free play is genuinely unaffected, so say so.
                    VStack(spacing: 6) {
                        Text("the supporter tier isn't available right now")
                            .font(YolkType.bodySmall.weight(.semibold))
                            .foregroundStyle(YolkColor.ink)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("nothing is wrong with your yolkling. everything in the app still works.")
                            .font(.caption2)
                            .foregroundStyle(YolkColor.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            Haptics.shared.tick()
                            Task { await store.loadOfferings() }
                        } label: {
                            Text("try again")
                                .font(YolkType.bodySmall.weight(.semibold))
                                .foregroundStyle(YolkColor.shell)
                                .padding(.horizontal, YolkSpace.md).padding(.vertical, 8)
                                .background(YolkColor.ink, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, YolkSpace.sm)
                } else {
                    planPicker

                    Button { subscribe() } label: {
                    VStack(spacing: 2) {
                        if store.purchasing {
                            // Was a literal "…", which is indistinguishable from truncated
                            // text and says nothing about whether anything is happening.
                            PurchasingIndicator()
                                .frame(height: 20)
                                .transition(.opacity)
                        } else {
                            Text("become a supporter")
                                .font(YolkType.body.weight(.semibold))
                            Text(ctaSubtitle).font(.caption2).opacity(0.9)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: store.purchasing)
                    .foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(YolkColor.ink, in: Capsule())
                }
                    .buttonStyle(.plain)
                    .disabled(store.purchasing || chosen == nil)
                }
            }
            HStack(spacing: YolkSpace.md) {
                Button("restore") { Task { await store.restore() } }
                Link("terms", destination: URL(string: "https://yolkling.com/terms")!)
                Link("privacy", destination: URL(string: "https://yolkling.com/privacy")!)
            }
            .font(.caption2).foregroundStyle(YolkColor.muted)
        }
        .padding(.horizontal, YolkSpace.lg).padding(.vertical, YolkSpace.md)
        .background(YolkColor.shell)
    }

    /// The plan the person is buying. Falls back to the store's default (annual when
    /// there is one) until they touch anything.
    private var chosen: SubscriptionStore.Plan? {
        store.plans.first { $0.id == selectedID } ?? store.defaultPlan
    }

    /// What the button says underneath. Never invents a price: if the offering has not
    /// loaded there is nothing to promise, so it says nothing.
    private var ctaSubtitle: String {
        guard let p = chosen else { return "loading…" }
        return "\(p.price) / \(p.isAnnual ? "year" : "month") · cancel anytime"
    }

    /// Both plans, side by side.
    ///
    /// Shown as a choice rather than a single lead package. The paywall used to render
    /// exactly one option (`offering?.monthly`), so an annual plan configured in the
    /// dashboard would have been invisible and unbuyable with no error anywhere.
    @ViewBuilder private var planPicker: some View {
        if store.plans.count > 1 {
            HStack(spacing: YolkSpace.sm) {
                ForEach(store.plans) { plan in
                    planCard(plan)
                }
            }
        }
    }

    private func planCard(_ plan: SubscriptionStore.Plan) -> some View {
        let isOn = chosen?.id == plan.id
        return Button {
            Haptics.shared.select()
            withAnimation(.snappy) { selectedID = plan.id }
        } label: {
            VStack(spacing: 3) {
                Text(plan.title)
                    .font(YolkType.bodySmall.weight(.semibold))
                    .foregroundStyle(YolkColor.ink)
                Text(plan.price)
                    .font(YolkType.body.weight(.bold))
                    .foregroundStyle(YolkColor.ink)
                // The per-month figure is what makes the two comparable at a glance.
                // Without it "$34.99" and "$4.99" look like the expensive one and the
                // cheap one, which is the opposite of the truth.
                Text(plan.perMonth ?? " ")
                    .font(.caption2)
                    .foregroundStyle(YolkColor.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, YolkSpace.sm)
            // The unselected card keeps a container. With a clear background and no
            // border it read as floating text rather than the other half of a choice,
            // so the monthly plan looked like a caption next to the real option.
            .background(isOn ? YolkColor.shell2 : YolkColor.shell2.opacity(0.45),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isOn ? YolkColor.ink : YolkColor.line, lineWidth: isOn ? 2 : 1)
            )
            .overlay(alignment: .top) {
                // Only ever drawn from real prices. `annualSavingPercent` returns nil
                // unless both plans actually loaded, so this cannot print a number the
                // store did not produce.
                if plan.isAnnual, let pct = plan.savingPercent {
                    Text("save \(pct)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(YolkColor.shell)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(YolkColor.yolkDeep, in: Capsule())
                        .offset(y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func subscribe() {
        guard let plan = chosen else { return }
        Task {
            switch await store.subscribe(planID: plan.id) {
            case .success:
                Haptics.shared.reward()
                dialog = YolkDialog(icon: .creature(vibe, .affectionate), title: "you're a supporter!",
                                    message: "thank you for keeping yolkling alive. it means everything.", primaryTitle: "♥")
            case .cancelled:
                // Deliberately nothing. They changed their mind; saying so would be nagging.
                break
            case .failed(let why):
                // Anything other than a deliberate cancel HAS to say something. This
                // branch did not exist, so a failed purchase was a tap that did nothing
                // at all on a payment screen.
                Haptics.shared.warn()
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "that didn't go through",
                                    message: why, primaryTitle: "okay")
            }
        }
    }
}
