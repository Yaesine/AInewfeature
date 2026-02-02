import Foundation
import Combine

@MainActor
final class WorkflowsViewModel: ObservableObject {
    static let maxInputCharacters = 12_000

    @Published var isRunning = false
    @Published var currentStepIndex = 0
    @Published var outputText: String = ""
    @Published var outputTrace: [WorkflowTraceStep] = []
    @Published var errorMessage: String?

    @Published var showPaywall = false
    @Published var paywallReason: String = ""
    @Published var showOutput = false
    @Published var showSettings = false
    @Published var showWorkflows = false

    let subscriptionManager: MockSubscriptionManager
    let settingsViewModel: SettingsViewModel
    let store: WorkflowStore
    let historyStore: HistoryStore

    private let runner: WorkflowRunner
    private var runTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    // Quick Actions (free: 3/day, pro: unlimited)
    private let defaults: UserDefaults
    private let quickCountKey = "stepflow.quickActions.count"
    private let quickDateKey = "stepflow.quickActions.date"
    private let maxFreeQuickActions = 3

    enum QuickAction: CaseIterable, Identifiable {
        case fixGrammar
        case rewritePro
        case summarize
        case bulletPoints
        case translateFR

        var id: String { title }

        var title: String {
            switch self {
            case .fixGrammar: return "Fix Grammar"
            case .rewritePro: return "Rewrite Pro"
            case .summarize: return "Summarize"
            case .bulletPoints: return "Bullet Points"
            case .translateFR: return "Translate FR"
            }
        }

        var systemImage: String {
            switch self {
            case .fixGrammar: return "wand.and.stars"
            case .rewritePro: return "briefcase.fill"
            case .summarize: return "text.justify.left"
            case .bulletPoints: return "list.bullet"
            case .translateFR: return "globe.europe.africa.fill"
            }
        }
    }

    init(
        store: WorkflowStore = WorkflowStore(),
        historyStore: HistoryStore = HistoryStore(),
        subscriptionManager: MockSubscriptionManager = MockSubscriptionManager(),
        settingsViewModel: SettingsViewModel? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.store = store
        self.historyStore = historyStore
        self.subscriptionManager = subscriptionManager
        self.defaults = defaults

        let settingsVM = settingsViewModel ?? SettingsViewModel(persistence: UserDefaultsPersistenceService())
        self.settingsViewModel = settingsVM
        self.runner = WorkflowRunner(openAIClient: OpenAIClient())

        // Forward nested ObservableObject changes (store/history/subscription) to SwiftUI.
        store.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        historyStore.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        subscriptionManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Selected workflow

    var workflow: Workflow {
        get { store.selectedWorkflow }
        set { store.selectedWorkflow = newValue }
    }

    var workflows: [StoredWorkflow] { store.workflows }

    func selectWorkflow(_ id: UUID) {
        store.select(id)
    }

    // MARK: - CRUD (gated)

    func createNewWorkflow() {
        if !subscriptionManager.isPro, store.workflows.count >= 1 {
            showPaywallFor("Free plan allows 1 saved workflow. Upgrade to Pro for unlimited workflows.")
            return
        }
        _ = store.createNewWorkflow(named: "New Workflow")
    }

    func duplicateWorkflow(_ id: UUID) {
        if !subscriptionManager.isPro, store.workflows.count >= 1 {
            showPaywallFor("Free plan allows 1 saved workflow. Upgrade to Pro for unlimited workflows.")
            return
        }
        _ = store.duplicate(id)
    }

    func deleteWorkflow(_ id: UUID) {
        store.delete(id)
    }

    func renameWorkflow(_ id: UUID, to name: String) {
        store.rename(id, to: name)
    }

    // MARK: - Editing

    func updateWorkflowName(_ name: String) {
        var w = workflow
        w.name = name
        workflow = w
    }

    func updateInputText(_ text: String) {
        var w = workflow
        w.inputText = text
        workflow = w
    }

    func addBlock(_ block: Block) {
        subscriptionManager.resetRunsIfNeeded()
        guard subscriptionManager.canAddBlock(currentCount: workflow.blocks.count) else {
            showPaywallFor("Free plan allows up to \(subscriptionManager.maxFreeBlocks) steps. Upgrade to Pro for unlimited steps.")
            return
        }
        var w = workflow
        w.blocks.append(block)
        workflow = w
    }

    func deleteBlock(at offsets: IndexSet) {
        var w = workflow
        w.blocks.remove(atOffsets: offsets)
        workflow = w
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        var w = workflow
        w.blocks.move(fromOffsets: source, toOffset: destination)
        workflow = w
    }

    func updateBlock(_ block: Block) {
        var w = workflow
        guard let index = w.blocks.firstIndex(where: { $0.id == block.id }) else { return }
        w.blocks[index] = block
        workflow = w
    }

    func deleteBlock(id: UUID) {
        var w = workflow
        w.blocks.removeAll(where: { $0.id == id })
        workflow = w
    }

    func moveBlock(id: UUID, direction: Int) {
        guard direction != 0 else { return }
        var w = workflow
        guard let index = w.blocks.firstIndex(where: { $0.id == id }) else { return }
        let newIndex = max(0, min(w.blocks.count - 1, index + direction))
        guard newIndex != index else { return }
        let block = w.blocks.remove(at: index)
        w.blocks.insert(block, at: newIndex)
        workflow = w
    }

    // MARK: - Run (with trace + safety limits)

    func runWorkflow() {
        let input = workflow.inputText
        guard !input.trimmed.isEmpty else {
            errorMessage = "Paste or type some text first."
            return
        }
        guard input.count <= Self.maxInputCharacters else {
            errorMessage = "Input is too long (\(input.count) characters). Max is \(Self.maxInputCharacters)."
            return
        }
        guard !workflow.blocks.isEmpty else {
            errorMessage = "Add at least one step first."
            return
        }

        // Preflight: if AI is required and we're in OpenAI mode without a key, route to Settings.
        let settings = settingsViewModel.settings
        let requiresAI = workflow.blocks.contains(where: { block in
            if block.type == .ai { return true }
            if block.type == .formatter, block.formatterOperation?.kind == .fixGrammar { return true } // Fix grammar uses AI
            return false
        })
        if requiresAI, settings.aiMode == .openAI, settingsViewModel.apiKeyInput.trimmed.isEmpty {
            // Avoid presenting an alert and a sheet at the same time (SwiftUI warning).
            errorMessage = nil
            settingsViewModel.testStatusMessage = "No API key found. Add your OpenAI key or switch to Demo AI."
            showSettings = true
            return
        }

        subscriptionManager.resetRunsIfNeeded()
        guard subscriptionManager.canRunWorkflow() else {
            showPaywallFor("You’ve hit today’s free run limit. Upgrade to Pro for unlimited runs.")
            return
        }

        errorMessage = nil
        isRunning = true
        currentStepIndex = 0
        outputText = ""
        outputTrace = []

        let blocks = workflow.blocks
        let workflowName = workflow.name

        AppLog.ui.info("UI(runWorkflow) name=\(workflowName, privacy: .private(mask: .hash)) blocks=\(blocks.count, privacy: .public) inputChars=\(input.count, privacy: .public)")

        runTask?.cancel()
        runTask = Task {
            do {
                let result = try await self.runner.runWithTrace(blocks: blocks, input: input, settings: settings) { step, total in
                    Task { @MainActor [weak self] in
                        self?.currentStepIndex = step
                    }
                }
                self.outputText = result.finalOutput
                self.outputTrace = result.steps

                self.subscriptionManager.recordRun()
                self.historyStore.add(
                    workflowName: workflowName,
                    input: input,
                    output: result.finalOutput,
                    trace: result.steps,
                    isPro: self.subscriptionManager.isPro
                )

                self.showOutput = true
            } catch {
                AppLog.ui.error("UI(runWorkflow error) \(error.localizedDescription, privacy: .public)")
                if let workflowError = error as? WorkflowError {
                    switch workflowError {
                    case .missingAPIKey:
                        // Avoid sheet+alert collisions: route to Settings without showing the error alert.
                        self.settingsViewModel.testStatusMessage = "No API key found. Add your OpenAI key or switch to Demo AI."
                        self.errorMessage = nil
                        self.showSettings = true
                        self.isRunning = false
                        return
                    default:
                        break
                    }
                }
                self.errorMessage = error.localizedDescription
            }
            self.isRunning = false
        }
    }

    func cancelRun() {
        runTask?.cancel()
        isRunning = false
    }

    // MARK: - Quick Actions

    func canUseQuickActions() -> Bool {
        if subscriptionManager.isPro { return true }
        resetQuickActionsIfNeeded()
        return defaults.integer(forKey: quickCountKey) < maxFreeQuickActions
    }

    func runQuickAction(_ action: QuickAction) {
        let input = workflow.inputText
        guard !input.trimmed.isEmpty else {
            errorMessage = "Paste or type some text first."
            return
        }
        guard input.count <= Self.maxInputCharacters else {
            errorMessage = "Input is too long (\(input.count) characters). Max is \(Self.maxInputCharacters)."
            return
        }
        guard canUseQuickActions() else {
            showPaywallFor("Free plan allows \(maxFreeQuickActions) quick actions/day. Upgrade to Pro for unlimited quick actions.")
            return
        }

        let blocks: [Block]
        switch action {
        case .fixGrammar:
            blocks = [Block(type: .ai, instruction: "Fix grammar and spelling. Keep the original meaning. Preserve the original language. Keep formatting (line breaks). Return only the corrected text.")]
        case .bulletPoints:
            blocks = [Block(type: .formatter, formatterOperation: .bulletPoints)]
        case .rewritePro:
            blocks = [Block(type: .ai, instruction: "Rewrite professionally as a short, clear message.")]
        case .summarize:
            blocks = [Block(type: .ai, instruction: "Summarize in 5 bullet points.")]
        case .translateFR:
            blocks = [Block(type: .ai, instruction: "Translate to French. Keep a professional tone.")]
        }

        // AI actions require a provider.
        if blocks.contains(where: { $0.type == .ai }),
           settingsViewModel.settings.aiMode == .openAI,
           settingsViewModel.apiKeyInput.trimmed.isEmpty {
            errorMessage = nil
            settingsViewModel.testStatusMessage = "No API key found. Add your OpenAI key or switch to Demo AI."
            showSettings = true
            return
        }

        recordQuickAction()

        AppLog.ui.info("UI(quickAction) action=\(action.title, privacy: .public) inputChars=\(input.count, privacy: .public)")

        errorMessage = nil
        isRunning = true
        currentStepIndex = 0
        outputText = ""
        outputTrace = []

        let settings = settingsViewModel.settings
        let workflowName = "\(workflow.name) · \(action.title)"

        runTask?.cancel()
        runTask = Task {
            do {
                let result = try await self.runner.runWithTrace(blocks: blocks, input: input, settings: settings) { step, total in
                    Task { @MainActor [weak self] in
                        self?.currentStepIndex = step
                    }
                }
                self.outputText = result.finalOutput
                self.outputTrace = result.steps
                self.historyStore.add(
                    workflowName: workflowName,
                    input: input,
                    output: result.finalOutput,
                    trace: result.steps,
                    isPro: self.subscriptionManager.isPro
                )
                self.showOutput = true
            } catch {
                AppLog.ui.error("UI(quickAction error) \(error.localizedDescription, privacy: .public)")
                if let workflowError = error as? WorkflowError {
                    switch workflowError {
                    case .missingAPIKey:
                        self.settingsViewModel.testStatusMessage = "No API key found. Add your OpenAI key or switch to Demo AI."
                        self.errorMessage = nil
                        self.showSettings = true
                        self.isRunning = false
                        return
                    default:
                        break
                    }
                }
                self.errorMessage = error.localizedDescription
            }
            self.isRunning = false
        }
    }

    private func resetQuickActionsIfNeeded() {
        guard let last = defaults.object(forKey: quickDateKey) as? Date else { return }
        if !Calendar.current.isDateInToday(last) {
            defaults.set(0, forKey: quickCountKey)
        }
    }

    private func recordQuickAction() {
        resetQuickActionsIfNeeded()
        let count = defaults.integer(forKey: quickCountKey) + 1
        defaults.set(count, forKey: quickCountKey)
        defaults.set(Date(), forKey: quickDateKey)
    }

    // MARK: - Paywall helper

    private func showPaywallFor(_ reason: String) {
        paywallReason = reason
        showPaywall = true
    }
}

@MainActor
final class TemplatesViewModel: ObservableObject {
    @Published private(set) var templatesByCategory: [TemplateCategory: [WorkflowTemplate]] = [:]
    
    init() {
        self.templatesByCategory = Dictionary(grouping: Self.sampleTemplates, by: { $0.category })
    }

    func isLocked(_ template: WorkflowTemplate, isPro: Bool) -> Bool {
        template.isProOnly && !isPro
    }

    // 3 free templates; rest pro.
    static let sampleTemplates: [WorkflowTemplate] = [
        // Email & Work (3 free)
        WorkflowTemplate(
            category: .emailAndWork,
            name: "Professional Reply",
            description: "Turn a rough reply into a clear, professional email.",
            blocks: [
                Block(type: .formatter, formatterOperation: .fixGrammar),
                Block(type: .ai, instruction: "Rewrite professionally as a concise email."),
                Block(type: .ai, instruction: "Add a subject line and a polite closing.")
            ],
            isProOnly: false
        ),
        WorkflowTemplate(
            category: .emailAndWork,
            name: "Polite Complaint",
            description: "Firm but polite message with clear request.",
            blocks: [
                Block(type: .formatter, formatterOperation: .fixGrammar),
                Block(type: .ai, instruction: "Rewrite as a polite complaint. Include the issue, impact, and a clear request for resolution."),
                Block(type: .ai, instruction: "Shorten to under 120 words.")
            ],
            isProOnly: false
        ),
        WorkflowTemplate(
            category: .emailAndWork,
            name: "Meeting Summary",
            description: "Generate summary + action items from notes.",
            blocks: [
                Block(type: .ai, instruction: "Summarize the meeting notes in 5 bullet points."),
                Block(type: .ai, instruction: "Extract action items with owners and deadlines if present."),
                Block(type: .formatter, formatterOperation: .bulletPoints)
            ],
            isProOnly: false
        ),

        // Study (Pro)
        WorkflowTemplate(
            category: .study,
            name: "Explain Simply",
            description: "Explain like I'm 12, with an example.",
            blocks: [
                Block(type: .ai, instruction: "Explain simply. Use a short analogy and one concrete example."),
                Block(type: .ai, instruction: "List 3 key takeaways.")
            ],
            isProOnly: true
        ),
        WorkflowTemplate(
            category: .study,
            name: "Key Points",
            description: "Extract the key points and definitions.",
            blocks: [
                Block(type: .ai, instruction: "Extract the key points and important definitions."),
                Block(type: .formatter, formatterOperation: .bulletPoints)
            ],
            isProOnly: true
        ),
        WorkflowTemplate(
            category: .study,
            name: "Flashcards (basic)",
            description: "Turn text into simple Q/A flashcards.",
            blocks: [
                Block(type: .ai, instruction: "Create 10 flashcards as Q: ... A: ..."),
                Block(type: .formatter, formatterOperation: .fixGrammar)
            ],
            isProOnly: true
        ),

        // Social (Pro)
        WorkflowTemplate(
            category: .social,
            name: "Tweet Thread",
            description: "Create a short Twitter/X thread.",
            blocks: [
                Block(type: .ai, instruction: "Create a 6-tweet thread. Hook first, then numbered tweets, then a closing."),
                Block(type: .formatter, formatterOperation: .fixGrammar)
            ],
            isProOnly: true
        ),
        WorkflowTemplate(
            category: .social,
            name: "LinkedIn Post",
            description: "Professional post with structure and CTA.",
            blocks: [
                Block(type: .ai, instruction: "Write a LinkedIn post with a strong hook, 3 sections, and a short CTA."),
                Block(type: .ai, instruction: "Shorten slightly and keep a professional tone.")
            ],
            isProOnly: true
        ),

        // Translation (Pro)
        WorkflowTemplate(
            category: .translation,
            name: "French Professional",
            description: "Translate to French with professional tone.",
            blocks: [
                Block(type: .ai, instruction: "Translate to French. Keep a professional tone."),
                Block(type: .formatter, formatterOperation: .fixGrammar)
            ],
            isProOnly: true
        ),
        WorkflowTemplate(
            category: .translation,
            name: "English Professional",
            description: "Translate to English with professional tone.",
            blocks: [
                Block(type: .ai, instruction: "Translate to English. Keep a professional tone."),
                Block(type: .formatter, formatterOperation: .fixGrammar)
            ],
            isProOnly: true
        ),

        // Extra Pro templates to reach 12+
        WorkflowTemplate(
            category: .emailAndWork,
            name: "Follow‑up Email",
            description: "A polite follow‑up with clear next step.",
            blocks: [
                Block(type: .formatter, formatterOperation: .fixGrammar),
                Block(type: .ai, instruction: "Rewrite as a polite follow-up email. Keep it short and actionable.")
            ],
            isProOnly: true
        ),
        WorkflowTemplate(
            category: .study,
            name: "Practice Questions",
            description: "Generate 8 practice questions from text.",
            blocks: [
                Block(type: .ai, instruction: "Create 8 practice questions and provide short answers."),
                Block(type: .formatter, formatterOperation: .fixGrammar)
            ],
            isProOnly: true
        )
    ]
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []

    private let historyStore: HistoryStore

    init(historyStore: HistoryStore = HistoryStore()) {
        self.historyStore = historyStore
        self.items = historyStore.items
    }

    func refresh() {
        items = historyStore.items
    }

    func delete(_ id: UUID) {
        historyStore.delete(id)
        refresh()
    }
}
