import SwiftUI
import gtopCore

struct MiniHUDContent: View {
    @ObservedObject var monitorService: SystemMonitorService
    let onToggleMode: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    miniMetric(
                        title: "CPU",
                        value: Formatters.percent(monitorService.snapshot.cpu.totalUsage),
                        accent: .mint
                    )
                    miniMetric(
                        title: "MEM",
                        value: Formatters.ratioPercent(
                            used: monitorService.snapshot.memory.usedGB,
                            total: monitorService.snapshot.memory.totalGB
                        ),
                        accent: memoryAccent
                    )
                }

                VStack(spacing: 5) {
                    miniDetail(
                        title: "Disk",
                        value: Formatters.ratioPercent(
                            used: monitorService.snapshot.disk.usedGB,
                            total: monitorService.snapshot.disk.totalGB
                        ),
                        accent: .purple
                    )
                    miniDetail(
                        title: "Net",
                        value: "↓ \(Formatters.bytesPerSecond(monitorService.snapshot.network.downloadBytesPerSecond))"
                            + "  ↑ \(Formatters.bytesPerSecond(monitorService.snapshot.network.uploadBytesPerSecond))",
                        accent: .blue
                    )
                }
            }

            HUDModeToggleButton(
                mode: .mini,
                onToggleMode: onToggleMode
            )
            .padding(4)
        }
    }

    private var memoryAccent: Color {
        switch monitorService.snapshot.memory.pressure {
        case .normal:
            return .teal
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    private func miniMetric(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Circle()
                    .fill(accent.opacity(0.9))
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryText)
            }
            Text(value)
                .font(.system(size: 26, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(primaryText)
                .frame(width: 76, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(cardBackground)
    }

    private func miniDetail(title: String, value: String, accent: Color) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(accent.opacity(0.85))
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(secondaryText)
                .frame(width: 34, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(primaryText)
                .frame(width: title == "Net" ? 132 : 52, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(cardBackground)
    }

    private var primaryText: Color {
        Color.white.opacity(0.98)
    }

    private var secondaryText: Color {
        Color.white.opacity(0.72)
    }

    private var cardBackground: some View {
        Rectangle()
            .fill(Color(red: 0.12, green: 0.135, blue: 0.17).opacity(0.94))
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )
    }
}

struct HUDStatusBadge: View {
    let isAlwaysOnTop: Bool

    var body: some View {
        Text(isAlwaysOnTop ? "FOREGROUND" : "UTILITY")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.98))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isAlwaysOnTop ? Color.accentColor.opacity(0.36) : Color.white.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
            )
            .clipShape(Capsule())
    }
}

struct HUDModeToggleButton: View {
    let mode: HUDMode
    let onToggleMode: () -> Void

    var body: some View {
        Button {
            onToggleMode()
        } label: {
            Image(systemName: mode == .standard
                ? "arrow.down.right.and.arrow.up.left"
                : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.98))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.white.opacity(0.11)))
                .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .help(mode == .standard ? "Switch to Mini Mode" : "Return to Standard Mode")
    }
}

struct ProcessListPopover: View {
    let section: ResourceSection
    let entries: [ProcessUsageEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(section.title) Top Processes")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.96))

            if entries.isEmpty {
                Text("No processes to display.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.68))
            } else {
                processList
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(
            Rectangle()
                .fill(Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.98))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .preferredColorScheme(.dark)
    }

    private var processList: some View {
        ForEach(entries) { entry in
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.96))
                    Text("PID \(entry.pid)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.56))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.primaryValueText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.96))
                    Text(entry.secondaryValueText)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.68))
                }
            }
            .padding(.vertical, 4)
        }
    }
}
