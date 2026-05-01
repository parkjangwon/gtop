import CoreGraphics
import Foundation

public struct HUDPreferences: Codable, Equatable {
    public var frame: CGRect
    public var isVisible: Bool
    public var isAlwaysOnTop: Bool
    public var mode: HUDMode
    public var screenIdentifier: String?

    public init(
        frame: CGRect,
        isVisible: Bool,
        isAlwaysOnTop: Bool,
        mode: HUDMode = .standard,
        screenIdentifier: String?
    ) {
        self.frame = frame
        self.isVisible = isVisible
        self.isAlwaysOnTop = isAlwaysOnTop
        self.mode = mode
        self.screenIdentifier = screenIdentifier
    }

    private enum CodingKeys: String, CodingKey {
        case frame
        case isVisible
        case isAlwaysOnTop
        case mode
        case screenIdentifier
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frame = try container.decode(CGRect.self, forKey: .frame)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        isAlwaysOnTop = try container.decode(Bool.self, forKey: .isAlwaysOnTop)
        mode = try container.decodeIfPresent(HUDMode.self, forKey: .mode) ?? .standard
        screenIdentifier = try container.decodeIfPresent(String.self, forKey: .screenIdentifier)
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
