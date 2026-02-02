import Foundation

struct WorkflowHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let output: String

    init(id: UUID = UUID(), date: Date = Date(), output: String) {
        self.id = id
        self.date = date
        self.output = output
    }
}

struct Workflow: Codable, Equatable {
    var name: String
    var blocks: [Block]
    var inputText: String
    var history: [WorkflowHistoryItem]

    init(name: String = "My Workflow", blocks: [Block] = [], inputText: String = "", history: [WorkflowHistoryItem] = []) {
        self.name = name
        self.blocks = blocks
        self.inputText = inputText
        self.history = history
    }
}

// MARK: - Multi-workflow + Templates + History (P0)

struct StoredWorkflow: Identifiable, Codable, Equatable {
    let id: UUID
    var workflow: Workflow
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), workflow: Workflow, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.workflow = workflow
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case emailAndWork = "Email & Work"
    case study = "Study"
    case social = "Social"
    case translation = "Translation"

    var id: String { rawValue }
}

struct WorkflowTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    let category: TemplateCategory
    let name: String
    let description: String
    let blocks: [Block]
    let isProOnly: Bool

    init(
        id: UUID = UUID(),
        category: TemplateCategory,
        name: String,
        description: String,
        blocks: [Block],
        isProOnly: Bool
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.description = description
        self.blocks = blocks
        self.isProOnly = isProOnly
    }
}

struct WorkflowTraceStep: Identifiable, Codable, Equatable {
    let id: UUID
    let index: Int
    let title: String
    let output: String

    init(id: UUID = UUID(), index: Int, title: String, output: String) {
        self.id = id
        self.index = index
        self.title = title
        self.output = output
    }
}

struct WorkflowRunResult: Codable, Equatable {
    let finalOutput: String
    let steps: [WorkflowTraceStep]
}

struct HistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let workflowName: String
    let inputSnippet: String
    let output: String
    let trace: [WorkflowTraceStep]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        workflowName: String,
        inputSnippet: String,
        output: String,
        trace: [WorkflowTraceStep] = []
    ) {
        self.id = id
        self.date = date
        self.workflowName = workflowName
        self.inputSnippet = inputSnippet
        self.output = output
        self.trace = trace
    }
}
