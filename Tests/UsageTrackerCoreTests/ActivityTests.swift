import XCTest
@testable import UsageTrackerCore

final class ActivityTests: XCTestCase {
    private var services: [Service] { Catalog.seededServices() }

    func testCursorBundleMatchesCursor() {
        let sample = SurfaceSample(bundleID: "com.todesktop.230313mzl4w4u92")
        XCTAssertEqual(ActivityRouter.match(sample: sample, services: services), "cursor")
    }

    func testClaudeDesktopMatchesClaude() {
        let sample = SurfaceSample(bundleID: "com.anthropic.claudefordesktop")
        XCTAssertEqual(ActivityRouter.match(sample: sample, services: services), "claude")
    }

    func testChromeClaudeHostMatchesClaude() {
        let sample = SurfaceSample(
            bundleID: "com.google.Chrome",
            url: URL(string: "https://claude.ai/chat/abc")
        )
        XCTAssertEqual(ActivityRouter.match(sample: sample, services: services), "claude")
    }

    func testChromeUnrelatedHostDoesNotCount() {
        let sample = SurfaceSample(
            bundleID: "com.google.Chrome",
            url: URL(string: "https://news.ycombinator.com")
        )
        XCTAssertNil(ActivityRouter.match(sample: sample, services: services))
    }

    func testHostMatchAllowsSubdomain() {
        let sample = SurfaceSample(
            bundleID: "com.apple.Safari",
            url: URL(string: "https://www.chatgpt.com/")
        )
        XCTAssertEqual(ActivityRouter.match(sample: sample, services: services), "chatgpt")
    }

    func testDisabledServiceIsIgnored() {
        var list = services
        if let i = list.firstIndex(where: { $0.id == "cursor" }) {
            list[i].enabled = false
        }
        let sample = SurfaceSample(bundleID: "com.todesktop.230313mzl4w4u92")
        XCTAssertNil(ActivityRouter.match(sample: sample, services: list))
    }

    func testPerServiceHoursExcludeOtherApps() {
        let now = Date()
        let window = WeekWindow.containing(now, firstWeekday: 2)
        let entries = [
            TimeEntry(startedAt: now, minutes: 30, serviceID: "claude"),
            TimeEntry(startedAt: now, minutes: 90, serviceID: "cursor"),
        ]
        let claude = WeeklyBudgetMath.hoursUsed(
            entries: entries,
            sessionStartedAt: nil,
            now: now,
            window: window,
            serviceID: "claude"
        )
        let all = WeeklyBudgetMath.hoursUsed(
            entries: entries,
            sessionStartedAt: nil,
            now: now,
            window: window
        )
        XCTAssertEqual(claude, 0.5, accuracy: 0.001)
        XCTAssertEqual(all, 2.0, accuracy: 0.001)
    }

    func testLiveSessionCountsOnlyForThatService() {
        let start = Date()
        let now = start.addingTimeInterval(1800)
        let window = WeekWindow.containing(now, firstWeekday: 2)
        let claude = WeeklyBudgetMath.hoursUsed(
            entries: [],
            sessionStartedAt: start,
            sessionServiceID: "claude",
            now: now,
            window: window,
            serviceID: "claude"
        )
        let cursor = WeeklyBudgetMath.hoursUsed(
            entries: [],
            sessionStartedAt: start,
            sessionServiceID: "claude",
            now: now,
            window: window,
            serviceID: "cursor"
        )
        XCTAssertEqual(claude, 0.5, accuracy: 0.001)
        XCTAssertEqual(cursor, 0, accuracy: 0.001)
    }
}
