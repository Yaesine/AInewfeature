import Foundation

struct SettingsStore: Codable, Equatable {
    enum AIMode: String, Codable, CaseIterable {
        case openAI = "OpenAI"
        case demo = "Demo (no billing)"
    }

    var modelName: String
    var temperature: Double
    var apiKey: String?
    var aiMode: AIMode

    init(modelName: String = "gpt-4o-mini", temperature: Double = 0.4, apiKey: String? = nil, aiMode: AIMode = .openAI) {
        self.modelName = modelName
        self.temperature = temperature
        self.apiKey = apiKey
        self.aiMode = aiMode
    }

    // Backward-compatible decoding (older installs won’t have aiMode yet)
    enum CodingKeys: String, CodingKey {
        case modelName
        case temperature
        case apiKey
        case aiMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.modelName = (try? container.decode(String.self, forKey: .modelName)) ?? "gpt-4o-mini"
        self.temperature = (try? container.decode(Double.self, forKey: .temperature)) ?? 0.4
        self.apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey)
        self.aiMode = (try? container.decode(AIMode.self, forKey: .aiMode)) ?? .openAI
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modelName, forKey: .modelName)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(aiMode, forKey: .aiMode)
    }
}
