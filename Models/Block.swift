import Foundation

enum BlockType: String, Codable {
    case ai
    case formatter

    var displayName: String {
        switch self {
        case .ai:
            return "AI Step"
        case .formatter:
            return "Formatter"
        }
    }
}

struct Block: Identifiable, Codable, Equatable {
    let id: UUID
    var type: BlockType
    var instruction: String?
    var formatterOperation: FormatterOperation?

    init(id: UUID = UUID(), type: BlockType, instruction: String? = nil, formatterOperation: FormatterOperation? = nil) {
        self.id = id
        self.type = type
        self.instruction = instruction
        self.formatterOperation = formatterOperation
    }

    var displayDetail: String {
        switch type {
        case .ai:
            return instruction?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? instruction ?? ""
                : "Instruction required"
        case .formatter:
            return formatterOperation?.displayName ?? "Formatter"
        }
    }
}
