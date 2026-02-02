import Foundation

/// Local, free "demo AI" for testing app flows without OpenAI billing.
/// IMPORTANT: This is NOT real AI; outputs are heuristic and deterministic.
struct DemoAIClient {
    func runInstruction(input: String, instruction: String) async -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerInstr = instruction.lowercased()

        // Grammar-ish cleanup: reuse the formatter cleanup idea + add punctuation.
        if lowerInstr.contains("fix grammar") || lowerInstr.contains("grammar") || lowerInstr.contains("spelling") {
            return DemoTransforms.cleanSentence(trimmed)
        }

        if lowerInstr.contains("summarize") {
            return DemoTransforms.summarize(trimmed)
        }

        if lowerInstr.contains("bullet") {
            return DemoTransforms.bulletPoints(trimmed)
        }

        if lowerInstr.contains("translate") && (lowerInstr.contains("french") || lowerInstr.contains("fr")) {
            return DemoTransforms.fakeTranslateToFrench(trimmed)
        }

        if lowerInstr.contains("rewrite") || lowerInstr.contains("professional") || lowerInstr.contains("email") {
            return DemoTransforms.rewriteProfessional(trimmed)
        }

        // Fallback: echo with a tiny transformation so users see a change.
        return DemoTransforms.summarize(trimmed)
    }
}

enum DemoTransforms {
    static func cleanSentence(_ input: String) -> String {
        var s = input
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+([,\\.:;!\\?])", with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "([,\\.:;!\\?])(\\S)", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "\\b[iI]\\b", with: "I", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let firstLetterIndex = s.firstIndex(where: { $0.isLetter }) {
            let upper = String(s[firstLetterIndex]).uppercased()
            s.replaceSubrange(firstLetterIndex...firstLetterIndex, with: upper)
        }
        if let last = s.last, !".!?".contains(last), s.count > 0 {
            s += "."
        }
        return s
    }

    static func summarize(_ input: String) -> String {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "" }
        let parts = text
            .split(whereSeparator: { $0 == "." || $0 == "!" || $0 == "?" || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            return "Summary: \(parts.prefix(2).joined(separator: ". "))."
        }
        let words = text.split(whereSeparator: { $0 == " " || $0 == "\n" })
        return "Summary: " + words.prefix(24).joined(separator: " ") + (words.count > 24 ? "…" : "")
    }

    static func bulletPoints(_ input: String) -> String {
        let lines = input
            .split(whereSeparator: { $0 == "\n" || $0 == "." })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if lines.isEmpty { return "" }
        return lines.prefix(8).map { "• \($0)" }.joined(separator: "\n")
    }

    static func rewriteProfessional(_ input: String) -> String {
        let cleaned = cleanSentence(input).trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { return "" }
        return """
        Hi,

        \(cleaned)

        Thanks,
        """
    }

    static func fakeTranslateToFrench(_ input: String) -> String {
        if input.isEmpty { return "" }
        return "FR (demo): " + input
    }
}

