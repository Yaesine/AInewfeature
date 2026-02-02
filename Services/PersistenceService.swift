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

// MARK: - P0: Multi-workflow store + history (no backend)

final class WorkflowStore: ObservableObject {
    @Published private(set) var workflows: [StoredWorkflow]
    @Published var selectedWorkflowID: UUID

    private let defaults: UserDefaults
    private let legacyPersistence: PersistenceService

    private let workflowsKey = "stepflow.workflows.v1"
    private let selectedKey = "stepflow.workflows.selected.v1"
    private let migratedKey = "stepflow.workflows.didMigrateLegacy.v1"

    init(defaults: UserDefaults = .standard, legacyPersistence: PersistenceService = UserDefaultsPersistenceService()) {
        self.defaults = defaults
        self.legacyPersistence = legacyPersistence

        if let data = defaults.data(forKey: workflowsKey),
           let decoded = try? JSONDecoder().decode([StoredWorkflow].self, from: data),
           !decoded.isEmpty {
            self.workflows = decoded
            if let selected = defaults.string(forKey: selectedKey),
               let uuid = UUID(uuidString: selected),
               decoded.contains(where: { $0.id == uuid }) {
                self.selectedWorkflowID = uuid
            } else {
                self.selectedWorkflowID = decoded[0].id
            }
            return
        }

        // First launch (or pre-migration): migrate the legacy single workflow.
        let legacy = legacyPersistence.loadWorkflow()
        let initial = StoredWorkflow(workflow: legacy)
        self.workflows = [initial]
        self.selectedWorkflowID = initial.id
        persist()

        // Mark migration so we don't keep re-importing if legacy workflow changes later.
        defaults.set(true, forKey: migratedKey)
        defaults.set(String(initial.id.uuidString), forKey: selectedKey)
    }

    var selectedIndex: Int? {
        workflows.firstIndex(where: { $0.id == selectedWorkflowID })
    }

    var selectedWorkflow: Workflow {
        get {
            if let idx = selectedIndex { return workflows[idx].workflow }
            return workflows.first?.workflow ?? Workflow()
        }
        set {
            guard let idx = selectedIndex else { return }
            workflows[idx].workflow = newValue
            workflows[idx].updatedAt = Date()
            persist()
        }
    }

    var selectedStoredWorkflow: StoredWorkflow? {
        guard let idx = selectedIndex else { return nil }
        return workflows[idx]
    }

    func select(_ id: UUID) {
        guard workflows.contains(where: { $0.id == id }) else { return }
        selectedWorkflowID = id
        defaults.set(id.uuidString, forKey: selectedKey)
    }

    func createNewWorkflow(named name: String = "New Workflow") -> StoredWorkflow {
        let new = StoredWorkflow(workflow: Workflow(name: name))
        workflows.insert(new, at: 0)
        select(new.id)
        persist()
        return new
    }

    func delete(_ id: UUID) {
        workflows.removeAll(where: { $0.id == id })
        if workflows.isEmpty {
            let new = StoredWorkflow(workflow: Workflow())
            workflows = [new]
            selectedWorkflowID = new.id
        } else if !workflows.contains(where: { $0.id == selectedWorkflowID }) {
            selectedWorkflowID = workflows[0].id
        }
        persist()
    }

    func duplicate(_ id: UUID) -> StoredWorkflow? {
        guard let existing = workflows.first(where: { $0.id == id }) else { return nil }
        var copyWorkflow = existing.workflow
        copyWorkflow.name = "\(existing.workflow.name) Copy"
        // Give new IDs to blocks to avoid accidental edits in-place.
        copyWorkflow.blocks = copyWorkflow.blocks.map { Block(type: $0.type, instruction: $0.instruction, formatterOperation: $0.formatterOperation) }
        let dup = StoredWorkflow(workflow: copyWorkflow)
        workflows.insert(dup, at: 0)
        select(dup.id)
        persist()
        return dup
    }

    func rename(_ id: UUID, to name: String) {
        guard let idx = workflows.firstIndex(where: { $0.id == id }) else { return }
        workflows[idx].workflow.name = name
        workflows[idx].updatedAt = Date()
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(workflows) else { return }
        defaults.set(data, forKey: workflowsKey)
        defaults.set(selectedWorkflowID.uuidString, forKey: selectedKey)
    }
}

final class HistoryStore: ObservableObject {
    @Published private(set) var items: [HistoryItem]

    private let defaults: UserDefaults
    private let historyKey = "stepflow.history.v1"
    private let migratedLegacyKey = "stepflow.history.didMigrateLegacy.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            self.items = decoded
        } else {
            self.items = []
        }

        // Seamless migration: import legacy per-workflow history if present.
        if items.isEmpty, defaults.bool(forKey: migratedLegacyKey) == false {
            let legacy = UserDefaultsPersistenceService(defaults: defaults).loadWorkflow()
            if !legacy.history.isEmpty {
                self.items = legacy.history
                    .sorted(by: { $0.date > $1.date })
                    .prefix(20)
                    .map { old in
                        HistoryItem(
                            date: old.date,
                            workflowName: legacy.name,
                            inputSnippet: "",
                            output: old.output,
                            trace: []
                        )
                    }
                persist()
            }
            defaults.set(true, forKey: migratedLegacyKey)
        }
    }

    func add(workflowName: String, input: String, output: String, trace: [WorkflowTraceStep], isPro: Bool) {
        let snippet = String(input.prefix(200))
        let item = HistoryItem(workflowName: workflowName, inputSnippet: snippet, output: output, trace: trace)
        items.insert(item, at: 0)
        let limit = isPro ? 50 : 5
        items = Array(items.prefix(limit))
        persist()
    }

    func delete(_ id: UUID) {
        items.removeAll(where: { $0.id == id })
        persist()
    }

    func clear() {
        items = []
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: historyKey)
    }
}
