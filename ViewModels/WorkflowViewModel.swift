import Foundation

@MainActor
final class WorkflowViewModel: ObservableObject {
    @Published var workflow: Workflow
    @Published var isRunning = false
    @Published var currentStepIndex = 0
    @Published var outputText: String = ""
    @Published var errorMessage: String?
    @Published var showPaywall = false
    @Published var showOutput = false

    let subscriptionManager: SubscriptionManaging
    let settingsViewModel: SettingsViewModel

    private let persistence: PersistenceService
    private let runner: WorkflowRunner
    private var runTask: Task<Void, Never>?

    init(
        persistence: PersistenceService = UserDefaultsPersistenceService(),
        subscriptionManager: SubscriptionManaging = MockSubscriptionManager(),
        settingsViewModel: SettingsViewModel? = nil
    ) {
        self.persistence = persistence
        self.subscriptionManager = subscriptionManager
        let settingsVM = settingsViewModel ?? SettingsViewModel(persistence: persistence)
        self.settingsViewModel = settingsVM
        self.runner = WorkflowRunner(openAIClient: OpenAIClient())
        self.workflow = persistence.loadWorkflow()
    }

    func updateWorkflowName(_ name: String) {
        workflow.name = name
        saveWorkflow()
    }

    func updateInputText(_ text: String) {
        workflow.inputText = text
        saveWorkflow()
    }

    func addBlock(_ block: Block) {
        subscriptionManager.resetRunsIfNeeded()
        guard subscriptionManager.canAddBlock(currentCount: workflow.blocks.count) else {
            showPaywall = true
            return
        }
        workflow.blocks.append(block)
        saveWorkflow()
    }

    func deleteBlock(at offsets: IndexSet) {
        workflow.blocks.remove(atOffsets: offsets)
        saveWorkflow()
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        workflow.blocks.move(fromOffsets: source, toOffset: destination)
        saveWorkflow()
    }

    func updateBlock(_ block: Block) {
        guard let index = workflow.blocks.firstIndex(where: { $0.id == block.id }) else { return }
        workflow.blocks[index] = block
        saveWorkflow()
    }

    func runWorkflow() {
        guard !workflow.inputText.trimmed.isEmpty else { return }
        guard !workflow.blocks.isEmpty else { return }
        subscriptionManager.resetRunsIfNeeded()
        guard subscriptionManager.canRunWorkflow() else {
            showPaywall = true
            return
        }

        errorMessage = nil
        isRunning = true
        currentStepIndex = 0
        outputText = ""

        let settings = settingsViewModel.settings
        let blocks = workflow.blocks
        runTask?.cancel()
        runTask = Task {
            do {
                let output = try await self.runner.run(blocks: blocks, input: self.workflow.inputText, settings: settings) { step, total in
                    self.currentStepIndex = step
                }
                self.outputText = output
                self.saveWorkflow()
                self.subscriptionManager.recordRun()
                self.showOutput = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isRunning = false
        }
    }

    func cancelRun() {
        runTask?.cancel()
        isRunning = false
    }

    func saveWorkflow() {
        persistence.saveWorkflow(workflow)
    }
}
