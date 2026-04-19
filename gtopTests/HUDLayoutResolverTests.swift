import CoreGraphics
import XCTest
@testable import gtopCore

final class HUDLayoutResolverTests: XCTestCase {
    func testDefaultFramePlacesHudAtTopRightWithMargin() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let size = CGSize(width: 320, height: 420)

        let frame = HUDLayoutResolver.defaultFrame(in: screenFrame, size: size, margin: 24)

        XCTAssertEqual(frame.origin.x, 1384, accuracy: 0.1)
        XCTAssertEqual(frame.origin.y, 673, accuracy: 0.1)
        XCTAssertEqual(frame.size.width, 320, accuracy: 0.1)
        XCTAssertEqual(frame.size.height, 420, accuracy: 0.1)
    }

    func testResolvedFrameFallsBackWhenSavedFrameIsOffScreen() {
        let screens = [
            CGRect(x: 0, y: 0, width: 1512, height: 982),
            CGRect(x: 1512, y: 0, width: 1512, height: 982)
        ]
        let savedFrame = CGRect(x: 4000, y: 500, width: 320, height: 420)

        let resolved = HUDLayoutResolver.resolve(
            savedFrame: savedFrame,
            screens: screens,
            fallbackScreen: screens[1],
            size: CGSize(width: 320, height: 420)
        )

        XCTAssertTrue(screens[1].intersects(resolved))
    }
}
