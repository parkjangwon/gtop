import Foundation
import Combine

public final class SystemMonitorService: ObservableObject, @unchecked Sendable {
    private let cpuMonitor: CPUMonitoring
    private let memoryMonitor: MemoryMonitoring
    private let networkMonitor: NetworkMonitoring
    private let powerMonitor: PowerMonitoring
    private let thermalMonitor: ThermalMonitoring
    private let processInsightsMonitor: ProcessInsightsMonitor
    private let historyStore: SnapshotHistoryStore
    private let hintEngine: ActionHintEngine
    private let queue = DispatchQueue(label: "org.parkjw.gtop.monitoring", qos: .utility)
    private var timer: DispatchSourceTimer?

    @Published public private(set) var snapshot: SystemSnapshot
    @Published public private(set) var history: ResourceHistory
    @Published public private(set) var hints: [ActionHint]
    @Published public private(set) var topProcessesBySection: [ResourceSection: [ProcessUsageEntry]]

    public init() {
        cpuMonitor = CPUMonitor()
        memoryMonitor = MemoryMonitor()
        networkMonitor = NetworkMonitor()
        powerMonitor = PowerMonitor()
        thermalMonitor = ThermalMonitor()
        processInsightsMonitor = ProcessInsightsMonitor(limit: 6)
        historyStore = SnapshotHistoryStore(limit: 60)
        hintEngine = ActionHintEngine()
        snapshot = .empty
        history = .empty
        hints = []
        topProcessesBySection = [:]
    }

    init(
        cpuMonitor: CPUMonitoring,
        memoryMonitor: MemoryMonitoring,
        networkMonitor: NetworkMonitoring,
        powerMonitor: PowerMonitoring,
        thermalMonitor: ThermalMonitoring,
        processInsightsMonitor: ProcessInsightsMonitor,
        historyStore: SnapshotHistoryStore,
        hintEngine: ActionHintEngine
    ) {
        self.cpuMonitor = cpuMonitor
        self.memoryMonitor = memoryMonitor
        self.networkMonitor = networkMonitor
        self.powerMonitor = powerMonitor
        self.thermalMonitor = thermalMonitor
        self.processInsightsMonitor = processInsightsMonitor
        self.historyStore = historyStore
        self.hintEngine = hintEngine
        snapshot = .empty
        history = .empty
        hints = []
        topProcessesBySection = [:]
    }

    public func start() {
        guard timer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
            self?.sample()
        }
        timer.resume()
        self.timer = timer
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }

    public func processEntries(for section: ResourceSection) -> [ProcessUsageEntry] {
        topProcessesBySection[section] ?? []
    }

    public func refreshProcessEntries(for section: ResourceSection) {
        guard section == .network else { return }

        queue.async { [weak self] in
            guard let self else { return }
            let entries = self.processInsightsMonitor.fetchNetworkEntries()
            DispatchQueue.main.async { [weak self] in
                self?.topProcessesBySection[.network] = entries
            }
        }
    }

    private func sample() {
        let processInsights = processInsightsMonitor.sample()
        let snapshot = SystemSnapshot(
            capturedAt: .now,
            cpu: cpuMonitor.sample(),
            memory: memoryMonitor.sample(),
            disk: processInsights.diskStatus,
            network: networkMonitor.sample(),
            power: powerMonitor.sample(),
            thermal: thermalMonitor.sample()
        )

        historyStore.append(snapshot)
        let history = historyStore.history
        let hints = hintEngine.makeHints(snapshot: snapshot, history: history)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.snapshot = snapshot
            self.history = history
            self.hints = hints
            self.topProcessesBySection[.cpu] = processInsights.entriesBySection[.cpu] ?? []
            self.topProcessesBySection[.memory] = processInsights.entriesBySection[.memory] ?? []
            self.topProcessesBySection[.disk] = processInsights.entriesBySection[.disk] ?? []
        }
    }
}
