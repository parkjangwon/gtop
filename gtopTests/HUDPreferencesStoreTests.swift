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
            screenIdentifier: "42"
        )

        store.save(expected)
        let restored = store.load()

        XCTAssertEqual(restored, expected)
    }
}
