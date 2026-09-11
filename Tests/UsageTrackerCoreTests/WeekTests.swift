import XCTest
@testable import UsageTrackerCore

final class WeekTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    func testMondayWeekContainsWednesday() {
        let wednesday = date(2026, 9, 9, 15, 0)
        let window = WeekWindow.containing(wednesday, calendar: calendar, firstWeekday: 2)
        XCTAssertEqual(calendar.component(.weekday, from: window.start), 2)
        XCTAssertTrue(window.contains(wednesday))
        XCTAssertTrue(window.contains(date(2026, 9, 7, 0, 0)))
        XCTAssertFalse(window.contains(date(2026, 9, 14, 0, 0)))
    }

    func testSundayWeekStart() {
        let wednesday = date(2026, 9, 9, 12, 0)
        let window = WeekWindow.containing(wednesday, calendar: calendar, firstWeekday: 1)
        XCTAssertEqual(calendar.component(.weekday, from: window.start), 1)
        XCTAssertTrue(window.contains(date(2026, 9, 6, 8, 0)))
    }

    func testPetalFillsSplitHoursEvenly() {
        let budget = WeeklyBudget(hoursLimit: 5, hoursUsed: 2.5)
        XCTAssertEqual(budget.petalFills(), [1, 1, 0.5, 0, 0])
        XCTAssertEqual(budget.hoursRemaining, 2.5)
        XCTAssertFalse(budget.isOver)
    }

    func testOverBudgetFillsAllPetals() {
        let budget = WeeklyBudget(hoursLimit: 5, hoursUsed: 6)
        XCTAssertEqual(budget.petalFills(), [1, 1, 1, 1, 1])
        XCTAssertTrue(budget.isOver)
    }

    func testCustomBudgetStillUsesFivePetals() {
        let budget = WeeklyBudget(hoursLimit: 10, hoursUsed: 3)
        let fills = budget.petalFills()
        XCTAssertEqual(fills.count, 5)
        XCTAssertEqual(fills[0], 1, accuracy: 0.001)
        XCTAssertEqual(fills[1], 0.5, accuracy: 0.001)
        XCTAssertEqual(fills[2], 0, accuracy: 0.001)
    }

    func testLiveSessionCountsTowardWeek() {
        let now = date(2026, 9, 9, 11, 30)
        let window = WeekWindow.containing(now, calendar: calendar, firstWeekday: 2)
        let hours = WeeklyBudgetMath.hoursUsed(
            entries: [TimeEntry(startedAt: date(2026, 9, 8, 12, 0), minutes: 30)],
            sessionStartedAt: date(2026, 9, 9, 10, 0),
            now: now,
            window: window
        )
        XCTAssertEqual(hours, 0.5 + 1.5, accuracy: 0.001)
    }

    func testEntryOutsideWindowIsIgnored() {
        let now = date(2026, 9, 9, 12, 0)
        let window = WeekWindow.containing(now, calendar: calendar, firstWeekday: 2)
        let hours = WeeklyBudgetMath.hoursUsed(
            entries: [TimeEntry(startedAt: date(2026, 9, 1, 12, 0), minutes: 120)],
            sessionStartedAt: nil,
            now: now,
            window: window
        )
        XCTAssertEqual(hours, 0)
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var components = DateComponents()
        components.year = y
        components.month = m
        components.day = d
        components.hour = h
        components.minute = min
        return calendar.date(from: components)!
    }
}
