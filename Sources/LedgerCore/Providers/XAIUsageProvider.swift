import Foundation

/// Reads xAI API key/team info as a stand-in for usage.
///
/// Unlike Anthropic and OpenAI, xAI does not publish a documented usage-report or
/// cost-report endpoint as of this writing. This provider calls the key-info endpoint
/// (`GET /v1/api-key`), which confirms the key is live and returns team/account metadata,
/// but does not return spend. `used` is left at 0 with an error surfaced until xAI ships
/// (or documents) a real usage endpoint — check https://docs.x.ai before relying on this.
public struct XAIUsageProvider: UsageProvider {
    public let service = ServiceID.xaiAPI

    public init() {}

    public func fetchUsage(apiKey: String) async throws -> UsageSnapshot {
        guard !apiKey.isEmpty else { throw UsageProviderError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://api.x.ai/v1/api-key")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        _ = try await httpGetJSON(request)

        throw UsageProviderError.unexpectedResponse(
            "xAI key is valid, but xAI has no documented usage/cost endpoint yet — nothing to report"
        )
    }
}
