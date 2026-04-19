import Darwin
import Foundation
import IOKit.ps

protocol CPUMonitoring {
    func sample() -> CPUStatus
}

protocol MemoryMonitoring {
    func sample() -> MemoryStatus
}

protocol NetworkMonitoring {
    func sample() -> NetworkStatus
}

protocol PowerMonitoring {
    func sample() -> PowerStatus?
}

protocol ThermalMonitoring {
    func sample() -> ThermalStatus
}

final class CPUMonitor: CPUMonitoring {
    private var previous: host_cpu_load_info_data_t?

    func sample() -> CPUStatus {
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride
                / MemoryLayout<integer_t>.stride
        )
        var info = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return CPUStatus(totalUsage: 0, userUsage: 0, systemUsage: 0)
        }

        defer { previous = info }

        guard let previous else {
            return CPUStatus(totalUsage: 0, userUsage: 0, systemUsage: 0)
        }

        let user = Double(info.cpu_ticks.0 - previous.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1 - previous.cpu_ticks.1)
        let idle = Double(info.cpu_ticks.2 - previous.cpu_ticks.2)
        let nice = Double(info.cpu_ticks.3 - previous.cpu_ticks.3)
        let total = max(user + system + idle + nice, 1)

        return CPUStatus(
            totalUsage: ((user + system + nice) / total) * 100,
            userUsage: (user / total) * 100,
            systemUsage: ((system + nice) / total) * 100
        )
    }
}

final class MemoryMonitor: MemoryMonitoring {
    func sample() -> MemoryStatus {
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        var statistics = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &statistics) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryStatus(
                usedGB: 0,
                totalGB: totalMemory / 1_073_741_824,
                pressure: .normal,
                swapUsedGB: 0
            )
        }

        let anonymous = Double(statistics.internal_page_count) * Double(pageSize)
        let wired = Double(statistics.wire_count) * Double(pageSize)
        let compressed = Double(statistics.compressor_page_count) * Double(pageSize)

        // `active` can still include a fair amount of cache-ish memory depending on the
        // system state. For a user-facing RAM gauge that stays closer to tools like
        // RunCat, anonymous(app) memory + wired + compressed is a better approximation.
        let used = anonymous + wired + compressed
        let swapUsed = currentSwapUsage()
        let usedRatio = used / max(totalMemory, 1)

        let pressure: MemoryPressureLevel
        if usedRatio >= 0.9 || swapUsed >= 1_073_741_824 {
            pressure = .critical
        } else if usedRatio >= 0.75 {
            pressure = .warning
        } else {
            pressure = .normal
        }

        return MemoryStatus(
            usedGB: used / 1_073_741_824,
            totalGB: totalMemory / 1_073_741_824,
            pressure: pressure,
            swapUsedGB: swapUsed / 1_073_741_824
        )
    }

    private func currentSwapUsage() -> Double {
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.stride

        let result = sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0)
        guard result == 0 else {
            return 0
        }

        return Double(swapUsage.xsu_used)
    }
}

final class NetworkMonitor: NetworkMonitoring {
    private var previousTotals: (inbound: UInt64, outbound: UInt64)?
    private var previousDate: Date?

    func sample() -> NetworkStatus {
        let now = Date()
        let totals = interfaceTotals()

        defer {
            previousTotals = totals
            previousDate = now
        }

        guard let previousTotals, let previousDate else {
            return NetworkStatus(
                downloadBytesPerSecond: 0,
                uploadBytesPerSecond: 0,
                isExpensive: false
            )
        }

        let elapsed = max(now.timeIntervalSince(previousDate), 1)
        let inboundDelta = Double(totals.inbound &- previousTotals.inbound) / elapsed
        let outboundDelta = Double(totals.outbound &- previousTotals.outbound) / elapsed

        return NetworkStatus(
            downloadBytesPerSecond: max(inboundDelta, 0),
            uploadBytesPerSecond: max(outboundDelta, 0),
            isExpensive: false
        )
    }

    private func interfaceTotals() -> (inbound: UInt64, outbound: UInt64) {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        var inbound: UInt64 = 0
        var outbound: UInt64 = 0

        guard getifaddrs(&pointer) == 0, let first = pointer else {
            return (0, 0)
        }

        defer { freeifaddrs(pointer) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let interface = current.pointee
            let flags = Int32(interface.ifa_flags)
            let family = interface.ifa_addr.pointee.sa_family

            if family == UInt8(AF_LINK),
               (flags & IFF_UP) != 0,
               (flags & IFF_LOOPBACK) == 0,
               let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                inbound += UInt64(data.pointee.ifi_ibytes)
                outbound += UInt64(data.pointee.ifi_obytes)
            }

            cursor = interface.ifa_next
        }

        return (inbound, outbound)
    }
}

final class PowerMonitor: PowerMonitoring {
    func sample() -> PowerStatus? {
        let lowPowerEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = list.first,
              let description = IOPSGetPowerSourceDescription(
                snapshot,
                source
              )?.takeUnretainedValue() as? [String: Any] else {
            return nil
        }

        let current = description[kIOPSCurrentCapacityKey] as? Double
        let max = description[kIOPSMaxCapacityKey] as? Double
        let batteryLevel = (current != nil && max != nil && max != 0) ? (current! / max!) * 100 : nil
        let powerSource = description[kIOPSPowerSourceStateKey] as? String
        let isCharging = powerSource == kIOPSACPowerValue

        return PowerStatus(
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            lowPowerModeEnabled: lowPowerEnabled
        )
    }
}

final class ThermalMonitor: ThermalMonitoring {
    func sample() -> ThermalStatus {
        let state: ThermalState
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            state = .nominal
        case .fair:
            state = .fair
        case .serious:
            state = .serious
        case .critical:
            state = .critical
        @unknown default:
            state = .nominal
        }

        return ThermalStatus(state: state)
    }
}
