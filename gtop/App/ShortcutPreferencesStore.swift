import Foundation
import gtopCore

@MainActor
final class ShortcutPreferencesStore {
    private let defaults: UserDefaults
    private let key = "gtop.globalShortcut"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> KeyboardShortcut? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(KeyboardShortcut.self, from: data)
    }

    func save(_ shortcut: KeyboardShortcut?) {
        guard let shortcut else {
            defaults.removeObject(forKey: key)
            return
        }

        guard let data = try? JSONEncoder().encode(shortcut) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
