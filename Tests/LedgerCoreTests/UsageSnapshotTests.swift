import XCTest
@testable import LedgerCore

final class UsageSnapshotTests: XCTestCase {
    func testFractionClampsAtOne() {
        let snapshot = UsageSnapshot(used: 150, limit: 100, unit: "USD", fetchedAt: Date(), source: .manual)
        XCTAssertEqual(snapshot.fraction, 1.0)
    }

    func testFractionNilWithoutLimit() {
        let snapshot = UsageSnapshot(used: 42, limit: nil, unit: "USD", fetchedAt: Date(), source: .manual)
        XCTAssertNil(snapshot.fraction)
    }
}
