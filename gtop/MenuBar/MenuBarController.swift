import AppKit
import gtopCore

@MainActor
final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onToggleHUD: () -> Void
    private let onToggleLaunchAtLogin: () -> Void
    private let onShowShortcutSettings: () -> Void
    private let onToggleForegroundMode: () -> Void
    private let onQuit: () -> Void
    private var hudState = HUDState(isVisible: true, isAlwaysOnTop: false)
    private var launchAtLoginState: LaunchAtLoginMenuState = .disabled

    init(
        onToggleHUD: @escaping () -> Void,
        onToggleLaunchAtLogin: @escaping () -> Void,
        onShowShortcutSettings: @escaping () -> Void,
        onToggleForegroundMode: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onToggleHUD = onToggleHUD
        self.onToggleLaunchAtLogin = onToggleLaunchAtLogin
        self.onShowShortcutSettings = onShowShortcutSettings
        self.onToggleForegroundMode = onToggleForegroundMode
        self.onQuit = onQuit
        super.init()
        configureStatusItem()
    }

    func update(
        hudState: HUDState? = nil,
        launchAtLoginState: LaunchAtLoginMenuState? = nil
    ) {
        if let hudState {
            self.hudState = hudState
        }

        if let launchAtLoginState {
            self.launchAtLoginState = launchAtLoginState
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "waveform.path.ecg.rectangle", accessibilityDescription: "gtop")
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(handleStatusItemClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc
    private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent, let button = statusItem.button else {
            onToggleHUD()
            return
        }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.autoenablesItems = false

            let shortcutItem = NSMenuItem(
                title: "Keyboard Shortcut…",
                action: #selector(showShortcutSettingsFromMenu),
                keyEquivalent: ""
            )
            shortcutItem.target = self
            shortcutItem.isEnabled = true
            menu.addItem(shortcutItem)

            let foregroundItem = NSMenuItem(
                title: hudState.isAlwaysOnTop ? "Turn Foreground Mode Off" : "Turn Foreground Mode On",
                action: #selector(toggleForegroundFromMenu),
                keyEquivalent: ""
            )
            foregroundItem.target = self
            foregroundItem.isEnabled = true
            menu.addItem(foregroundItem)

            let launchAtLoginItem = NSMenuItem(
                title: launchAtLoginState.menuTitle,
                action: #selector(toggleLaunchAtLoginFromMenu),
                keyEquivalent: ""
            )
            launchAtLoginItem.target = self
            launchAtLoginItem.isEnabled = true
            menu.addItem(launchAtLoginItem)

            menu.addItem(.separator())

            let quitItem = NSMenuItem(title: "Quit", action: #selector(quitFromMenu), keyEquivalent: "q")
            quitItem.target = self
            quitItem.isEnabled = true
            menu.addItem(quitItem)

            NSMenu.popUpContextMenu(menu, with: event, for: button)
        } else {
            onToggleHUD()
        }
    }

    @objc
    private func showShortcutSettingsFromMenu() {
        onShowShortcutSettings()
    }

    @objc
    private func toggleForegroundFromMenu() {
        onToggleForegroundMode()
    }

    @objc
    private func toggleLaunchAtLoginFromMenu() {
        onToggleLaunchAtLogin()
    }

    @objc
    private func quitFromMenu() {
        onQuit()
    }
}
