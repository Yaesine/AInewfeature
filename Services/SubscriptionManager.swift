import Foundation
import Combine

protocol SubscriptionManaging: ObservableObject {
    var isPro: Bool { get }
    var dailyRunCount: Int { get }
    var maxFreeBlocks: Int { get }
    var maxFreeRuns: Int { get }

    func recordRun()
    func resetRunsIfNeeded()
    func canAddBlock(currentCount: Int) -> Bool
    func canRunWorkflow() -> Bool
    func toggleProForDebug()
}

final class MockSubscriptionManager: SubscriptionManaging {
    @Published private(set) var isPro: Bool
    @Published private(set) var dailyRunCount: Int

    let maxFreeBlocks = 3
    let maxFreeRuns = 10

    private let defaults: UserDefaults
    private let isProKey = "stepflow.isPro"
    private let runCountKey = "stepflow.runCount"
    private let runDateKey = "stepflow.runDate"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isPro = defaults.bool(forKey: isProKey)
        self.dailyRunCount = defaults.integer(forKey: runCountKey)
        resetRunsIfNeeded()
    }

    func recordRun() {
        resetRunsIfNeeded()
        dailyRunCount += 1
        defaults.set(dailyRunCount, forKey: runCountKey)
        defaults.set(Date(), forKey: runDateKey)
    }

    func resetRunsIfNeeded() {
        guard let lastRunDate = defaults.object(forKey: runDateKey) as? Date else {
            return
        }
        if !Calendar.current.isDateInToday(lastRunDate) {
            dailyRunCount = 0
            defaults.set(0, forKey: runCountKey)
        }
    }

    func canAddBlock(currentCount: Int) -> Bool {
        if isPro { return true }
        return currentCount < maxFreeBlocks
    }

    func canRunWorkflow() -> Bool {
        if isPro { return true }
        return dailyRunCount < maxFreeRuns
    }

    func toggleProForDebug() {
        #if DEBUG
        isPro.toggle()
        defaults.set(isPro, forKey: isProKey)
        #endif
    }
}
