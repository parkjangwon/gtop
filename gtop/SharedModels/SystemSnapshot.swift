import Foundation

public enum MemoryPressureLevel: String, Codable, Equatable, Sendable {
    case normal
    case warning
    case critical
}

public enum ThermalState: String, Codable, Equatable, Sendable {
    case nominal
    case fair
    case serious
    case critical
}

public struct CPUStatus: Codable, Equatable, Sendable {
    public var totalUsage: Double
    public var userUsage: Double
    public var systemUsage: Double

    public init(totalUsage: Double, userUsage: Double, systemUsage: Double) {
        self.totalUsage = totalUsage
        self.userUsage = userUsage
        self.systemUsage = systemUsage
    }
}

public struct MemoryStatus: Codable, Equatable, Sendable {
    public var usedGB: Double
    public var totalGB: Double
    public var pressure: MemoryPressureLevel
    public var swapUsedGB: Double

    public init(usedGB: Double, totalGB: Double, pressure: MemoryPressureLevel, swapUsedGB: Double) {
        self.usedGB = usedGB
        self.totalGB = totalGB
        self.pressure = pressure
        self.swapUsedGB = swapUsedGB
    }
}

public struct NetworkStatus: Codable, Equatable, Sendable {
    public var downloadBytesPerSecond: Double
    public var uploadBytesPerSecond: Double
    public var isExpensive: Bool

    public init(downloadBytesPerSecond: Double, uploadBytesPerSecond: Double, isExpensive: Bool) {
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.isExpensive = isExpensive
    }
}

public struct PowerStatus: Codable, Equatable, Sendable {
    public var batteryLevel: Double?
    public var isCharging: Bool
    public var lowPowerModeEnabled: Bool

    public init(batteryLevel: Double?, isCharging: Bool, lowPowerModeEnabled: Bool) {
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.lowPowerModeEnabled = lowPowerModeEnabled
    }
}

public struct ThermalStatus: Codable, Equatable, Sendable {
    public var state: ThermalState

    public init(state: ThermalState) {
        self.state = state
    }
}

public struct SystemSnapshot: Codable, Equatable, Sendable {
    public var capturedAt: Date
    public var cpu: CPUStatus
    public var memory: MemoryStatus
    public var disk: DiskStatus
    public var network: NetworkStatus
    public var power: PowerStatus?
    public var thermal: ThermalStatus

    public init(
        capturedAt: Date,
        cpu: CPUStatus,
        memory: MemoryStatus,
        disk: DiskStatus,
        network: NetworkStatus,
        power: PowerStatus?,
        thermal: ThermalStatus
    ) {
        self.capturedAt = capturedAt
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.network = network
        self.power = power
        self.thermal = thermal
    }

    public static let empty = SystemSnapshot(
        capturedAt: .now,
        cpu: CPUStatus(totalUsage: 0, userUsage: 0, systemUsage: 0),
        memory: MemoryStatus(usedGB: 0, totalGB: 1, pressure: .normal, swapUsedGB: 0),
        disk: DiskStatus(usedGB: 0, totalGB: 1, readBytesPerSecond: 0, writeBytesPerSecond: 0),
        network: NetworkStatus(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0, isExpensive: false),
        power: nil,
        thermal: ThermalStatus(state: .nominal)
    )
}

public struct ResourceHistory: Codable, Equatable, Sendable {
    public var cpuUsage: [Double]
    public var downloadBytesPerSecond: [Double]
    public var uploadBytesPerSecond: [Double]

    public init(cpuUsage: [Double], downloadBytesPerSecond: [Double], uploadBytesPerSecond: [Double]) {
        self.cpuUsage = cpuUsage
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.uploadBytesPerSecond = uploadBytesPerSecond
    }

    public static let empty = ResourceHistory(cpuUsage: [], downloadBytesPerSecond: [], uploadBytesPerSecond: [])
}

public enum HUDMode: String, Codable, Equatable, Sendable {
    case standard
    case mini
}

public struct HUDState: Codable, Equatable, Sendable {
    public var isVisible: Bool
    public var isAlwaysOnTop: Bool
    public var mode: HUDMode

    public init(isVisible: Bool, isAlwaysOnTop: Bool, mode: HUDMode = .standard) {
        self.isVisible = isVisible
        self.isAlwaysOnTop = isAlwaysOnTop
        self.mode = mode
    }
}

public enum HUDDismissalPolicy {
    public static func shouldDismissOnOutsideClick(
        hudState: HUDState,
        hitOwnedWindow: Bool
    ) -> Bool {
        hudState.isVisible && !hudState.isAlwaysOnTop && !hitOwnedWindow
    }
}
