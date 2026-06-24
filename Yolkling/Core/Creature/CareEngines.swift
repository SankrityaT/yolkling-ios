import Foundation

/// A kind streak: it advances on a day you care for your yolk, a single missed day
/// is absorbed by a free rest token (it PAUSES, never shatters), and a longer gap
/// resets gently without taking anything away. Weekly care earns a rest token back.
/// No guilt, no punishment (see docs/MONETIZATION.md).
enum StreakEngine {
    struct Result { let streak: Int; let restTokens: Int; let restUsed: Bool }

    static func recordCare(streak: Int, lastCare: Date?, restTokens: Int, today: Date = .now) -> Result {
        let cal = Calendar.current
        guard let last = lastCare else { return Result(streak: max(streak, 1), restTokens: restTokens, restUsed: false) }
        if cal.isDateInToday(last) { return Result(streak: streak, restTokens: restTokens, restUsed: false) }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: today)).day ?? 0
        if days <= 1 {
            let s = streak + 1
            let earned = s % 7 == 0 ? 1 : 0                 // a rest token for a full week of care
            return Result(streak: s, restTokens: min(restTokens + earned, 3), restUsed: false)
        }
        if days == 2, restTokens > 0 {                       // one missed day, the token covers it
            return Result(streak: streak + 1, restTokens: restTokens - 1, restUsed: true)
        }
        return Result(streak: 1, restTokens: restTokens, restUsed: false)   // gentle reset, nothing taken
    }
}

/// Picks the next species to discover for the collection. The reward for caring is
/// a new friend (a "hunt" variable reward, ethically: real effort always pays, only
/// WHICH species is variable). Biases toward an active seasonal set so showing up
/// during the season fills its clock, without ever guaranteeing it.
enum DiscoveryEngine {
    static func pickNext(discovered: Set<String>) -> String? {
        let seasonal = SpeciesSets.all.first { $0.isSeasonal && ($0.seasonDaysLeft ?? 0) > 0 }
        let seasonalPool = (seasonal?.speciesIDs ?? []).filter { !discovered.contains($0) }
        if !seasonalPool.isEmpty, Int.random(in: 0..<100) < 65 {
            return seasonalPool.randomElement()
        }
        let allPool = Array(Set(SpeciesSets.all.flatMap { $0.speciesIDs })).filter { !discovered.contains($0) }
        return allPool.randomElement() ?? seasonalPool.randomElement()
    }
}
