import Carbon
import XCTest
@testable import gtopCore

final class KeyboardShortcutTests: XCTestCase {
    func testDisplayStringUsesModifierSymbolsAndKeyDisplay() {
        let shortcut = KeyboardShortcut(
            keyCode: 5,
            keyDisplay: "G",
            modifiers: [.command, .shift]
        )

        XCTAssertEqual(shortcut.displayString, "⌘⇧G")
    }

    func testDisplayStringUsesFunctionKeyNameForSpecialKeycodes() {
        let shortcut = KeyboardShortcut(
            keyCode: UInt32(kVK_F16),
            keyDisplay: "?",
            modifiers: [.command]
        )

        XCTAssertEqual(shortcut.displayString, "⌘F16")
    }

    func testDisplaySegmentsKeepSpecialKeysReadable() {
        let shortcut = KeyboardShortcut(
            keyCode: UInt32(kVK_ANSI_KeypadEnter),
            keyDisplay: "",
            modifiers: [.command, .shift]
        )

        XCTAssertEqual(shortcut.displaySegments, ["⌘", "⇧", "NumEnter"])
    }

    func testValidatorRejectsReservedShortcut() {
        let shortcut = KeyboardShortcut(
            keyCode: 12,
            keyDisplay: "Q",
            modifiers: [.command]
        )

        let result = ShortcutConflictValidator.validateLocal(shortcut)

        XCTAssertEqual(result, .reservedBySystem)
    }

    func testValidatorRequiresModifier() {
        let shortcut = KeyboardShortcut(
            keyCode: 5,
            keyDisplay: "G",
            modifiers: []
        )

        let result = ShortcutConflictValidator.validateLocal(shortcut)

        XCTAssertEqual(result, .missingModifier)
    }

    func testHudDismissalPolicyDismissesVisibleUtilityHudOnOutsideClick() {
        let shouldDismiss = HUDDismissalPolicy.shouldDismissOnOutsideClick(
            hudState: HUDState(isVisible: true, isAlwaysOnTop: false),
            hitOwnedWindow: false
        )

        XCTAssertTrue(shouldDismiss)
    }

    func testHudDismissalPolicyKeepsForegroundHudVisible() {
        let shouldDismiss = HUDDismissalPolicy.shouldDismissOnOutsideClick(
            hudState: HUDState(isVisible: true, isAlwaysOnTop: true),
            hitOwnedWindow: false
        )

        XCTAssertFalse(shouldDismiss)
    }
}
