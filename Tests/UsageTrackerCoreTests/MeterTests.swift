import XCTest
@testable import UsageTrackerCore

final class MeterTests: XCTestCase {
    func testPercentFractionClamps() {
        let meter = Meter(kind: .percent, used: 150, limit: 100, updatedAt: Date())
        XCTAssertEqual(meter.fraction, 1.0)
    }

    func testPercentDisplay() {
        let meter = Meter(kind: .percent, used: 40, limit: 100, updatedAt: Date())
        XCTAssertEqual(meter.displayValue, "40%")
        XCTAssertEqual(meter.fraction, 0.4)
    }

    func testCountWithoutLimitHasNoFraction() {
        let meter = Meter(kind: .count, used: 12, limit: nil, unitLabel: "requests", updatedAt: Date())
        XCTAssertNil(meter.fraction)
        XCTAssertEqual(meter.displayValue, "12 requests")
    }

    func testUnlimitedHasNoFraction() {
        let meter = Meter(kind: .unlimited, used: 0, limit: nil)
        XCTAssertNil(meter.fraction)
        XCTAssertEqual(meter.displayValue, "No cap")
        XCTAssertTrue(meter.hasReading)
    }

    func testBlankHasNoReading() {
        XCTAssertFalse(Meter.blank(kind: .percent).hasReading)
        XCTAssertFalse(Meter.blank(kind: .count).hasReading)
    }

    func testUnknownKindFallsBackToCount() {
        XCTAssertEqual(MeterKind.resolved("tokens-v3"), .count)
        XCTAssertEqual(ResetPeriod.resolved("fortnight"), .weekly)
    }

    func testDurationDisplay() {
        let meter = Meter(kind: .duration, used: 1.5, limit: 5, unitLabel: "h", updatedAt: Date())
        XCTAssertEqual(meter.displayValue, "1.5h / 5h")
        XCTAssertEqual(meter.fraction, 0.3)
    }
}

final class DurationFormatTests: XCTestCase {
    func testShortHours() {
        XCTAssertEqual(DurationFormat.shortHours(2), "2h")
        XCTAssertEqual(DurationFormat.shortHours(0.5), "30m")
        XCTAssertEqual(DurationFormat.remaining(-0.25), "+15m")
    }

    func testLongHours() {
        XCTAssertEqual(DurationFormat.longHours(2.5), "2h 30m")
        XCTAssertEqual(DurationFormat.longHours(0.25), "15m")
    }
}
