import Foundation

public final class SnapshotHistoryStore {
    private let limit: Int
    private let lock = NSLock()
    private var cpuUsage: [Double] = []
    private var downloadBytesPerSecond: [Double] = []
    private var uploadBytesPerSecond: [Double] = []

    public init(limit: Int = 60) {
        self.limit = limit
    }

    public func append(_ snapshot: SystemSnapshot) {
        lock.lock()
        defer { lock.unlock() }

        cpuUsage.append(snapshot.cpu.totalUsage)
        downloadBytesPerSecond.append(snapshot.network.downloadBytesPerSecond)
        uploadBytesPerSecond.append(snapshot.network.uploadBytesPerSecond)

        trimIfNeeded(&cpuUsage)
        trimIfNeeded(&downloadBytesPerSecond)
        trimIfNeeded(&uploadBytesPerSecond)
    }

    public var history: ResourceHistory {
        lock.lock()
        defer { lock.unlock() }
        return ResourceHistory(
            cpuUsage: cpuUsage,
            downloadBytesPerSecond: downloadBytesPerSecond,
            uploadBytesPerSecond: uploadBytesPerSecond
        )
    }

    private func trimIfNeeded(_ values: inout [Double]) {
        if values.count > limit {
            values.removeFirst(values.count - limit)
        }
    }
}
