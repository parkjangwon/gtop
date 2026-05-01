import AppKit
import SwiftUI
import gtopCore

final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class HUDViewState: ObservableObject {
    @Published var isAlwaysOnTop = false
    @Published var mode: HUDMode = .standard
}

@MainActor
final class HUDPanelController: NSObject, NSWindowDelegate {
    let monitorService: SystemMonitorService
    let preferencesStore: HUDPreferencesStore
    let panel: HUDPanel
    let viewState = HUDViewState()
    let defaultSize = HUDPanelController.size(for: .standard)

    var onStateChange: ((HUDState) -> Void)?

    private(set) var currentState = HUDState(isVisible: true, isAlwaysOnTop: false, mode: .standard)
    private var currentScreenIdentifier: String?

    init(
        monitorService: SystemMonitorService,
        preferencesStore: HUDPreferencesStore,
        appVersion: String
    ) {
        self.monitorService = monitorService
        self.preferencesStore = preferencesStore

        panel = HUDPanel(
            contentRect: CGRect(origin: .zero, size: defaultSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init()

        let rootView = HUDView(
            monitorService: monitorService,
            viewState: viewState,
            appVersion: appVersion,
            onToggleMode: { [weak self] in
                self?.toggleMode()
            }
        )
        let hostingView = NSHostingView(rootView: rootView.preferredColorScheme(.dark))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .normal
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.delegate = self
        panel.contentView?.wantsLayer = true
    }

    func restoreOnLaunch() {
        if let preferences = preferencesStore.load() {
            restore(using: preferences)
            if preferences.isVisible {
                show()
            } else {
                hide()
            }
            setAlwaysOnTop(preferences.isAlwaysOnTop)
        } else {
            showAtDefaultPosition()
        }
    }

    func showAtDefaultPosition() {
        let fallbackScreen = activeScreen()?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultFrame = HUDLayoutResolver.defaultFrame(
            in: fallbackScreen,
            size: defaultSize,
            margin: 24
        )
        panel.setFrame(defaultFrame, display: true)
        currentScreenIdentifier = screenIdentifier(for: fallbackScreen)
        show()
    }

    func toggleVisibility() {
        if currentState.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        panel.orderFrontRegardless()
        currentState.isVisible = true
        persist()
        onStateChange?(currentState)
    }

    func hide(persistVisibility: Bool = true) {
        panel.orderOut(nil)
        currentState.isVisible = false
        if persistVisibility {
            persist()
        }
        onStateChange?(currentState)
    }

    func setAlwaysOnTop(_ enabled: Bool) {
        currentState.isAlwaysOnTop = enabled
        viewState.isAlwaysOnTop = enabled
        panel.level = enabled ? .floating : .normal
        persist()
        onStateChange?(currentState)
    }

    func toggleMode() {
        let nextMode: HUDMode = currentState.mode == .standard ? .mini : .standard
        setMode(nextMode)
    }

    func windowDidMove(_ notification: Notification) {
        updateCurrentScreen()
        persist()
        onStateChange?(currentState)
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        updateCurrentScreen()
        persist()
        onStateChange?(currentState)
    }

    private func restore(using preferences: HUDPreferences) {
        currentState.mode = preferences.mode
        viewState.mode = preferences.mode
        let screens = NSScreen.screens.map(\.visibleFrame)
        let fallback = screenForIdentifier(preferences.screenIdentifier)?.visibleFrame
            ?? activeScreen()?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? preferences.frame
        let resolved = HUDLayoutResolver.resolve(
            savedFrame: preferences.frame,
            screens: screens,
            fallbackScreen: fallback,
            size: Self.size(for: preferences.mode)
        )
        panel.setFrame(resolved, display: true)
        currentScreenIdentifier = preferences.screenIdentifier ?? screenIdentifier(for: resolved)
    }

    private func persist() {
        let preferences = HUDPreferences(
            frame: panel.frame,
            isVisible: currentState.isVisible,
            isAlwaysOnTop: currentState.isAlwaysOnTop,
            mode: currentState.mode,
            screenIdentifier: currentScreenIdentifier
        )
        preferencesStore.save(preferences)
    }

    private func setMode(_ mode: HUDMode) {
        guard currentState.mode != mode else { return }
        currentState.mode = mode
        viewState.mode = mode
        resizePanel(for: mode)
        persist()
        onStateChange?(currentState)
    }

    private func resizePanel(for mode: HUDMode) {
        let size = Self.size(for: mode)
        let currentFrame = panel.frame
        let proposedOrigin = CGPoint(
            x: currentFrame.maxX - size.width,
            y: currentFrame.maxY - size.height
        )
        let visibleFrame = NSScreen.screens
            .first(where: { $0.visibleFrame.intersects(currentFrame) })?
            .visibleFrame
        let resolvedOrigin = visibleFrame.map {
            CGPoint(
                x: min(max(proposedOrigin.x, $0.minX), $0.maxX - size.width),
                y: min(max(proposedOrigin.y, $0.minY), $0.maxY - size.height)
            )
        } ?? proposedOrigin

        panel.setFrame(CGRect(origin: resolvedOrigin, size: size), display: true, animate: true)
        updateCurrentScreen()
    }

    private static func size(for mode: HUDMode) -> CGSize {
        switch mode {
        case .standard:
            return CGSize(width: 320, height: 420)
        case .mini:
            return CGSize(width: 244, height: 142)
        }
    }

    private func activeScreen() -> NSScreen? {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(location, $0.frame, false) }) ?? NSScreen.main
    }

    private func screenForIdentifier(_ identifier: String?) -> NSScreen? {
        guard let identifier else { return nil }
        return NSScreen.screens.first(where: { screenIdentifier(for: $0.visibleFrame) == identifier })
    }

    private func screenIdentifier(for frame: CGRect) -> String? {
        NSScreen.screens.first(where: { $0.visibleFrame.intersects(frame) })
            .flatMap { screen in
                screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            }?
            .stringValue
    }

    private func updateCurrentScreen() {
        currentScreenIdentifier = screenIdentifier(for: panel.frame)
    }
}
