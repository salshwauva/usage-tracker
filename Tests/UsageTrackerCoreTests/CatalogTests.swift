import XCTest
@testable import UsageTrackerCore

final class CatalogTests: XCTestCase {
    func testMergeKeepsSavedReadingOnBuiltin() {
        var saved = Catalog.seededServices()
        guard let index = saved.firstIndex(where: { $0.id == "claude" }) else {
            return XCTFail("missing claude")
        }
        saved[index].meter = Meter(kind: .percent, used: 62, limit: 100, updatedAt: Date())
        saved[index].enabled = true

        let merged = Catalog.merge(saved: saved)
        let claude = merged.first { $0.id == "claude" }
        XCTAssertEqual(claude?.meter.used, 62)
        XCTAssertTrue(claude?.isBuiltIn == true)
    }

    func testMergeKeepsCustomService() {
        var saved = Catalog.seededServices()
        saved.append(Catalog.makeCustom(name: "Windsurf", vendor: "Codeium", bundleIDs: ["com.ex.windsurf"]))
        let merged = Catalog.merge(saved: saved)
        XCTAssertTrue(merged.contains { $0.displayName == "Windsurf" && !$0.isBuiltIn })
    }

    func testMergeAddsNewBuiltinEvenIfSaveIsOlder() {
        let oldSave = Catalog.seededServices().filter { $0.id != "deepseek" }
        XCTAssertFalse(oldSave.contains { $0.id == "deepseek" })
        let merged = Catalog.merge(saved: oldSave)
        XCTAssertTrue(merged.contains { $0.id == "deepseek" })
    }

    func testPopularFamiliesArePresent() {
        let ids = Set(Catalog.all.map(\.id))
        for id in ["claude", "chatgpt", "gemini", "grok", "cursor", "copilot"] {
            XCTAssertTrue(ids.contains(id), "missing \(id)")
        }
    }
}

final class StoreTests: XCTestCase {
    func testRoundTrip() throws {
        let defaults = UserDefaults(suiteName: "usagetracker.tests.\(UUID().uuidString)")!
        let store = PersistenceStore(defaults: defaults)
        var state = PersistedState.empty
        state.weeklyBudgetHours = 5
        state.entries = [TimeEntry(minutes: 45)]
        store.save(state)
        let loaded = store.load()
        XCTAssertEqual(loaded.weeklyBudgetHours, 5)
        XCTAssertEqual(loaded.entries.count, 1)
        XCTAssertEqual(loaded.entries[0].minutes, 45)
    }

    func testCorruptDataYieldsEmpty() {
        let defaults = UserDefaults(suiteName: "usagetracker.tests.\(UUID().uuidString)")!
        defaults.set(Data("not-json".utf8), forKey: "usagetracker.state.v1")
        let loaded = PersistenceStore(defaults: defaults).load()
        XCTAssertEqual(loaded.weeklyBudgetHours, 5)
        XCTAssertTrue(loaded.entries.isEmpty)
    }
}
