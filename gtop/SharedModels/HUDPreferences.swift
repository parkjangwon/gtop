import CoreGraphics
import Foundation

public struct HUDPreferences: Codable, Equatable {
    public var frame: CGRect
    public var isVisible: Bool
    public var isAlwaysOnTop: Bool
    public var screenIdentifier: String?

    public init(frame: CGRect, isVisible: Bool, isAlwaysOnTop: Bool, screenIdentifier: String?) {
        self.frame = frame
        self.isVisible = isVisible
        self.isAlwaysOnTop = isAlwaysOnTop
        self.screenIdentifier = screenIdentifier
    }
}

public final class HUDPreferencesStore {
    private let userDefaults: UserDefaults
    private let key = "gtop.hud.preferences"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func load() -> HUDPreferences? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(HUDPreferences.self, from: data)
    }

    public func save(_ preferences: HUDPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}
