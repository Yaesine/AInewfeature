import Foundation

protocol PersistenceService {
    func loadWorkflow() -> Workflow
    func saveWorkflow(_ workflow: Workflow)
    func loadSettings() -> SettingsStore
    func saveSettings(_ settings: SettingsStore)
}

final class UserDefaultsPersistenceService: PersistenceService {
    private let workflowKey = "stepflow.workflow"
    private let settingsKey = "stepflow.settings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadWorkflow() -> Workflow {
        guard let data = defaults.data(forKey: workflowKey),
              let workflow = try? JSONDecoder().decode(Workflow.self, from: data) else {
            return Workflow()
        }
        return workflow
    }

    func saveWorkflow(_ workflow: Workflow) {
        guard let data = try? JSONEncoder().encode(workflow) else { return }
        defaults.set(data, forKey: workflowKey)
    }

    func loadSettings() -> SettingsStore {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(SettingsStore.self, from: data) else {
            return SettingsStore()
        }
        return settings
    }

    func saveSettings(_ settings: SettingsStore) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }
}
