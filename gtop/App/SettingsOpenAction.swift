import AppKit

@MainActor
protocol SettingsPresenting: AnyObject {
    func showShortcutSettings()
}
