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
