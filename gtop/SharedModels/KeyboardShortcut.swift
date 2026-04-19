import Carbon
import Foundation

public struct ShortcutModifiers: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let command = ShortcutModifiers(rawValue: 1 << 0)
    public static let option = ShortcutModifiers(rawValue: 1 << 1)
    public static let shift = ShortcutModifiers(rawValue: 1 << 2)
    public static let control = ShortcutModifiers(rawValue: 1 << 3)

    public var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        return flags
    }

    public var symbols: String {
        displaySegments.joined()
    }

    public var displaySegments: [String] {
        var output: [String] = []
        if contains(.command) { output.append("⌘") }
        if contains(.option) { output.append("⌥") }
        if contains(.shift) { output.append("⇧") }
        if contains(.control) { output.append("⌃") }
        return output
    }
}

public struct KeyboardShortcut: Codable, Equatable, Hashable, Sendable {
    public var keyCode: UInt32
    public var keyDisplay: String
    public var modifiers: ShortcutModifiers

    public init(keyCode: UInt32, keyDisplay: String, modifiers: ShortcutModifiers) {
        self.keyCode = keyCode
        self.keyDisplay = keyDisplay.uppercased()
        self.modifiers = modifiers
    }

    public var displayString: String {
        "\(modifiers.symbols)\(resolvedKeyDisplay)"
    }

    public var displaySegments: [String] {
        modifiers.displaySegments + [resolvedKeyDisplay]
    }

    public var resolvedKeyDisplay: String {
        if let special = Self.specialDisplay(for: keyCode) {
            return special
        }

        let trimmed = keyDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "?" {
            return "Key \(keyCode)"
        }

        return trimmed
    }

    public static func specialDisplay(for keyCode: UInt32) -> String? {
        specialDisplayMap[Int(keyCode)]
    }

    private static let specialDisplayMap: [Int: String] = [
        kVK_Space: "Space",
        kVK_Return: "Return",
        kVK_Escape: "Esc",
        kVK_Delete: "Delete",
        kVK_ForwardDelete: "FnDelete",
        kVK_Tab: "Tab",
        kVK_CapsLock: "Caps",
        kVK_Home: "Home",
        kVK_End: "End",
        kVK_PageUp: "PageUp",
        kVK_PageDown: "PageDown",
        kVK_Help: "Help",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_F1: "F1",
        kVK_F2: "F2",
        kVK_F3: "F3",
        kVK_F4: "F4",
        kVK_F5: "F5",
        kVK_F6: "F6",
        kVK_F7: "F7",
        kVK_F8: "F8",
        kVK_F9: "F9",
        kVK_F10: "F10",
        kVK_F11: "F11",
        kVK_F12: "F12",
        kVK_F13: "F13",
        kVK_F14: "F14",
        kVK_F15: "F15",
        kVK_F16: "F16",
        kVK_F17: "F17",
        kVK_F18: "F18",
        kVK_F19: "F19",
        kVK_F20: "F20",
        kVK_ANSI_Keypad0: "Num0",
        kVK_ANSI_Keypad1: "Num1",
        kVK_ANSI_Keypad2: "Num2",
        kVK_ANSI_Keypad3: "Num3",
        kVK_ANSI_Keypad4: "Num4",
        kVK_ANSI_Keypad5: "Num5",
        kVK_ANSI_Keypad6: "Num6",
        kVK_ANSI_Keypad7: "Num7",
        kVK_ANSI_Keypad8: "Num8",
        kVK_ANSI_Keypad9: "Num9",
        kVK_ANSI_KeypadDecimal: "Num.",
        kVK_ANSI_KeypadMultiply: "Num*",
        kVK_ANSI_KeypadPlus: "Num+",
        kVK_ANSI_KeypadClear: "NumClear",
        kVK_ANSI_KeypadDivide: "Num/",
        kVK_ANSI_KeypadEnter: "NumEnter",
        kVK_ANSI_KeypadMinus: "Num-",
        kVK_ANSI_KeypadEquals: "Num="
    ]
}

public enum ShortcutConflictResult: Equatable, Sendable {
    case valid
    case missingModifier
    case reservedBySystem
}

public enum ShortcutConflictValidator {
    private static let reserved: Set<KeyboardShortcut> = [
        KeyboardShortcut(keyCode: UInt32(kVK_ANSI_Q), keyDisplay: "Q", modifiers: [.command]),
        KeyboardShortcut(keyCode: UInt32(kVK_ANSI_W), keyDisplay: "W", modifiers: [.command]),
        KeyboardShortcut(keyCode: UInt32(kVK_ANSI_H), keyDisplay: "H", modifiers: [.command]),
        KeyboardShortcut(keyCode: UInt32(kVK_ANSI_M), keyDisplay: "M", modifiers: [.command]),
        KeyboardShortcut(keyCode: UInt32(kVK_Space), keyDisplay: "Space", modifiers: [.command]),
        KeyboardShortcut(keyCode: UInt32(kVK_Tab), keyDisplay: "Tab", modifiers: [.command]),
        KeyboardShortcut(keyCode: UInt32(kVK_ANSI_Comma), keyDisplay: ",", modifiers: [.command])
    ]

    public static func validateLocal(_ shortcut: KeyboardShortcut) -> ShortcutConflictResult {
        if shortcut.modifiers.isEmpty {
            return .missingModifier
        }

        if reserved.contains(shortcut) {
            return .reservedBySystem
        }

        return .valid
    }
}
