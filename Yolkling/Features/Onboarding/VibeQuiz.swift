import SwiftUI
import YolklingCore

/// Three silly questions that hand you a creature.
///
/// The landing page has always promised this — *"tell it your vibe, three silly
/// questions"* — while the app asked you to pick a hex swatch from a grid. That gap was
/// the last ⚠️ in CLAIMS.md.
///
/// It's also just better onboarding. Picking a colour is a settings screen; answering
/// "your phone dies, how do you feel" and being handed a creature is a small act of
/// self-description, and you own the result in a way you never own a swatch you tapped.
/// That's the IKEA effect, lever 2 in docs/MONETIZATION.md. It gives people something to
/// say out loud, too — "I got the sleepy garden one" — which a colour picker never will.
///
/// Every question visibly changes one thing, so no answer feels wasted: where you are
/// picks the LOOK, what you'd eat picks the COLOUR, and the phone question picks the MOOD.
enum VibeQuiz {

    struct Answer: Identifiable, Equatable {
        let id: String
        let text: String
        var color: UInt? = nil
        var style: CreatureStyle? = nil
        var mood: Mood? = nil
    }

    struct Question: Identifiable, Equatable {
        let id: String
        let prompt: String
        let answers: [Answer]
    }

    static let questions: [Question] = [
        Question(id: "where", prompt: "it's 3pm on a saturday. where are you?", answers: [
            Answer(id: "bed",     text: "still in bed, honestly",        style: .tuft),
            Answer(id: "outside", text: "outside, somewhere green",      style: .sprout),
            Answer(id: "people",  text: "somewhere loud, with people",   style: .ears),
            Answer(id: "rearrange", text: "rearranging my entire room",  style: .tulipBud),
        ]),
        Question(id: "snack", prompt: "pick a snack. don't think about it.", answers: [
            Answer(id: "warm",   text: "something warm",   color: 0xE7B68C),
            Answer(id: "fizzy",  text: "something fizzy",  color: 0x8FD0FF),
            Answer(id: "sweet",  text: "something sweet",  color: 0xFF94C2),
            Answer(id: "closest", text: "whatever's closest", color: 0xFFC23B),
        ]),
        Question(id: "phone", prompt: "your phone dies. you feel…", answers: [
            Answer(id: "free",    text: "free, genuinely",          mood: .happy),
            Answer(id: "twitchy", text: "a little twitchy",         mood: .curious),
            Answer(id: "fine",    text: "fine. i'll read something", mood: .content),
            Answer(id: "charger", text: "already finding a charger", mood: .excited),
        ]),
    ]

    /// What the answers add up to. Anything unanswered keeps the existing default rather
    /// than snapping to something arbitrary.
    struct Result: Equatable {
        var color: UInt = CreaturePalette.colors[0]
        var style: CreatureStyle = .classic
        var mood: Mood = .happy
    }

    static func result(from picks: [String: Answer]) -> Result {
        var r = Result()
        for a in picks.values {
            if let c = a.color { r.color = c }
            if let s = a.style { r.style = s }
            if let m = a.mood  { r.mood = m }
        }
        return r
    }
}

/// The quiz itself: one question at a time, with the creature forming as you answer.
///
/// Showing the creature react to each answer is the whole point — it turns three taps
/// into watching something become yours, rather than filling in a form and being shown
/// the output at the end.
struct VibeQuizView: View {
    @State var model: HatchModel
    var onDone: () -> Void

    @State private var index = 0
    @State private var picks: [String: VibeQuiz.Answer] = [:]

    private var question: VibeQuiz.Question { VibeQuiz.questions[index] }

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer(minLength: 0)

            // Forms in front of you as you answer.
            YolklingView(vibe: model.vibe, expression: model.startingMood.expression, size: 150)
                .frame(height: 190)
                .animation(.snappy(duration: 0.35), value: model.colorHex)
                .animation(.snappy(duration: 0.35), value: model.style)

            VStack(spacing: 6) {
                Text(question.prompt)
                    .font(YolkType.heading).foregroundStyle(YolkColor.ink)
                    .multilineTextAlignment(.center)
                Text("question \(index + 1) of \(VibeQuiz.questions.count)")
                    .font(.caption2).foregroundStyle(YolkColor.muted)
            }
            .padding(.horizontal, YolkSpace.lg)

            VStack(spacing: YolkSpace.sm) {
                ForEach(question.answers) { answer in
                    Button { pick(answer) } label: {
                        Text(answer.text)
                            .font(YolkType.body)
                            .foregroundStyle(YolkColor.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 15).padding(.horizontal, YolkSpace.md)
                            .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, YolkSpace.lg)

            Spacer(minLength: 0)

            // An escape hatch. Some people just want to pick a colour, and making them
            // answer questions first would be the app being precious about itself.
            Button { onDone() } label: {
                Text("i'd rather just pick").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
            .buttonStyle(.plain)
            .padding(.bottom, YolkSpace.lg)
        }
        .background(YolkColor.shell)
    }

    private func pick(_ answer: VibeQuiz.Answer) {
        Haptics.shared.select()
        picks[question.id] = answer

        // Apply immediately so the creature changes under your thumb.
        let r = VibeQuiz.result(from: picks)
        withAnimation(.snappy(duration: 0.35)) {
            model.colorHex = r.color
            model.style = r.style
            model.startingMood = r.mood
        }

        if index + 1 < VibeQuiz.questions.count {
            withAnimation(.easeInOut(duration: 0.25)) { index += 1 }
        } else {
            Haptics.shared.reward()
            onDone()
        }
    }
}
