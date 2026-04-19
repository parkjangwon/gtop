import Foundation

public enum Formatters {
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    public static func percent(_ value: Double) -> String {
        "\(percentFormatter.string(from: NSNumber(value: value)) ?? "0")%"
    }

    public static func ratioPercent(used: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return percent((used / total) * 100)
    }

    public static func gigabytes(_ value: Double) -> String {
        String(format: "%.1f GB", value)
    }

    public static func bytes(_ value: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: value)
    }

    public static func bytesPerSecond(_ value: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return "\(formatter.string(fromByteCount: Int64(value)))/s"
    }
}
