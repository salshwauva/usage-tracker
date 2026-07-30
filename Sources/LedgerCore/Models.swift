import Foundation

public enum ServiceID: String, CaseIterable, Codable, Identifiable {
    case anthropicAPI
    case openAIAPI
    case xaiAPI
    case claudeSubscription
    case chatGPTSubscription
    case grokSubscription

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .anthropicAPI: return "Anthropic API"
        case .openAIAPI: return "OpenAI API"
        case .xaiAPI: return "xAI API"
        case .claudeSubscription: return "Claude.ai"
        case .chatGPTSubscription: return "ChatGPT"
        case .grokSubscription: return "Grok"
        }
    }

    public var kind: ServiceKind {
        switch self {
        case .anthropicAPI, .openAIAPI, .xaiAPI: return .apiBilling
        case .claudeSubscription, .chatGPTSubscription, .grokSubscription: return .subscriptionCap
        }
    }
}

public enum ServiceKind {
    /// Backed by an official usage/cost API and an API key.
    case apiBilling
    /// Consumer subscription usage cap (e.g. Pro plan message limits). No public API exists for
    /// any of these as of this writing, so values come from Sophia's own manual entry.
    case subscriptionCap
}

public struct UsageSnapshot: Codable, Equatable {
    public var used: Double
    public var limit: Double?
    public var unit: String
    public var fetchedAt: Date
    public var source: Source

    public enum Source: String, Codable {
        case api
        case manual
    }

    public init(used: Double, limit: Double?, unit: String, fetchedAt: Date, source: Source) {
        self.used = used
        self.limit = limit
        self.unit = unit
        self.fetchedAt = fetchedAt
        self.source = source
    }

    public var fraction: Double? {
        guard let limit, limit > 0 else { return nil }
        return min(used / limit, 1.0)
    }
}

public struct ServiceStatus: Identifiable {
    public var id: ServiceID { service }
    public let service: ServiceID
    public var snapshot: UsageSnapshot?
    public var error: String?
    public var isConfigured: Bool

    public init(service: ServiceID, snapshot: UsageSnapshot? = nil, error: String? = nil, isConfigured: Bool) {
        self.service = service
        self.snapshot = snapshot
        self.error = error
        self.isConfigured = isConfigured
    }
}
