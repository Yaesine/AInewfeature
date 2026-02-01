import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: SettingsStore
    @Published var apiKeyInput: String
    @Published var testStatusMessage: String?
    @Published var isTestingKey = false

    private let persistence: PersistenceService
    private let keychain: KeychainHelper
    private let openAIClient: OpenAIClient
    private let keychainService = "stepflow.ai"
    private let keychainAccount = "openai-key"

    init(persistence: PersistenceService, keychain: KeychainHelper = .shared, openAIClient: OpenAIClient = OpenAIClient()) {
        self.persistence = persistence
        self.keychain = keychain
        self.openAIClient = openAIClient
        let storedSettings = persistence.loadSettings()
        self.settings = storedSettings
        self.apiKeyInput = (try? keychain.read(service: keychainService, account: keychainAccount)) ?? ""
        self.settings.apiKey = apiKeyInput
    }

    func saveSettings() {
        settings.apiKey = apiKeyInput.trimmed
        persistence.saveSettings(settings)
        do {
            if settings.apiKey?.isEmpty == true {
                try keychain.delete(service: keychainService, account: keychainAccount)
            } else if let apiKey = settings.apiKey {
                try keychain.save(apiKey, service: keychainService, account: keychainAccount)
            }
        } catch {
            testStatusMessage = WorkflowError.keychainError.localizedDescription
        }
    }

    func testAPIKey() async {
        isTestingKey = true
        testStatusMessage = nil
        defer { isTestingKey = false }
        let trimmedKey = apiKeyInput.trimmed
        guard !trimmedKey.isEmpty else {
            testStatusMessage = "Enter an API key first."
            return
        }
        do {
            let result = try await openAIClient.runInstruction(
                input: "Ping",
                instruction: "Reply with the word OK.",
                model: settings.modelName,
                apiKey: trimmedKey,
                temperature: 0
            )
            testStatusMessage = result.lowercased().contains("ok") ? "Key is valid." : "Received a response."
        } catch {
            testStatusMessage = error.localizedDescription
        }
    }
}
