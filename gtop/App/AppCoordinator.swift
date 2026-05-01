import AppKit
import Foundation
import gtopCore

@MainActor
final class AppCoordinator: SettingsPresenting {
    private let monitorService = SystemMonitorService()
    private let preferencesStore = HUDPreferencesStore()
    private let shortcutPreferencesStore = ShortcutPreferencesStore()
    private let launchAtLoginController = LaunchAtLoginController()
    private lazy var hotKeyManager = GlobalHotKeyManager { [weak self] in
        self?.toggleHUDVisibility()
    }
    private lazy var hudController = HUDPanelController(
        monitorService: monitorService,
        preferencesStore: preferencesStore,
        appVersion: appVersion
    )
    private lazy var menuBarController = MenuBarController(
        onToggleHUD: { [weak self] in self?.toggleHUDVisibility() },
        onToggleLaunchAtLogin: { [weak self] in self?.toggleLaunchAtLogin() },
        onShowShortcutSettings: { [weak self] in self?.showShortcutSettings() },
        onToggleForegroundMode: { [weak self] in self?.toggleForegroundMode() },
        onQuit: { [weak self] in self?.quit() }
    )
    private lazy var shortcutSettingsController = ShortcutSettingsWindowController(
        viewModel: ShortcutSettingsViewModel(
            preferencesStore: shortcutPreferencesStore,
            hotKeyManager: hotKeyManager
        )
    )

    private var globalOutsideClickMonitor: Any?
    private let appVersion =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

    func start() {
        monitorService.start()
        hudController.onStateChange = { [weak self] state in
            self?.menuBarController.update(hudState: state)
        }
        hudController.restoreOnLaunch()
        refreshMenuBarState()
        restoreShortcut()
        installOutsideClickMonitor()
    }

    func stop() {
        monitorService.stop()
        removeOutsideClickMonitor()
    }

    func showShortcutSettings() {
        shortcutSettingsController.present()
    }

    private func toggleHUDVisibility() {
        hudController.toggleVisibility()
        refreshMenuBarState()
    }

    private func toggleForegroundMode() {
        hudController.setAlwaysOnTop(!hudController.currentState.isAlwaysOnTop)
        refreshMenuBarState()
    }

    private func quit() {
        stop()
        NSApp.terminate(nil)
    }

    private func restoreShortcut() {
        guard let shortcut = shortcutPreferencesStore.load() else { return }
        do {
            try hotKeyManager.register(shortcut: shortcut)
        } catch {
            shortcutPreferencesStore.save(nil)
        }
    }

    private func installOutsideClickMonitor() {
        removeOutsideClickMonitor()

        globalOutsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.dismissHUDForOutsideClickIfNeeded()
            }
        }
    }

    private func removeOutsideClickMonitor() {
        if let globalOutsideClickMonitor {
            NSEvent.removeMonitor(globalOutsideClickMonitor)
            self.globalOutsideClickMonitor = nil
        }
    }

    private func dismissHUDForOutsideClickIfNeeded() {
        let clickLocation = NSEvent.mouseLocation
        let hitOwnedWindow = NSApp.windows.contains { window in
            window.isVisible && window.frame.contains(clickLocation)
        }

        guard HUDDismissalPolicy.shouldDismissOnOutsideClick(
            hudState: hudController.currentState,
            hitOwnedWindow: hitOwnedWindow
        ) else {
            return
        }

        hudController.hide(persistVisibility: false)
        refreshMenuBarState()
    }

    private func toggleLaunchAtLogin() {
        do {
            _ = try launchAtLoginController.toggle()
        } catch {
            presentLaunchAtLoginError(error)
        }

        refreshMenuBarState()
    }

    private func refreshMenuBarState() {
        menuBarController.update(
            hudState: hudController.currentState,
            launchAtLoginState: launchAtLoginController.menuState
        )
    }

    private func presentLaunchAtLoginError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Could not change Launch at Login."
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
