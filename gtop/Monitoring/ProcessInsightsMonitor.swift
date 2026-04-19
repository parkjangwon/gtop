import Darwin
import Foundation

struct ProcessInsightsSnapshot {
    var diskStatus: DiskStatus
    var entriesBySection: [ResourceSection: [ProcessUsageEntry]]
}

final class ProcessInsightsMonitor {
    private struct PreviousUsage {
        var timestamp: TimeInterval
        var cpuTimeNanos: UInt64
        var diskReadBytes: UInt64
        var diskWriteBytes: UInt64
    }

    private struct ProcessSample {
        var name: String
        var currentUsage: PreviousUsage
        var memoryEntry: ProcessUsageEntry
    }

    private struct UsageDelta {
        var cpuPercent: Double
        var readRate: Double
        var writeRate: Double
        var totalRate: Double
    }

    private var previousUsageByPID: [Int32: PreviousUsage] = [:]
    private let limit: Int

    init(limit: Int = 6) {
        self.limit = limit
    }

    func sample() -> ProcessInsightsSnapshot {
        let now = ProcessInfo.processInfo.systemUptime
        let pids = currentPIDs()
        var cpuEntries: [ProcessUsageEntry] = []
        var memoryEntries: [ProcessUsageEntry] = []
        var diskEntries: [ProcessUsageEntry] = []
        var nextUsageByPID: [Int32: PreviousUsage] = [:]
        var totalDiskReadRate: Double = 0
        var totalDiskWriteRate: Double = 0
        let filesystemUsage = filesystemUsage()

        for pid in pids where pid > 0 {
            guard let sample = processSample(for: pid, now: now) else {
                continue
            }

            nextUsageByPID[pid] = sample.currentUsage
            memoryEntries.append(sample.memoryEntry)

            guard let previous = previousUsageByPID[pid] else {
                continue
            }

            let delta = usageDelta(from: previous, to: sample.currentUsage)
            totalDiskReadRate += delta.readRate
            totalDiskWriteRate += delta.writeRate

            if let cpuEntry = cpuEntry(for: pid, name: sample.name, cpuPercent: delta.cpuPercent) {
                cpuEntries.append(cpuEntry)
            }

            if let diskEntry = diskEntry(for: pid, name: sample.name, delta: delta) {
                diskEntries.append(diskEntry)
            }
        }

        previousUsageByPID = nextUsageByPID

        return ProcessInsightsSnapshot(
            diskStatus: DiskStatus(
                usedGB: filesystemUsage.usedGB,
                totalGB: filesystemUsage.totalGB,
                readBytesPerSecond: totalDiskReadRate,
                writeBytesPerSecond: totalDiskWriteRate
            ),
            entriesBySection: [
                .cpu: ProcessUsageRanker.topEntries(from: cpuEntries, limit: limit),
                .memory: ProcessUsageRanker.topEntries(from: memoryEntries, limit: limit),
                .disk: ProcessUsageRanker.topEntries(from: diskEntries, limit: limit)
            ]
        )
    }

    private func processSample(
        for pid: Int32,
        now: TimeInterval
    ) -> ProcessSample? {
        guard let info = usageInfo(for: pid) else {
            return nil
        }

        let name = processName(for: pid)
        return ProcessSample(
            name: name,
            currentUsage: PreviousUsage(
                timestamp: now,
                cpuTimeNanos: info.ri_user_time + info.ri_system_time,
                diskReadBytes: info.ri_diskio_bytesread,
                diskWriteBytes: info.ri_diskio_byteswritten
            ),
            memoryEntry: ProcessUsageEntry(
                pid: pid,
                name: name,
                primaryValueText: Formatters.bytes(Int64(info.ri_resident_size)),
                secondaryValueText: "Resident memory",
                sortValue: Double(info.ri_resident_size),
                section: .memory
            )
        )
    }

    private func usageInfo(for pid: Int32) -> rusage_info_v4? {
        var info = rusage_info_v4()
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { rebound in
                proc_pid_rusage(pid, RUSAGE_INFO_V4, rebound)
            }
        }

        return status == 0 ? info : nil
    }

    private func usageDelta(
        from previous: PreviousUsage,
        to current: PreviousUsage
    ) -> UsageDelta {
        let elapsed = max(current.timestamp - previous.timestamp, 0.001)
        let cpuDelta = current.cpuTimeNanos &- previous.cpuTimeNanos
        let readDelta = current.diskReadBytes &- previous.diskReadBytes
        let writeDelta = current.diskWriteBytes &- previous.diskWriteBytes
        let cpuPercent = (Double(cpuDelta) / (elapsed * 1_000_000_000.0)) * 100.0
        let readRate = Double(readDelta) / elapsed
        let writeRate = Double(writeDelta) / elapsed

        return UsageDelta(
            cpuPercent: cpuPercent,
            readRate: readRate,
            writeRate: writeRate,
            totalRate: readRate + writeRate
        )
    }

    private func cpuEntry(
        for pid: Int32,
        name: String,
        cpuPercent: Double
    ) -> ProcessUsageEntry? {
        guard cpuPercent > 0 else {
            return nil
        }

        return ProcessUsageEntry(
            pid: pid,
            name: name,
            primaryValueText: Formatters.percent(cpuPercent),
            secondaryValueText: "CPU share",
            sortValue: cpuPercent,
            section: .cpu
        )
    }

    private func diskEntry(
        for pid: Int32,
        name: String,
        delta: UsageDelta
    ) -> ProcessUsageEntry? {
        guard delta.totalRate > 0 else {
            return nil
        }

        return ProcessUsageEntry(
            pid: pid,
            name: name,
            primaryValueText: "R \(Formatters.bytesPerSecond(delta.readRate))",
            secondaryValueText: "W \(Formatters.bytesPerSecond(delta.writeRate))",
            sortValue: delta.totalRate,
            section: .disk
        )
    }

    func fetchNetworkEntries() -> [ProcessUsageEntry] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
        process.arguments = ["-P", "-L", "1", "-J", "bytes_in,bytes_out", "-x"]
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            return []
        }

        process.waitUntilExit()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        let entries = output
            .split(whereSeparator: \.isNewline)
            .dropFirst()
            .compactMap(parseNetworkRow)

        return ProcessUsageRanker.topEntries(from: entries, limit: limit)
    }

    private func currentPIDs() -> [Int32] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }

        let buffer = UnsafeMutablePointer<pid_t>.allocate(capacity: Int(count))
        defer { buffer.deallocate() }

        let bufferSize = Int(count) * MemoryLayout<pid_t>.stride
        let bytes = proc_listallpids(buffer, Int32(bufferSize))
        let pidCount = max(Int(bytes) / MemoryLayout<pid_t>.stride, 0)
        return Array(UnsafeBufferPointer(start: buffer, count: pidCount))
    }

    private func processName(for pid: Int32) -> String {
        let nameBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(MAXPATHLEN))
        defer { nameBuffer.deallocate() }

        if proc_name(pid, nameBuffer, UInt32(MAXPATHLEN)) > 0 {
            return String(cString: nameBuffer)
        }

        if proc_pidpath(pid, nameBuffer, UInt32(MAXPATHLEN)) > 0 {
            return URL(fileURLWithPath: String(cString: nameBuffer)).lastPathComponent
        }

        return "pid \(pid)"
    }

    private func parseNetworkRow(_ row: Substring) -> ProcessUsageEntry? {
        let columns = row.split(separator: ",", omittingEmptySubsequences: false)
        guard columns.count >= 3 else { return nil }

        let processColumn = String(columns[0])
        let inbound = Double(columns[1]) ?? 0
        let outbound = Double(columns[2]) ?? 0
        let total = inbound + outbound
        guard total > 0 else { return nil }

        let components = processColumn.split(separator: ".", omittingEmptySubsequences: false)
        let pid = Int32(components.last ?? "") ?? 0
        let name = components.dropLast().joined(separator: ".")

        return ProcessUsageEntry(
            pid: pid,
            name: name.isEmpty ? processColumn : name,
            primaryValueText: "↓ \(Formatters.bytesPerSecond(inbound))",
            secondaryValueText: "↑ \(Formatters.bytesPerSecond(outbound))",
            sortValue: total,
            section: .network
        )
    }

    private func filesystemUsage() -> (usedGB: Double, totalGB: Double) {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let totalBytes = (attributes[.systemSize] as? NSNumber)?.doubleValue ?? 0
            let freeBytes = (attributes[.systemFreeSize] as? NSNumber)?.doubleValue ?? 0
            let usedBytes = max(totalBytes - freeBytes, 0)
            return (
                usedGB: usedBytes / 1_073_741_824,
                totalGB: max(totalBytes, 1) / 1_073_741_824
            )
        } catch {
            return (usedGB: 0, totalGB: 1)
        }
    }
}
