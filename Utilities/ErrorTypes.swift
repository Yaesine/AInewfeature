import Foundation

enum WorkflowError: LocalizedError {
    case invalidURL
    case apiError(String)
    case emptyResponse
    case missingAPIKey
    case invalidBlock(String)
    case cancelled
    case keychainError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .apiError(let message):
            return "The API request failed. \(message)"
        case .emptyResponse:
            return "The AI response was empty."
        case .missingAPIKey:
            return "Please add your API key in Settings to run AI steps."
        case .invalidBlock(let message):
            return "This step is invalid: \(message)."
        case .cancelled:
            return "The workflow was cancelled."
        case .keychainError:
            return "Unable to access secure storage."
        }
    }
}
