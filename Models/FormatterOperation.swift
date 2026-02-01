import Foundation

enum FormatterTone: String, Codable, CaseIterable {
    case casual
    case neutral
    case professional

    var displayName: String {
        switch self {
        case .casual:
            return "Casual"
        case .neutral:
            return "Neutral"
        case .professional:
            return "Professional"
        }
    }
}

enum FormatterOperation: Codable, Equatable, CaseIterable {
    case fixGrammar
    case shorten
    case expand
    case bulletPoints
    case tone(FormatterTone)

    enum CodingKeys: String, CodingKey {
        case kind
        case tone
    }

    enum Kind: String, Codable, CaseIterable {
        case fixGrammar
        case shorten
        case expand
        case bulletPoints
        case tone
    }

    static var allCases: [FormatterOperation] {
        [
            .fixGrammar,
            .shorten,
            .expand,
            .bulletPoints,
            .tone(.neutral)
        ]
    }

    var kind: Kind {
        switch self {
        case .fixGrammar:
            return .fixGrammar
        case .shorten:
            return .shorten
        case .expand:
            return .expand
        case .bulletPoints:
            return .bulletPoints
        case .tone:
            return .tone
        }
    }

    var displayName: String {
        switch self {
        case .fixGrammar:
            return "Fix grammar"
        case .shorten:
            return "Shorten"
        case .expand:
            return "Expand"
        case .bulletPoints:
            return "Bullet points"
        case .tone(let tone):
            return "Tone: \(tone.displayName)"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .fixGrammar:
            self = .fixGrammar
        case .shorten:
            self = .shorten
        case .expand:
            self = .expand
        case .bulletPoints:
            self = .bulletPoints
        case .tone:
            let tone = try container.decode(FormatterTone.self, forKey: .tone)
            self = .tone(tone)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        if case let .tone(tone) = self {
            try container.encode(tone, forKey: .tone)
        }
    }
}
