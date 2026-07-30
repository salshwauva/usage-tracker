import Foundation

/// Reads month-to-date API spend from Anthropic's Admin API cost report.
///
/// Requires an Admin API key (`sk-ant-admin...`), not a regular API key — cost/usage
/// reporting is org-admin scoped. There is no API-exposed spending "limit"; any spending
/// cap Sophia has configured in the Anthropic Console is not readable via API, so `limit`
/// here is whatever budget she sets locally in Ledger's settings, not a value from Anthropic.
///
/// Endpoint shape is per Anthropic's Admin API usage & cost docs as of this writing
/// (`GET /v1/organizations/cost_report`). Anthropic can revise this API; verify against
/// current docs if requests start failing.
public struct AnthropicUsageProvider: UsageProvider {
    public let service = ServiceID.anthropicAPI
    private let budget: Double?

    public init(monthlyBudgetUSD: Double? = nil) {
        self.budget = monthlyBudgetUSD
    }

    public func fetchUsage(apiKey: String) async throws -> UsageSnapshot {
        guard !apiKey.isEmpty else { throw UsageProviderError.missingAPIKey }

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        var components = URLComponents(string: "https://api.anthropic.com/v1/organizations/cost_report")!
        components.queryItems = [
            URLQueryItem(name: "starting_at", value: isoFormatter.string(from: startOfMonth)),
            URLQueryItem(name: "ending_at", value: isoFormatter.string(from: now)),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let (data, _) = try await httpGetJSON(request)
        let report = try JSONDecoder().decode(CostReportResponse.self, from: data)

        let totalUSD = report.data.reduce(0.0) { sum, bucket in
            sum + bucket.results.reduce(0.0) { $0 + (Double($1.amount) ?? 0) }
        }

        return UsageSnapshot(used: totalUSD, limit: budget, unit: "USD", fetchedAt: now, source: .api)
    }
}

private let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

private struct CostReportResponse: Decodable {
    struct Bucket: Decodable {
        struct Result: Decodable {
            let amount: String
            let currency: String?
        }
        let results: [Result]
    }
    let data: [Bucket]
}
