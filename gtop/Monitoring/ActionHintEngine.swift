import Foundation

public struct ActionHintEngine {
    public init() {}

    public func makeHints(snapshot: SystemSnapshot, history: ResourceHistory) -> [ActionHint] {
        var hints: [ActionHint] = []

        appendMemoryHint(to: &hints, snapshot: snapshot)
        appendCPUHint(to: &hints, snapshot: snapshot, history: history)
        appendNetworkHint(to: &hints, snapshot: snapshot)
        appendPowerHint(to: &hints, snapshot: snapshot)
        appendThermalHint(to: &hints, snapshot: snapshot)

        return Array(hints.prefix(3))
    }

    private func appendMemoryHint(to hints: inout [ActionHint], snapshot: SystemSnapshot) {
        guard snapshot.memory.pressure == .critical || snapshot.memory.swapUsedGB >= 1 else {
            return
        }

        hints.append(
            ActionHint(
                kind: .memory,
                severity: .warning,
                title: "High memory pressure",
                message: "Closing apps or browser tabs may help reduce memory pressure."
            )
        )
    }

    private func appendCPUHint(
        to hints: inout [ActionHint],
        snapshot: SystemSnapshot,
        history: ResourceHistory
    ) {
        let recentCPU = history.cpuUsage.suffix(10)
        let sustainedCPU = recentCPU.isEmpty
            ? snapshot.cpu.totalUsage
            : recentCPU.reduce(0, +) / Double(recentCPU.count)

        guard sustainedCPU >= 75 || snapshot.cpu.totalUsage >= 85 else {
            return
        }

        hints.append(
            ActionHint(
                kind: .cpu,
                severity: .info,
                title: "High CPU load",
                message: "Check for background work such as builds, indexing, or heavy tasks."
            )
        )
    }

    private func appendNetworkHint(to hints: inout [ActionHint], snapshot: SystemSnapshot) {
        let hasNetworkSpike = snapshot.network.downloadBytesPerSecond >= 12_000_000
            || snapshot.network.uploadBytesPerSecond >= 8_000_000
        guard hasNetworkSpike else {
            return
        }

        hints.append(
            ActionHint(
                kind: .network,
                severity: .info,
                title: "Increased network activity",
                message: "A large upload, download, or sync task may be in progress."
            )
        )
    }

    private func appendPowerHint(to hints: inout [ActionHint], snapshot: SystemSnapshot) {
        guard let power = snapshot.power, power.lowPowerModeEnabled else {
            return
        }

        hints.append(
            ActionHint(
                kind: .power,
                severity: .info,
                title: "Low Power Mode enabled",
                message: "Performance may be reduced to prioritize battery life."
            )
        )
    }

    private func appendThermalHint(to hints: inout [ActionHint], snapshot: SystemSnapshot) {
        guard snapshot.thermal.state == .serious || snapshot.thermal.state == .critical else {
            return
        }

        hints.append(
            ActionHint(
                kind: .thermal,
                severity: .warning,
                title: "Thermal pressure detected",
                message: "Consider reducing sustained heavy workloads for a while."
            )
        )
    }
}
