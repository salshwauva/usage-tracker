import Foundation

public struct WeekWindow: Equatable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    /// `firstWeekday` matches Calendar: 1 Sunday, 2 Monday.
    public static func containing(
        _ date: Date,
        calendar: Calendar = .current,
        firstWeekday: Int = 2
    ) -> WeekWindow {
        var cal = calendar
        cal.firstWeekday = firstWeekday
        let weekday = cal.component(.weekday, from: date)
        let daysFromStart = (weekday - firstWeekday + 7) % 7
        let startDay = cal.date(byAdding: .day, value: -daysFromStart, to: date) ?? date
        let start = cal.startOfDay(for: startDay)
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? start.addingTimeInterval(7 * 24 * 3600)
        return WeekWindow(start: start, end: end)
    }
}

public struct WeeklyBudget: Equatable {
    public var hoursLimit: Double
    public var hoursUsed: Double

    public init(hoursLimit: Double, hoursUsed: Double) {
        self.hoursLimit = hoursLimit
        self.hoursUsed = hoursUsed
    }

    public var hoursRemaining: Double { hoursLimit - hoursUsed }
    public var isOver: Bool { hoursUsed > hoursLimit && hoursLimit > 0 }
    public var fraction: Double {
        guard hoursLimit > 0 else { return 0 }
        return min(max(hoursUsed / hoursLimit, 0), 1)
    }

    /// One value per petal. Index 0 is the first hour.
    public func petalFills(petalCount: Int = 5) -> [Double] {
        guard petalCount > 0, hoursLimit > 0 else {
            return Array(repeating: 0, count: max(petalCount, 0))
        }
        let hoursPerPetal = hoursLimit / Double(petalCount)
        return (0..<petalCount).map { index in
            let start = Double(index) * hoursPerPetal
            return min(max((hoursUsed - start) / hoursPerPetal, 0), 1)
        }
    }
}

public enum WeeklyBudgetMath {
    public static func hoursUsed(
        entries: [TimeEntry],
        sessionStartedAt: Date?,
        sessionServiceID: String? = nil,
        now: Date,
        window: WeekWindow,
        serviceID: String? = nil
    ) -> Double {
        let logged = entries
            .filter { window.contains($0.startedAt) }
            .filter { serviceID == nil || $0.serviceID == serviceID }
            .reduce(0.0) { $0 + $1.hours }
        let liveApplies: Bool = {
            guard let sessionStartedAt, window.contains(sessionStartedAt) else { return false }
            if let serviceID { return sessionServiceID == serviceID }
            return true
        }()
        let live = liveApplies
            ? max(now.timeIntervalSince(sessionStartedAt ?? now) / 3600, 0)
            : 0
        return logged + live
    }
}
