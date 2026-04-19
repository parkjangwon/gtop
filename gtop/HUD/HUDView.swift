import SwiftUI
import gtopCore

struct HUDView: View {
    @ObservedObject var monitorService: SystemMonitorService
    @ObservedObject var viewState: HUDViewState
    let appVersion: String
    @State private var presentedSection: ResourceSection?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            VStack(spacing: 10) {
                cpuCard
                memoryCard
                diskCard
                networkCard
            }
            if !monitorService.hints.isEmpty {
                hintsSection
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(panelBackground)
        .overlay(
            Rectangle()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.32), radius: 18, y: 12)
        .popover(item: $presentedSection, arrowEdge: .leading) { section in
            ProcessListPopover(
                section: section,
                entries: monitorService.processEntries(for: section)
            )
            .onAppear {
                monitorService.refreshProcessEntries(for: section)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("gtop")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(primaryText)
                    Text("macOS live system monitor")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(secondaryText)
                }
                Spacer()
                statusBadge
            }

            Text(monitorService.snapshot.capturedAt.formatted(date: .omitted, time: .standard))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(secondaryText)
        }
    }

    private var statusBadge: some View {
        Text(viewState.isAlwaysOnTop ? "FOREGROUND" : "UTILITY")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(viewState.isAlwaysOnTop ? Color.accentColor.opacity(0.36) : Color.white.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
            )
            .clipShape(Capsule())
    }

    private var cpuCard: some View {
        sectionCard(for: .cpu) {
            MetricCard(
                title: "CPU",
                primary: Formatters.percent(monitorService.snapshot.cpu.totalUsage),
                secondary: cpuSecondaryText,
                sparklineValues: monitorService.history.cpuUsage,
                accent: .mint
            )
        }
    }

    private var memoryCard: some View {
        sectionCard(for: .memory) {
            MetricCard(
                title: "Memory",
                primary: Formatters.ratioPercent(
                    used: monitorService.snapshot.memory.usedGB,
                    total: monitorService.snapshot.memory.totalGB
                ),
                secondary: memorySecondaryText,
                sparklineValues: monitorService.history.cpuUsage,
                accent: memoryAccent
            )
        }
    }

    private var diskCard: some View {
        sectionCard(for: .disk) {
            MetricCard(
                title: "Disk",
                primary: Formatters.ratioPercent(
                    used: monitorService.snapshot.disk.usedGB,
                    total: monitorService.snapshot.disk.totalGB
                ),
                secondary: diskSecondaryText,
                sparklineValues: [],
                accent: .purple
            )
        }
    }

    private var networkCard: some View {
        sectionCard(for: .network) {
            MetricCard(
                title: "Network",
                primary: "↓ \(Formatters.bytesPerSecond(monitorService.snapshot.network.downloadBytesPerSecond))",
                secondary: "↑ \(Formatters.bytesPerSecond(monitorService.snapshot.network.uploadBytesPerSecond))",
                sparklineValues: monitorService.history.downloadBytesPerSecond,
                accent: .blue
            )
        }
    }

    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hints")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(secondaryText)
            ForEach(Array(monitorService.hints.enumerated()), id: \.offset) { _, hint in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(hint.severity == .warning ? Color.orange : Color.accentColor)
                        .frame(width: 7, height: 7)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hint.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(primaryText)
                        Text(hint.message)
                            .font(.system(size: 11))
                            .foregroundStyle(secondaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(cardBackground)
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

    private var cpuSecondaryText: String {
        "User \(Formatters.percent(monitorService.snapshot.cpu.userUsage))"
            + " · System \(Formatters.percent(monitorService.snapshot.cpu.systemUsage))"
    }

    private var memorySecondaryText: String {
        "\(Formatters.gigabytes(monitorService.snapshot.memory.usedGB))"
            + " / \(Formatters.gigabytes(monitorService.snapshot.memory.totalGB))"
            + " · Pressure \(monitorService.snapshot.memory.pressure.rawValue.capitalized)"
            + " · Swap \(Formatters.gigabytes(monitorService.snapshot.memory.swapUsedGB))"
    }

    private var diskSecondaryText: String {
        "\(Formatters.gigabytes(monitorService.snapshot.disk.usedGB))"
            + " / \(Formatters.gigabytes(monitorService.snapshot.disk.totalGB))"
            + " · R \(Formatters.bytesPerSecond(monitorService.snapshot.disk.readBytesPerSecond))"
            + " · W \(Formatters.bytesPerSecond(monitorService.snapshot.disk.writeBytesPerSecond))"
    }

    @ViewBuilder
    private func sectionCard<Content: View>(
        for section: ResourceSection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            presentedSection = section
        } label: {
            content()
        }
        .buttonStyle(.plain)
    }

    private var primaryText: Color {
        Color.white.opacity(0.98)
    }

    private var secondaryText: Color {
        Color.white.opacity(0.72)
    }

    private var panelBackground: some View {
        Rectangle()
            .fill(Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.98))
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.015)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
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

private struct ProcessListPopover: View {
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
}

private struct MetricCard: View {
    let title: String
    let primary: String
    let secondary: String
    let sparklineValues: [Double]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
                Spacer()
                SparklineView(values: sparklineValues, color: accent)
                    .frame(width: 82, height: 24)
            }
            Text(primary)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.96))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(secondary)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(2)
        }
        .padding(12)
        .background(
            Rectangle()
                .fill(Color(red: 0.12, green: 0.135, blue: 0.17).opacity(0.94))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
    }
}

private struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Canvas { context, size in
            let points = normalizedPoints(in: size)
            guard points.count > 1 else { return }

            var path = Path()
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            context.stroke(path, with: .color(color.opacity(0.95)), lineWidth: 2.2)
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let maxValue = max(values.max() ?? 1, 1)
        let minValue = values.min() ?? 0
        let span = max(maxValue - minValue, 1)

        return values.enumerated().map { index, value in
            let xPosition = size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
            let normalized = (value - minValue) / span
            let yPosition = size.height - (size.height * CGFloat(normalized))
            return CGPoint(x: xPosition, y: yPosition)
        }
    }
}
