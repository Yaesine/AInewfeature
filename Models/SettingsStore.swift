import Foundation

struct SettingsStore: Codable, Equatable {
    var modelName: String
    var temperature: Double
    var apiKey: String?

    init(modelName: String = "gpt-4o-mini", temperature: Double = 0.4, apiKey: String? = nil) {
        self.modelName = modelName
        self.temperature = temperature
        self.apiKey = apiKey
    }
}
