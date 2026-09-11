import Foundation

/// How a subscription currently reports usage.
///
/// Vendors change this. ChatGPT has been a message count, a GPT-4 cap, and a
/// percentage bar. Store the kind as a string so an unknown future kind still
/// decodes, then fall back to a generic used/limit editor.
public enum MeterKind: String, CaseIterable, Identifiable, Codable {
    case percent
    case count
    case duration
    case unlimited

    public var id: String { rawValue }

    public static func resolved(_ raw: String) -> MeterKind {
        MeterKind(rawValue: raw) ?? .count
    }

    public var editorCaption: String {
        switch self {
        case .percent: return "Share of the vendor usage bar (0-100)"
        case .count: return "Used / limit of whatever they currently count"
        case .duration: return "Hours used / hours in the plan"
        case .unlimited: return "No cap. Nothing to fill."
        }
    }
}

public enum ResetPeriod: String, CaseIterable, Identifiable, Codable {
    case weekly
    case monthly
    case rolling7
    case none

    public var id: String { rawValue }

    public static func resolved(_ raw: String) -> ResetPeriod {
        ResetPeriod(rawValue: raw) ?? .weekly
    }

    public var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .rolling7: return "Rolling 7 days"
        case .none: return "Does not reset"
        }
    }
}

/// One subscription reading. Independent of the weekly hour budget.
public struct Meter: Codable, Equatable {
    public var kindRaw: String
    public var used: Double
    public var limit: Double?
    public var unitLabel: String
    public var periodRaw: String
    public var updatedAt: Date?
    public var note: String

    public init(
        kind: MeterKind = .percent,
        used: Double = 0,
        limit: Double? = 100,
        unitLabel: String = "%",
        period: ResetPeriod = .weekly,
        updatedAt: Date? = nil,
        note: String = ""
    ) {
        self.kindRaw = kind.rawValue
        self.used = used
        self.limit = limit
        self.unitLabel = unitLabel
        self.periodRaw = period.rawValue
        self.updatedAt = updatedAt
        self.note = note
    }

    public var kind: MeterKind { MeterKind.resolved(kindRaw) }
    public var period: ResetPeriod { ResetPeriod.resolved(periodRaw) }

    public var hasReading: Bool {
        switch kind {
        case .unlimited: return true
        case .percent, .count, .duration: return updatedAt != nil
        }
    }

    /// 0...1 for a fill. Nil when there is no cap.
    public var fraction: Double? {
        switch kind {
        case .unlimited:
            return nil
        case .percent:
            let cap = limit ?? 100
            guard cap > 0 else { return nil }
            return min(max(used / cap, 0), 1)
        case .count, .duration:
            guard let limit, limit > 0 else { return nil }
            return min(max(used / limit, 0), 1)
        }
    }

    public var displayValue: String {
        switch kind {
        case .unlimited:
            return "No cap"
        case .percent:
            return "\(Self.trimmed(used))%"
        case .count:
            if let limit {
                return "\(Self.trimmed(used)) / \(Self.trimmed(limit)) \(unitLabel)".trimmingCharacters(in: .whitespaces)
            }
            return "\(Self.trimmed(used)) \(unitLabel)".trimmingCharacters(in: .whitespaces)
        case .duration:
            if let limit {
                return "\(DurationFormat.shortHours(used)) / \(DurationFormat.shortHours(limit))"
            }
            return DurationFormat.shortHours(used)
        }
    }

    public static func blank(kind: MeterKind) -> Meter {
        Meter(kind: kind, used: 0, limit: defaultLimit(for: kind), unitLabel: defaultUnit(for: kind), updatedAt: nil)
    }

    public static func defaultLimit(for kind: MeterKind) -> Double? {
        switch kind {
        case .percent: return 100
        case .count: return nil
        case .duration: return nil
        case .unlimited: return nil
        }
    }

    public static func defaultUnit(for kind: MeterKind) -> String {
        switch kind {
        case .percent: return "%"
        case .count: return "requests"
        case .duration: return "h"
        case .unlimited: return ""
        }
    }

    private static func trimmed(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value.rounded())) }
        return String(format: "%.1f", value)
    }
}

public struct Service: Identifiable, Equatable, Codable {
    public var id: String
    public var displayName: String
    public var vendor: String
    public var models: [String]
    public var enabled: Bool
    public var isBuiltIn: Bool
    public var meter: Meter
    public var bundleIDs: [String]
    public var urlHosts: [String]

    public init(
        id: String,
        displayName: String,
        vendor: String,
        models: [String],
        enabled: Bool,
        isBuiltIn: Bool,
        meter: Meter,
        bundleIDs: [String] = [],
        urlHosts: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.vendor = vendor
        self.models = models
        self.enabled = enabled
        self.isBuiltIn = isBuiltIn
        self.meter = meter
        self.bundleIDs = bundleIDs
        self.urlHosts = urlHosts
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        displayName = try c.decode(String.self, forKey: .displayName)
        vendor = try c.decodeIfPresent(String.self, forKey: .vendor) ?? ""
        models = try c.decodeIfPresent([String].self, forKey: .models) ?? []
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        isBuiltIn = try c.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
        meter = try c.decodeIfPresent(Meter.self, forKey: .meter) ?? Meter.blank(kind: .percent)
        bundleIDs = try c.decodeIfPresent([String].self, forKey: .bundleIDs) ?? []
        urlHosts = try c.decodeIfPresent([String].self, forKey: .urlHosts) ?? []
    }
}

public struct TimeEntry: Identifiable, Equatable, Codable {
    public var id: UUID
    public var startedAt: Date
    public var minutes: Double
    public var serviceID: String?
    public var isAdjustment: Bool

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        minutes: Double,
        serviceID: String? = nil,
        isAdjustment: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.minutes = minutes
        self.serviceID = serviceID
        self.isAdjustment = isAdjustment
    }

    public var hours: Double { minutes / 60 }
}

public struct PersistedState: Codable, Equatable {
    public var schemaVersion: Int
    public var weeklyBudgetHours: Double
    public var firstWeekday: Int
    public var entries: [TimeEntry]
    public var services: [Service]
    public var sessionStartedAt: Date?
    public var sessionServiceID: String?
    public var lastSampleAt: Date?
    public var idleSeconds: Double

    public static let currentSchema = 2

    public static var empty: PersistedState {
        PersistedState(
            schemaVersion: currentSchema,
            weeklyBudgetHours: 5,
            firstWeekday: 2,
            entries: [],
            services: Catalog.seededServices(),
            sessionStartedAt: nil,
            sessionServiceID: nil,
            lastSampleAt: nil,
            idleSeconds: 90
        )
    }

    public init(
        schemaVersion: Int,
        weeklyBudgetHours: Double,
        firstWeekday: Int,
        entries: [TimeEntry],
        services: [Service],
        sessionStartedAt: Date?,
        sessionServiceID: String?,
        lastSampleAt: Date?,
        idleSeconds: Double
    ) {
        self.schemaVersion = schemaVersion
        self.weeklyBudgetHours = weeklyBudgetHours
        self.firstWeekday = firstWeekday
        self.entries = entries
        self.services = services
        self.sessionStartedAt = sessionStartedAt
        self.sessionServiceID = sessionServiceID
        self.lastSampleAt = lastSampleAt
        self.idleSeconds = idleSeconds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? PersistedState.currentSchema
        weeklyBudgetHours = try c.decodeIfPresent(Double.self, forKey: .weeklyBudgetHours) ?? 5
        firstWeekday = try c.decodeIfPresent(Int.self, forKey: .firstWeekday) ?? 2
        entries = try c.decodeIfPresent([TimeEntry].self, forKey: .entries) ?? []
        services = try c.decodeIfPresent([Service].self, forKey: .services) ?? Catalog.seededServices()
        sessionStartedAt = try c.decodeIfPresent(Date.self, forKey: .sessionStartedAt)
        sessionServiceID = try c.decodeIfPresent(String.self, forKey: .sessionServiceID)
        lastSampleAt = try c.decodeIfPresent(Date.self, forKey: .lastSampleAt)
        idleSeconds = try c.decodeIfPresent(Double.self, forKey: .idleSeconds) ?? 90
    }
}

public enum DurationFormat {
    public static func shortHours(_ hours: Double) -> String {
        if abs(hours) >= 1 {
            let tenths = (hours * 10).rounded() / 10
            if tenths == tenths.rounded() {
                return "\(Int(tenths))h"
            }
            return String(format: "%.1fh", tenths)
        }
        let minutes = Int((hours * 60).rounded())
        return "\(minutes)m"
    }

    public static func remaining(_ hours: Double) -> String {
        if hours < 0 {
            return "+\(shortHours(-hours))"
        }
        return shortHours(hours)
    }

    public static func longHours(_ hours: Double) -> String {
        let sign = hours < 0 ? "-" : ""
        let absHours = abs(hours)
        let h = Int(absHours)
        let m = Int(((absHours - Double(h)) * 60).rounded())
        if h > 0 && m > 0 { return "\(sign)\(h)h \(m)m" }
        if h > 0 { return "\(sign)\(h)h" }
        return "\(sign)\(m)m"
    }
}
