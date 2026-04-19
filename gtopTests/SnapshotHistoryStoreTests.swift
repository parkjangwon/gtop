import XCTest
@testable import gtopCore

final class SnapshotHistoryStoreTests: XCTestCase {
    func testTrimsHistoryToMaximumSampleCount() {
        let store = SnapshotHistoryStore(limit: 3)

        (1...5).forEach {
            store.append(
                SystemSnapshot(
                    capturedAt: Date(timeIntervalSince1970: TimeInterval($0)),
                    cpu: CPUStatus(totalUsage: Double($0), userUsage: Double($0), systemUsage: 0),
                    memory: MemoryStatus(usedGB: 1, totalGB: 2, pressure: .normal, swapUsedGB: 0),
                    disk: DiskStatus(
                        usedGB: 0,
                        totalGB: 1,
                        readBytesPerSecond: 0,
                        writeBytesPerSecond: 0
                    ),
                    network: NetworkStatus(
                        downloadBytesPerSecond: Double($0),
                        uploadBytesPerSecond: Double($0),
                        isExpensive: false
                    ),
                    power: nil,
                    thermal: ThermalStatus(state: .nominal)
                )
            )
        }

        let history = store.history

        XCTAssertEqual(history.cpuUsage, [3, 4, 5])
        XCTAssertEqual(history.downloadBytesPerSecond, [3, 4, 5])
    }
}
