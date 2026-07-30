import Foundation

public enum UsageProviderError: Error, LocalizedError {
    case missingAPIKey
    case unexpectedResponse(String)
    case httpError(Int, String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key set"
        case .unexpectedResponse(let detail):
            return "Unexpected response: \(detail)"
        case .httpError(let code, let detail):
            return "HTTP \(code): \(detail)"
        }
    }
}

public protocol UsageProvider {
    var service: ServiceID { get }
    func fetchUsage(apiKey: String) async throws -> UsageSnapshot
}

func httpGetJSON(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
        throw UsageProviderError.unexpectedResponse("no HTTP response")
    }
    guard (200...299).contains(http.statusCode) else {
        let body = String(data: data, encoding: .utf8) ?? ""
        throw UsageProviderError.httpError(http.statusCode, body)
    }
    return (data, http)
}
