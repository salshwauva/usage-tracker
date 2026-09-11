import Foundation

public struct PersistenceStore {
    public static let shared = PersistenceStore()

    private let defaults: UserDefaults
    private let key = "usagetracker.state.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> PersistedState {
        guard let data = defaults.data(forKey: key) else {
            return .empty
        }
        do {
            let decoded = try JSONDecoder().decode(PersistedState.self, from: data)
            var state = decoded
            state.schemaVersion = PersistedState.currentSchema
            state.services = Catalog.merge(saved: decoded.services)
            if state.weeklyBudgetHours <= 0 { state.weeklyBudgetHours = 5 }
            if state.firstWeekday < 1 || state.firstWeekday > 7 { state.firstWeekday = 2 }
            if state.idleSeconds < 15 { state.idleSeconds = 90 }
            return state
        } catch {
            return .empty
        }
    }

    public func save(_ state: PersistedState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}
