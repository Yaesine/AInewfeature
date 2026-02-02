import Foundation

struct WorkflowRunner {
    let openAIClient: OpenAIClient
    let demoAIClient = DemoAIClient()

    func run(blocks: [Block], input: String, settings: SettingsStore, progress: @escaping (Int, Int) -> Void) async throws -> String {
        AppLog.workflow.info("Run(start) blocks=\(blocks.count, privacy: .public) inputChars=\(input.count, privacy: .public)")
        var currentText = input
        for (index, block) in blocks.enumerated() {
            if Task.isCancelled {
                AppLog.workflow.info("Run(cancelled) at step=\(index + 1, privacy: .public)")
                throw WorkflowError.cancelled
            }
            progress(index + 1, blocks.count)
            switch block.type {
            case .ai:
                guard let instruction = block.instruction, !instruction.isEmpty else {
                    AppLog.workflow.error("Run(error) missing instruction at step=\(index + 1, privacy: .public)")
                    throw WorkflowError.invalidBlock("Missing instruction")
                }
                AppLog.workflow.info("Run(step) \(index + 1, privacy: .public)/\(blocks.count, privacy: .public) AI instructionLen=\(instruction.count, privacy: .public)")
                if settings.aiMode == .demo {
                    currentText = await demoAIClient.runInstruction(input: currentText, instruction: instruction)
                } else {
                    guard let apiKey = settings.apiKey, !apiKey.isEmpty else {
                        AppLog.workflow.error("Run(error) missing API key at step=\(index + 1, privacy: .public)")
                        throw WorkflowError.missingAPIKey
                    }
                    currentText = try await openAIClient.runInstruction(
                        input: currentText,
                        instruction: instruction,
                        model: settings.modelName,
                        apiKey: apiKey,
                        temperature: settings.temperature
                    )
                }
            case .formatter:
                guard let operation = block.formatterOperation else {
                    AppLog.workflow.error("Run(error) missing formatter operation at step=\(index + 1, privacy: .public)")
                    throw WorkflowError.invalidBlock("Missing formatter operation")
                }
                if operation.kind == .fixGrammar {
                    AppLog.workflow.info("Run(step) \(index + 1, privacy: .public)/\(blocks.count, privacy: .public) FixGrammar(AI)")
                    if settings.aiMode == .demo {
                        currentText = await demoAIClient.runInstruction(
                            input: currentText,
                            instruction: "Fix grammar and spelling."
                        )
                    } else {
                        guard let apiKey = settings.apiKey, !apiKey.trimmed.isEmpty else {
                            AppLog.workflow.error("Run(error) missing API key for Fix grammar (AI) at step=\(index + 1, privacy: .public)")
                            throw WorkflowError.missingAPIKey
                        }
                        currentText = try await openAIClient.runInstruction(
                            input: currentText,
                            instruction: "Fix grammar and spelling. Keep the original meaning. Preserve the original language. Keep formatting (line breaks). Return only the corrected text.",
                            model: settings.modelName,
                            apiKey: apiKey,
                            temperature: min(settings.temperature, 0.3)
                        )
                    }
                } else {
                    AppLog.workflow.info("Run(step) \(index + 1, privacy: .public)/\(blocks.count, privacy: .public) Formatter op=\(operation.displayName, privacy: .public)")
                    currentText = applyFormatter(operation: operation, to: currentText)
                }
            }
        }
        AppLog.workflow.info("Run(done) outputChars=\(currentText.count, privacy: .public)")
        return currentText
    }

    func runWithTrace(
        blocks: [Block],
        input: String,
        settings: SettingsStore,
        progress: @escaping (Int, Int) -> Void
    ) async throws -> WorkflowRunResult {
        AppLog.workflow.info("RunWithTrace(start) blocks=\(blocks.count, privacy: .public) inputChars=\(input.count, privacy: .public)")
        var currentText = input
        var steps: [WorkflowTraceStep] = []

        for (index, block) in blocks.enumerated() {
            if Task.isCancelled {
                AppLog.workflow.info("RunWithTrace(cancelled) at step=\(index + 1, privacy: .public)")
                throw WorkflowError.cancelled
            }
            progress(index + 1, blocks.count)

            switch block.type {
            case .ai:
                guard let instruction = block.instruction, !instruction.isEmpty else {
                    AppLog.workflow.error("RunWithTrace(error) missing instruction at step=\(index + 1, privacy: .public)")
                    throw WorkflowError.invalidBlock("Missing instruction")
                }
                AppLog.workflow.info("RunWithTrace(step) \(index + 1, privacy: .public)/\(blocks.count, privacy: .public) AI instructionLen=\(instruction.count, privacy: .public)")
                if settings.aiMode == .demo {
                    currentText = await demoAIClient.runInstruction(input: currentText, instruction: instruction)
                    steps.append(WorkflowTraceStep(index: index + 1, title: "Demo AI: \(instruction)", output: currentText))
                } else {
                    guard let apiKey = settings.apiKey, !apiKey.isEmpty else {
                        AppLog.workflow.error("RunWithTrace(error) missing API key at step=\(index + 1, privacy: .public)")
                        throw WorkflowError.missingAPIKey
                    }
                    currentText = try await openAIClient.runInstruction(
                        input: currentText,
                        instruction: instruction,
                        model: settings.modelName,
                        apiKey: apiKey,
                        temperature: settings.temperature
                    )
                    steps.append(WorkflowTraceStep(index: index + 1, title: "AI: \(instruction)", output: currentText))
                }
            case .formatter:
                guard let operation = block.formatterOperation else {
                    AppLog.workflow.error("RunWithTrace(error) missing formatter operation at step=\(index + 1, privacy: .public)")
                    throw WorkflowError.invalidBlock("Missing formatter operation")
                }
                if operation.kind == .fixGrammar {
                    AppLog.workflow.info("RunWithTrace(step) \(index + 1, privacy: .public)/\(blocks.count, privacy: .public) FixGrammar(AI)")
                    if settings.aiMode == .demo {
                        currentText = await demoAIClient.runInstruction(
                            input: currentText,
                            instruction: "Fix grammar and spelling."
                        )
                        steps.append(WorkflowTraceStep(index: index + 1, title: "Fix grammar (Demo AI)", output: currentText))
                    } else {
                        guard let apiKey = settings.apiKey, !apiKey.trimmed.isEmpty else {
                            AppLog.workflow.error("RunWithTrace(error) missing API key for Fix grammar (AI) at step=\(index + 1, privacy: .public)")
                            throw WorkflowError.missingAPIKey
                        }
                        currentText = try await openAIClient.runInstruction(
                            input: currentText,
                            instruction: "Fix grammar and spelling. Keep the original meaning. Preserve the original language. Keep formatting (line breaks). Return only the corrected text.",
                            model: settings.modelName,
                            apiKey: apiKey,
                            temperature: min(settings.temperature, 0.3)
                        )
                        steps.append(WorkflowTraceStep(index: index + 1, title: "Fix grammar (AI)", output: currentText))
                    }
                } else {
                    AppLog.workflow.info("RunWithTrace(step) \(index + 1, privacy: .public)/\(blocks.count, privacy: .public) Formatter op=\(operation.displayName, privacy: .public)")
                    currentText = applyFormatter(operation: operation, to: currentText)
                    steps.append(WorkflowTraceStep(index: index + 1, title: "Formatter: \(operation.displayName)", output: currentText))
                }
            }
        }

        AppLog.workflow.info("RunWithTrace(done) outputChars=\(currentText.count, privacy: .public) stepsSaved=\(steps.count, privacy: .public)")
        return WorkflowRunResult(finalOutput: currentText, steps: steps)
    }

    private func applyFormatter(operation: FormatterOperation, to text: String) -> String {
        let beforeLen = text.count
        let beforePreview = String(text.prefix(120)).replacingOccurrences(of: "\n", with: "\\n")
        switch operation {
        case .fixGrammar:
            var result = text

            // NOTE:
            // This is a deterministic, offline "cleanup" (not a full grammar engine).
            // For true grammar correction / rewriting, use an AI step.

            // Normalize tabs
            result = result.replacingOccurrences(of: "\t", with: " ")

            // Per-line cleanup to preserve newlines/paragraphs.
            let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
            var cleanedLines: [String] = []
            cleanedLines.reserveCapacity(lines.count)

            for rawLine in lines {
                var line = String(rawLine)

                // Collapse whitespace runs to single spaces (within the line).
                line = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

                // Remove spaces before punctuation: "hello !" -> "hello!"
                line = line.replacingOccurrences(of: "\\s+([,\\.:;!\\?])", with: "$1", options: .regularExpression)

                // Ensure a space after punctuation when missing: "Hi,John" -> "Hi, John"
                line = line.replacingOccurrences(of: "([,\\.:;!\\?])(\\S)", with: "$1 $2", options: .regularExpression)

                // Replace standalone i/I with I (won't touch iPhone etc.)
                line = line.replacingOccurrences(of: "\\b[iI]\\b", with: "I", options: .regularExpression)

                // Common greeting comma: "Hey John" -> "Hey, John"
                let lower = line.lowercased()
                if lower.hasPrefix("hey ") { line = "Hey," + line.dropFirst(3) }
                if lower.hasPrefix("hi ") { line = "Hi," + line.dropFirst(2) }
                if lower.hasPrefix("hello ") { line = "Hello," + line.dropFirst(5) }

                // Trim line edges
                line = line.trimmingCharacters(in: .whitespaces)

                cleanedLines.append(line)
            }

            result = cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

            // If it's a single-line sentence without terminal punctuation, add a period.
            if !result.contains("\n"),
               let last = result.last,
               !".!?".contains(last),
               result.split(whereSeparator: { $0 == " " }).count >= 3 {
                result += "."
            }

            // Capitalize first letter (simple heuristic)
            if let firstLetterIndex = result.firstIndex(where: { $0.isLetter }) {
                let upper = String(result[firstLetterIndex]).uppercased()
                result.replaceSubrange(firstLetterIndex...firstLetterIndex, with: upper)
            }

            let changed = (result != text)
            let afterPreview = String(result.prefix(120)).replacingOccurrences(of: "\n", with: "\\n")
            AppLog.formatter.info("Formatter(\(operation.displayName, privacy: .public)) changed=\(changed, privacy: .public) beforeChars=\(beforeLen, privacy: .public) afterChars=\(result.count, privacy: .public)")
            DebugPrint.line("Formatter[\(operation.displayName)] changed=\(changed) BEFORE='\(beforePreview)' AFTER='\(afterPreview)'")
            return result
        case .shorten:
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Prefer sentence-based shortening if we see obvious sentence delimiters.
            let parts = trimmed
                .split(whereSeparator: { $0 == "." || $0 == "!" || $0 == "?" || $0 == "\n" })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let result: String
            if parts.count >= 2 {
                result = parts.prefix(2).joined(separator: ". ") + "."
            } else {
                // Fallback: word-based truncation
                let words = trimmed.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
                let maxWords = 28
                if words.count > maxWords {
                    result = words.prefix(maxWords).joined(separator: " ") + "…"
                } else {
                    result = trimmed
                }
            }
            let changed = (result != text)
            let afterPreview = String(result.prefix(120)).replacingOccurrences(of: "\n", with: "\\n")
            AppLog.formatter.info("Formatter(\(operation.displayName, privacy: .public)) changed=\(changed, privacy: .public) beforeChars=\(beforeLen, privacy: .public) afterChars=\(result.count, privacy: .public)")
            DebugPrint.line("Formatter[\(operation.displayName)] changed=\(changed) BEFORE='\(beforePreview)' AFTER='\(afterPreview)'")
            return result
        case .expand:
            let result = text + "\n\nAdditional details can be added here to expand on the main idea."
            AppLog.formatter.info("Formatter(\(operation.displayName, privacy: .public)) changed=true beforeChars=\(beforeLen, privacy: .public) afterChars=\(result.count, privacy: .public)")
            return result
        case .bulletPoints:
            let lines = text
                .split(whereSeparator: { $0 == "\n" || $0 == "." })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let result = lines.map { "• \($0)" }.joined(separator: "\n")
            AppLog.formatter.info("Formatter(\(operation.displayName, privacy: .public)) changed=\((result != text), privacy: .public) beforeChars=\(beforeLen, privacy: .public) afterChars=\(result.count, privacy: .public) bullets=\(lines.count, privacy: .public)")
            return result
        case .tone(let tone):
            let result = applyTone(tone, to: text)
            AppLog.formatter.info("Formatter(\(operation.displayName, privacy: .public)) changed=\((result != text), privacy: .public) beforeChars=\(beforeLen, privacy: .public) afterChars=\(result.count, privacy: .public)")
            return result
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
