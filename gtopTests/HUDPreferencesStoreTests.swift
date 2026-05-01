import CoreGraphics
import XCTest
@testable import gtopCore

final class HUDPreferencesStoreTests: XCTestCase {
    func testRoundTripsStoredPreferences() {
        let defaults = UserDefaults(suiteName: "HUDPreferencesStoreTests.\(UUID().uuidString)")!
        let store = HUDPreferencesStore(userDefaults: defaults)
        let expected = HUDPreferences(
            frame: CGRect(x: 120, y: 340, width: 320, height: 420),
            isVisible: true,
            isAlwaysOnTop: true,
            mode: .mini,
            screenIdentifier: "42"
        )

        store.save(expected)
        let restored = store.load()

        XCTAssertEqual(restored, expected)
    }

    func testLoadsLegacyPreferencesAsStandardMode() throws {
        let defaults = UserDefaults(suiteName: "HUDPreferencesStoreTests.\(UUID().uuidString)")!
        let store = HUDPreferencesStore(userDefaults: defaults)
        let legacyPreferences = """
        {
          "frame" : [[120, 340], [320, 420]],
          "isVisible" : true,
          "isAlwaysOnTop" : false,
          "screenIdentifier" : "42"
        }
        """
        defaults.set(Data(legacyPreferences.utf8), forKey: "gtop.hud.preferences")

        let restored = try XCTUnwrap(store.load())

        XCTAssertEqual(restored.mode, .standard)
    }
}
