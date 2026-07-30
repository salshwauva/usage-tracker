import Foundation

/// Persists Sophia's own manual readings of consumer subscription usage caps
/// (Claude.ai Pro/Max, ChatGPT Plus, Grok/X Premium). None of these expose usage via a
/// public API — the number only exists in each service's own web UI — so Ledger tracks
/// whatever she last typed in, timestamped, rather than polling anything.
public final class ManualUsageStore {
    public static let shared = ManualUsageStore()

    private let defaults: UserDefaults
    private let keyPrefix = "ledger.manualUsage."

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func record(used: Double, limit: Double?, unit: String, for id: ServiceID) {
        let snapshot = UsageSnapshot(used: used, limit: limit, unit: unit, fetchedAt: Date(), source: .manual)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: keyPrefix + id.rawValue)
    }

    public func snapshot(for id: ServiceID) -> UsageSnapshot? {
        guard let data = defaults.data(forKey: keyPrefix + id.rawValue) else { return nil }
        return try? JSONDecoder().decode(UsageSnapshot.self, from: data)
    }

    public func clear(for id: ServiceID) {
        defaults.removeObject(forKey: keyPrefix + id.rawValue)
    }
}
