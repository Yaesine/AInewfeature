import Foundation

struct WorkflowRunner {
    let openAIClient: OpenAIClient

    func run(blocks: [Block], input: String, settings: SettingsStore, progress: @escaping (Int, Int) -> Void) async throws -> String {
        var currentText = input
        for (index, block) in blocks.enumerated() {
            if Task.isCancelled {
                throw WorkflowError.cancelled
            }
            progress(index + 1, blocks.count)
            switch block.type {
            case .ai:
                guard let instruction = block.instruction, !instruction.isEmpty else {
                    throw WorkflowError.invalidBlock("Missing instruction")
                }
                guard let apiKey = settings.apiKey, !apiKey.isEmpty else {
                    throw WorkflowError.missingAPIKey
                }
                currentText = try await openAIClient.runInstruction(
                    input: currentText,
                    instruction: instruction,
                    model: settings.modelName,
                    apiKey: apiKey,
                    temperature: settings.temperature
                )
            case .formatter:
                guard let operation = block.formatterOperation else {
                    throw WorkflowError.invalidBlock("Missing formatter operation")
                }
                currentText = applyFormatter(operation: operation, to: currentText)
            }
        }
        return currentText
    }

    private func applyFormatter(operation: FormatterOperation, to text: String) -> String {
        switch operation {
        case .fixGrammar:
            return text
                .replacingOccurrences(of: "  ", with: " ")
                .replacingOccurrences(of: " ,", with: ",")
                .replacingOccurrences(of: " .", with: ".")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        case .shorten:
            let sentences = text.split(separator: ".")
            return sentences.prefix(2).joined(separator: ". ").trimmingCharacters(in: .whitespacesAndNewlines)
        case .expand:
            return text + "\n\nAdditional details can be added here to expand on the main idea."
        case .bulletPoints:
            let lines = text
                .split(whereSeparator: { $0 == "\n" || $0 == "." })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return lines.map { "• \($0)" }.joined(separator: "\n")
        case .tone(let tone):
            return applyTone(tone, to: text)
        }
    }

    private func applyTone(_ tone: FormatterTone, to text: String) -> String {
        switch tone {
        case .casual:
            return text.replacingOccurrences(of: "do not", with: "don't")
        case .neutral:
            return text
        case .professional:
            return "\(text)\n\nPlease let me know if you need any additional details."
        }
    }
}
