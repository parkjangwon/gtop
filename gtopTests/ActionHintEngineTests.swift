import XCTest
@testable import gtopCore

final class ActionHintEngineTests: XCTestCase {
    func testCreatesMemoryPressureHintWhenPressureCriticalAndSwapInUse() {
        let snapshot = SystemSnapshot(
            capturedAt: .distantPast,
            cpu: CPUStatus(totalUsage: 31, userUsage: 20, systemUsage: 11),
            memory: MemoryStatus(
                usedGB: 28,
                totalGB: 32,
                pressure: .critical,
                swapUsedGB: 4.2
            ),
            disk: DiskStatus(
                usedGB: 0,
                totalGB: 1,
                readBytesPerSecond: 0,
                writeBytesPerSecond: 0
            ),
            network: NetworkStatus(
                downloadBytesPerSecond: 0,
                uploadBytesPerSecond: 0,
                isExpensive: false
            ),
            power: nil,
            thermal: ThermalStatus(state: .serious)
        )
        let history = ResourceHistory(
            cpuUsage: [20, 28, 24],
            downloadBytesPerSecond: [],
            uploadBytesPerSecond: []
        )

        let hints = ActionHintEngine().makeHints(snapshot: snapshot, history: history)

        XCTAssertTrue(hints.contains(where: { $0.kind == .memory && $0.severity == .warning }))
    }

    func testCreatesCpuHintForSustainedHighLoad() {
        let snapshot = SystemSnapshot(
            capturedAt: .distantPast,
            cpu: CPUStatus(totalUsage: 88, userUsage: 57, systemUsage: 31),
            memory: MemoryStatus(usedGB: 9, totalGB: 32, pressure: .normal, swapUsedGB: 0),
            disk: DiskStatus(
                usedGB: 0,
                totalGB: 1,
                readBytesPerSecond: 0,
                writeBytesPerSecond: 0
            ),
            network: NetworkStatus(
                downloadBytesPerSecond: 0,
                uploadBytesPerSecond: 0,
                isExpensive: false
            ),
            power: nil,
            thermal: ThermalStatus(state: .nominal)
        )
        let history = ResourceHistory(
            cpuUsage: Array(repeating: 82, count: 10),
            downloadBytesPerSecond: [],
            uploadBytesPerSecond: []
        )

        let hints = ActionHintEngine().makeHints(snapshot: snapshot, history: history)

        XCTAssertTrue(hints.contains(where: { $0.kind == .cpu && $0.severity == .info }))
    }

    func testCreatesNetworkHintForLargeTransferBurst() {
        let snapshot = SystemSnapshot(
            capturedAt: .distantPast,
            cpu: CPUStatus(totalUsage: 18, userUsage: 9, systemUsage: 9),
            memory: MemoryStatus(usedGB: 9, totalGB: 32, pressure: .normal, swapUsedGB: 0),
            disk: DiskStatus(
                usedGB: 0,
                totalGB: 1,
                readBytesPerSecond: 0,
                writeBytesPerSecond: 0
            ),
            network: NetworkStatus(
                downloadBytesPerSecond: 18_000_000,
                uploadBytesPerSecond: 3_000_000,
                isExpensive: false
            ),
            power: nil,
            thermal: ThermalStatus(state: .nominal)
        )
        let history = ResourceHistory(
            cpuUsage: [],
            downloadBytesPerSecond: [2_000_000, 6_000_000],
            uploadBytesPerSecond: []
        )

        let hints = ActionHintEngine().makeHints(snapshot: snapshot, history: history)

        XCTAssertTrue(hints.contains(where: { $0.kind == .network }))
    }
}
