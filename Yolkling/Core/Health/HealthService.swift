import HealthKit
import SwiftUI

/// Reads the real-life signals that feed the yolk: today's steps and last night's
/// sleep (the "grow by living" loop). Read-only and gentle. Screen Time (time off
/// the phone) is the other half, gated behind the Family Controls entitlement.
@MainActor @Observable
final class HealthService {
    private let store = HKHealthStore()

    private(set) var steps: Int = 0
    private(set) var sleepHours: Double = 0
    private(set) var authorized = false

    var available: Bool { HKHealthStore.isHealthDataAvailable() }

    /// 0..1 read of how well you're living today (steps vs goal + sleep vs 7h). Drives
    /// the creature's liveliness. Neutral (0.5) until connected.
    var vitality: Double {
        guard authorized else { return 0.5 }
        let s = min(1.0, Double(steps) / 5000)
        let z = min(1.0, sleepHours / 7)
        return (s + z) / 2
    }

    private var readTypes: Set<HKObjectType> {
        [HKQuantityType(.stepCount), HKCategoryType(.sleepAnalysis)]
    }

    /// Ask permission, then load today's numbers. Returns whether we can read.
    @discardableResult
    func connect() async -> Bool {
        guard available else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            authorized = true
            await refresh()
            return true
        } catch {
            return false
        }
    }

    /// Re-enable reads for a player who connected on a previous launch (no prompt).
    func resume() async {
        guard available else { return }
        authorized = true
        await refresh()
    }

    func refresh() async {
        guard available else { return }
        async let s = readSteps()
        async let z = readSleepHours()
        let (st, sl) = await (s, z)
        steps = st
        sleepHours = sl
    }

    private func readSteps() async -> Int {
        let type = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0))
            }
            store.execute(q)
        }
    }

    private func readSleepHours() async -> Double {
        let type = HKCategoryType(.sleepAnalysis)
        // Window: from 6pm the previous evening to now, so "last night" is captured.
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .hour, value: -6, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(-86_400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let secs = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: secs / 3600)
            }
            store.execute(q)
        }
    }

    #if DEBUG
    /// Dev only: fake a good day in-memory so the card can be verified without the
    /// Health permission prompt (which can't be tapped in an automated screenshot).
    func mock(high: Bool = true) {
        authorized = true
        steps = high ? 7200 : 700
        sleepHours = high ? 7.5 : 3.0
    }

    /// Dev only: write a sample day so the grow-by-living card can be verified in the
    /// simulator (which has no real steps/sleep).
    func seedSampleDay() async {
        guard available else { return }
        let share: Set<HKSampleType> = [HKQuantityType(.stepCount), HKCategoryType(.sleepAnalysis)]
        try? await store.requestAuthorization(toShare: share, read: readTypes)
        authorized = true
        let cal = Calendar.current
        let now = Date()
        let dayStart = cal.startOfDay(for: now)
        let stepSample = HKQuantitySample(
            type: HKQuantityType(.stepCount),
            quantity: HKQuantity(unit: .count(), doubleValue: 7200),
            start: dayStart.addingTimeInterval(8 * 3600), end: now)
        let sleepEnd = dayStart.addingTimeInterval(7 * 3600)
        let sleepStart = sleepEnd.addingTimeInterval(-7.5 * 3600)
        let sleepSample = HKCategorySample(
            type: HKCategoryType(.sleepAnalysis),
            value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            start: sleepStart, end: sleepEnd)
        try? await store.save([stepSample, sleepSample])
        await refresh()
    }
    #endif
}
