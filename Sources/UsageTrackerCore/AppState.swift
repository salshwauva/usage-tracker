import Foundation
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published public private(set) var services: [Service]
    @Published public private(set) var entries: [TimeEntry]
    @Published public var weeklyBudgetHours: Double {
        didSet { persistThrottled(now: Date(), force: true) }
    }
    @Published public var firstWeekday: Int {
        didSet { persistThrottled(now: Date(), force: true) }
    }
    @Published public var idleSeconds: Double {
        didSet { persistThrottled(now: Date(), force: true) }
    }
    @Published public private(set) var sessionStartedAt: Date?
    @Published public private(set) var sessionServiceID: String?
    @Published public private(set) var isIdle: Bool = false
    @Published public private(set) var lastMatchedName: String?

    private var lastSampleAt: Date?
    private var lastPersistAt: Date = .distantPast

    private let store: PersistenceStore
    private let calendar: Calendar

    public init(
        store: PersistenceStore = .shared,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.calendar = calendar
        let loaded = store.load()
        self.services = loaded.services
        self.entries = loaded.entries
        self.weeklyBudgetHours = loaded.weeklyBudgetHours
        self.firstWeekday = loaded.firstWeekday
        self.idleSeconds = loaded.idleSeconds
        self.sessionStartedAt = loaded.sessionStartedAt
        self.sessionServiceID = loaded.sessionServiceID
        self.lastSampleAt = loaded.lastSampleAt
        recoverInterruptedSession()
    }

    public var enabledServices: [Service] {
        services.filter(\.enabled)
    }

    public var isWatching: Bool {
        sessionStartedAt != nil && !isIdle
    }

    public var watchingName: String? {
        guard isWatching, let id = sessionServiceID else { return lastMatchedName }
        return service(id: id)?.displayName
    }

    public func weekWindow(now: Date = Date()) -> WeekWindow {
        WeekWindow.containing(now, calendar: calendar, firstWeekday: firstWeekday)
    }

    public func budget(now: Date = Date()) -> WeeklyBudget {
        WeeklyBudget(
            hoursLimit: weeklyBudgetHours,
            hoursUsed: hoursUsed(now: now)
        )
    }

    public func hoursUsed(now: Date = Date(), serviceID: String? = nil) -> Double {
        let window = weekWindow(now: now)
        return WeeklyBudgetMath.hoursUsed(
            entries: entries,
            sessionStartedAt: sessionStartedAt,
            sessionServiceID: sessionServiceID,
            now: now,
            window: window,
            serviceID: serviceID
        )
    }

    public func entriesThisWeek(now: Date = Date()) -> [TimeEntry] {
        let window = weekWindow(now: now)
        return entries
            .filter { window.contains($0.startedAt) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    /// Called by ActivityMonitor. `ownBundle` means the menu bar popover is frontmost; keep counting the previous surface.
    public func ingest(sample: SurfaceSample?, idle: Bool, now: Date = Date(), ownBundle: Bool = false) {
        if ownBundle { return }

        if idle {
            if sessionStartedAt != nil {
                flushSession(at: lastSampleAt ?? now)
            }
            isIdle = true
            lastMatchedName = nil
            persistThrottled(now: now, force: true)
            return
        }

        isIdle = false
        let matchedID = sample.flatMap { ActivityRouter.match(sample: $0, services: services) }
        lastMatchedName = matchedID.flatMap { service(id: $0)?.displayName }

        if matchedID == sessionServiceID, sessionStartedAt != nil {
            lastSampleAt = now
            persistThrottled(now: now, force: false)
            return
        }

        flushSession(at: now)
        if let matchedID {
            sessionStartedAt = now
            sessionServiceID = matchedID
            lastSampleAt = now
        }
        persistThrottled(now: now, force: true)
    }

    public func flushForQuit(now: Date = Date()) {
        flushSession(at: now)
        persistThrottled(now: now, force: true)
    }

    public func recoverInterruptedSession() {
        guard let start = sessionStartedAt else { return }
        let end = lastSampleAt ?? start
        let minutes = end.timeIntervalSince(start) / 60
        sessionStartedAt = nil
        let serviceID = sessionServiceID
        sessionServiceID = nil
        lastSampleAt = nil
        if minutes >= 0.25 {
            entries.append(TimeEntry(startedAt: start, minutes: minutes, serviceID: serviceID))
        }
        persistThrottled(now: Date(), force: true)
    }

    public func removeEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        persistThrottled(now: Date(), force: true)
    }

    public func setEnabled(_ enabled: Bool, for id: String) {
        updateService(id) { $0.enabled = enabled }
    }

    public func updateModels(_ models: [String], for id: String) {
        updateService(id) { $0.models = models }
    }

    public func updateSources(bundleIDs: [String], urlHosts: [String], for id: String) {
        updateService(id) {
            $0.bundleIDs = bundleIDs
            $0.urlHosts = urlHosts
        }
    }

    public func rename(_ name: String, vendor: String, for id: String) {
        updateService(id) {
            $0.displayName = name
            $0.vendor = vendor
        }
    }

    public func addCustom(name: String, vendor: String, bundleIDs: [String], urlHosts: [String]) {
        services.append(Catalog.makeCustom(name: name, vendor: vendor, bundleIDs: bundleIDs, urlHosts: urlHosts))
        persistThrottled(now: Date(), force: true)
    }

    public func removeService(_ id: String) {
        guard let index = services.firstIndex(where: { $0.id == id }) else { return }
        guard !services[index].isBuiltIn else { return }
        services.remove(at: index)
        persistThrottled(now: Date(), force: true)
    }

    public func service(id: String) -> Service? {
        services.first { $0.id == id }
    }

    private func flushSession(at date: Date) {
        guard let start = sessionStartedAt else { return }
        let end = min(date, lastSampleAt ?? date)
        let minutes = end.timeIntervalSince(start) / 60
        let serviceID = sessionServiceID
        sessionStartedAt = nil
        sessionServiceID = nil
        lastSampleAt = nil
        if minutes >= 0.15 {
            entries.append(TimeEntry(startedAt: start, minutes: minutes, serviceID: serviceID))
        }
    }

    private func updateService(_ id: String, mutate: (inout Service) -> Void) {
        guard let index = services.firstIndex(where: { $0.id == id }) else { return }
        mutate(&services[index])
        persistThrottled(now: Date(), force: true)
    }

    private func persistThrottled(now: Date, force: Bool) {
        if !force, now.timeIntervalSince(lastPersistAt) < 15 { return }
        lastPersistAt = now
        store.save(
            PersistedState(
                schemaVersion: PersistedState.currentSchema,
                weeklyBudgetHours: weeklyBudgetHours,
                firstWeekday: firstWeekday,
                entries: entries,
                services: services,
                sessionStartedAt: sessionStartedAt,
                sessionServiceID: sessionServiceID,
                lastSampleAt: lastSampleAt,
                idleSeconds: idleSeconds
            )
        )
    }
}
