import XCTest
@testable import gtopCore

final class ProcessUsageRankerTests: XCTestCase {
    func testReturnsEntriesSortedByDescendingValueAndTrimsLimit() {
        let entries = [
            ProcessUsageEntry(
                pid: 1,
                name: "Alpha",
                primaryValueText: "1",
                secondaryValueText: "",
                sortValue: 1,
                section: .cpu
            ),
            ProcessUsageEntry(
                pid: 2,
                name: "Beta",
                primaryValueText: "5",
                secondaryValueText: "",
                sortValue: 5,
                section: .cpu
            ),
            ProcessUsageEntry(
                pid: 3,
                name: "Gamma",
                primaryValueText: "3",
                secondaryValueText: "",
                sortValue: 3,
                section: .cpu
            )
        ]

        let ranked = ProcessUsageRanker.topEntries(from: entries, limit: 2)

        XCTAssertEqual(ranked.map(\.name), ["Beta", "Gamma"])
    }
}
