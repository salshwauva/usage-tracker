import Foundation

public struct SurfaceSample: Equatable {
    public var bundleID: String
    public var url: URL?

    public init(bundleID: String, url: URL? = nil) {
        self.bundleID = bundleID
        self.url = url
    }
}

/// Browsers need a tab URL. Desktop AI apps match on bundle id alone.
public enum BrowserIDs {
    public static let all: Set<String> = [
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.apple.Safari",
        "company.thebrowser.Browser",
        "company.thebrowser.dia",
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "org.mozilla.firefox",
        "ai.perplexity.comet",
        "com.kagi.orion",
        "app.zen-browser.zen",
    ]

    public static func isBrowser(_ bundleID: String) -> Bool {
        all.contains(bundleID)
    }
}

/// Maps a frontmost app (and optional tab URL) to a catalog service.
/// Add a bundle id or host on the service when a vendor ships a new app or domain.
public enum ActivityRouter {
    public static func match(sample: SurfaceSample, services: [Service]) -> String? {
        let enabled = services.filter(\.enabled)
        if let host = normalizedHost(sample.url) {
            if let id = enabled.first(where: { $0.urlHosts.contains { hostMatches(host, pattern: $0) } })?.id {
                return id
            }
        }
        return enabled.first(where: { $0.bundleIDs.contains(sample.bundleID) })?.id
    }

    public static func normalizedHost(_ url: URL?) -> String? {
        guard var host = url?.host?.lowercased(), !host.isEmpty else { return nil }
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        return host
    }

    public static func hostMatches(_ host: String, pattern: String) -> Bool {
        let needle = pattern.lowercased()
        if host == needle { return true }
        return host.hasSuffix("." + needle)
    }
}
