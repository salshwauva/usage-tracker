import Foundation

/// Reads month-to-date API spend from OpenAI's organization costs endpoint.
///
/// Requires an Admin API key (organization owner scope), not a project key. As with
/// Anthropic, there is no API-exposed spending "limit" — any hard cap set in the OpenAI
/// billing dashboard isn't readable via API, so `limit` is Sophia's own locally configured
/// budget. Endpoint shape is per OpenAI's usage & costs docs as of this writing
/// (`GET /v1/organization/costs`); verify against current docs if requests start failing.
public struct OpenAIUsageProvider: UsageProvider {
    public let service = ServiceID.openAIAPI
    private let budget: Double?

    public init(monthlyBudgetUSD: Double? = nil) {
        self.budget = monthlyBudgetUSD
    }

    public func fetchUsage(apiKey: String) async throws -> UsageSnapshot {
        guard !apiKey.isEmpty else { throw UsageProviderError.missingAPIKey }

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        var components = URLComponents(string: "https://api.openai.com/v1/organization/costs")!
        components.queryItems = [
            URLQueryItem(name: "start_time", value: String(Int(startOfMonth.timeIntervalSince1970))),
            URLQueryItem(name: "limit", value: "180"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await httpGetJSON(request)
        let report = try JSONDecoder().decode(CostsResponse.self, from: data)

        let totalUSD = report.data.reduce(0.0) { sum, bucket in
            sum + bucket.results.reduce(0.0) { $0 + $1.amount.value }
        }

        return UsageSnapshot(used: totalUSD, limit: budget, unit: "USD", fetchedAt: now, source: .api)
    }
}

private struct CostsResponse: Decodable {
    struct Bucket: Decodable {
        struct Result: Decodable {
            struct Amount: Decodable {
                let value: Double
                let currency: String?
            }
            let amount: Amount
        }
        let results: [Result]
    }
    let data: [Bucket]
}
