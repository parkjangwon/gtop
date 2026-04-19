import Foundation

public enum ResourceSection: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case cpu
    case memory
    case disk
    case network

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .disk: return "Disk"
        case .network: return "Network"
        }
    }
}

public struct DiskStatus: Codable, Equatable, Sendable {
    public var usedGB: Double
    public var totalGB: Double
    public var readBytesPerSecond: Double
    public var writeBytesPerSecond: Double

    public init(usedGB: Double, totalGB: Double, readBytesPerSecond: Double, writeBytesPerSecond: Double) {
        self.usedGB = usedGB
        self.totalGB = totalGB
        self.readBytesPerSecond = readBytesPerSecond
        self.writeBytesPerSecond = writeBytesPerSecond
    }
}

public struct ProcessUsageEntry: Codable, Equatable, Identifiable, Sendable {
    public var pid: Int32
    public var name: String
    public var primaryValueText: String
    public var secondaryValueText: String
    public var sortValue: Double
    public var section: ResourceSection

    public var id: String { "\(section.rawValue)-\(pid)-\(name)" }

    public init(
        pid: Int32,
        name: String,
        primaryValueText: String,
        secondaryValueText: String,
        sortValue: Double,
        section: ResourceSection
    ) {
        self.pid = pid
        self.name = name
        self.primaryValueText = primaryValueText
        self.secondaryValueText = secondaryValueText
        self.sortValue = sortValue
        self.section = section
    }
}

public enum ProcessUsageRanker {
    public static func topEntries(from entries: [ProcessUsageEntry], limit: Int) -> [ProcessUsageEntry] {
        entries
            .filter { $0.sortValue > 0 }
            .sorted { lhs, rhs in
                if lhs.sortValue == rhs.sortValue {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.sortValue > rhs.sortValue
            }
            .prefix(limit)
            .map { $0 }
    }
}
