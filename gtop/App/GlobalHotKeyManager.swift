import AppKit
import Carbon
import Foundation
import gtopCore

private let gtopHotKeySignature: OSType = 0x47544F50

private let gtopHotKeyHandler: EventHandlerUPP = { _, event, userData in
    guard
        let event,
        let userData
    else { return noErr }

    let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr else { return status }
    if hotKeyID.signature == gtopHotKeySignature && hotKeyID.id == 1 {
        manager.onTriggered()
    }

    return noErr
}

enum GlobalHotKeyRegistrationError: LocalizedError {
    case missingModifier
    case reservedBySystem
    case alreadyInUse
    case registerFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .missingModifier:
            return "A shortcut must include at least one modifier key."
        case .reservedBySystem:
            return "This shortcut conflicts with a built-in macOS shortcut."
        case .alreadyInUse:
            return "That global shortcut is already in use."
        case let .registerFailed(status):
            return "Failed to register the shortcut. (OSStatus: \(status))"
        }
    }
}

final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private(set) var registeredShortcut: KeyboardShortcut?
    fileprivate let onTriggered: () -> Void

    init(onTriggered: @escaping () -> Void) {
        self.onTriggered = onTriggered
        installHandler()
    }

    deinit {
        unregister()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }

    func validate(shortcut: KeyboardShortcut, allowing current: KeyboardShortcut?) -> GlobalHotKeyRegistrationError? {
        switch ShortcutConflictValidator.validateLocal(shortcut) {
        case .valid:
            break
        case .missingModifier:
            return .missingModifier
        case .reservedBySystem:
            return .reservedBySystem
        }

        if current == shortcut {
            return nil
        }

        var trialRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: gtopHotKeySignature, id: 999)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers.carbonFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            OptionBits(kEventHotKeyExclusive),
            &trialRef
        )

        if let trialRef {
            UnregisterEventHotKey(trialRef)
        }

        if status == noErr {
            return nil
        }

        if status == eventHotKeyExistsErr {
            return .alreadyInUse
        }

        return .registerFailed(status)
    }

    func register(shortcut: KeyboardShortcut?) throws {
        unregister()

        guard let shortcut else {
            registeredShortcut = nil
            return
        }

        let hotKeyID = EventHotKeyID(signature: gtopHotKeySignature, id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers.carbonFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            OptionBits(kEventHotKeyExclusive),
            &ref
        )

        guard status == noErr, let ref else {
            throw GlobalHotKeyRegistrationError.registerFailed(status)
        }

        hotKeyRef = ref
        registeredShortcut = shortcut
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        registeredShortcut = nil
    }

    private func installHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            gtopHotKeyHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &handlerRef
        )
    }
}
