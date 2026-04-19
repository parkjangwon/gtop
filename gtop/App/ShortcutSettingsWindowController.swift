import AppKit
import Carbon
import SwiftUI
import gtopCore

typealias AppKeyboardShortcut = gtopCore.KeyboardShortcut

@MainActor
final class ShortcutSettingsWindowController: NSWindowController {
    init(viewModel: ShortcutSettingsViewModel) {
        let rootView = ShortcutSettingsView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "HUD Shortcut"
        window.isReleasedWhenClosed = false
        window.contentView = hosting

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func present() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
final class ShortcutSettingsViewModel: ObservableObject {
    @Published var currentShortcut: AppKeyboardShortcut?
    @Published var isRecording = false
    @Published var validationMessage: String?

    private let preferencesStore: ShortcutPreferencesStore
    private let hotKeyManager: GlobalHotKeyManager

    init(preferencesStore: ShortcutPreferencesStore, hotKeyManager: GlobalHotKeyManager) {
        self.preferencesStore = preferencesStore
        self.hotKeyManager = hotKeyManager
        currentShortcut = preferencesStore.load()
    }

    func beginRecording() {
        validationMessage = nil
        isRecording = true
    }

    func cancelRecording() {
        isRecording = false
    }

    func clearShortcut() {
        validationMessage = nil
        isRecording = false
        preferencesStore.save(nil)
        hotKeyManager.unregister()
        currentShortcut = nil
    }

    func handle(event: NSEvent) {
        guard isRecording else { return }

        if event.keyCode == UInt16(kVK_Escape) {
            cancelRecording()
            return
        }

        guard let shortcut = KeyboardShortcutFactory.from(event: event) else {
            validationMessage = "Press a modifier key together with a regular key."
            return
        }

        if let error = hotKeyManager.validate(shortcut: shortcut, allowing: currentShortcut) {
            validationMessage = error.localizedDescription
            isRecording = false
            return
        }

        do {
            try hotKeyManager.register(shortcut: shortcut)
            preferencesStore.save(shortcut)
            currentShortcut = shortcut
            validationMessage = nil
        } catch {
            validationMessage = error.localizedDescription
        }

        isRecording = false
    }
}

private enum KeyboardShortcutFactory {
    static func from(event: NSEvent) -> AppKeyboardShortcut? {
        let relevantFlags = event.modifierFlags.intersection([.command, .option, .shift, .control])
        let modifiers = ShortcutModifiers(modifierFlags: relevantFlags)
        guard !modifiers.isEmpty, !isModifierOnlyKey(event.keyCode) else {
            return nil
        }

        return AppKeyboardShortcut(
            keyCode: UInt32(event.keyCode),
            keyDisplay: displayString(for: event),
            modifiers: modifiers
        )
    }

    private static func isModifierOnlyKey(_ keyCode: UInt16) -> Bool {
        let modifierKeyCodes: [UInt16] = [
            UInt16(kVK_Command),
            UInt16(kVK_RightCommand),
            UInt16(kVK_Shift),
            UInt16(kVK_RightShift),
            UInt16(kVK_Option),
            UInt16(kVK_RightOption),
            UInt16(kVK_Control),
            UInt16(kVK_RightControl),
            UInt16(kVK_CapsLock)
        ]
        return modifierKeyCodes.contains(keyCode)
    }

    private static func displayString(for event: NSEvent) -> String {
        if let special = AppKeyboardShortcut.specialDisplay(for: UInt32(event.keyCode)) {
            return special
        }

        return (event.charactersIgnoringModifiers ?? "").uppercased()
    }
}

private struct ShortcutCaptureView: NSViewRepresentable {
    let onEvent: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onEvent = onEvent
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onEvent = onEvent
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class KeyCaptureView: NSView {
    var onEvent: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        onEvent?(event)
    }
}

private struct ShortcutSettingsView: View {
    @ObservedObject var viewModel: ShortcutSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HUD Global Shortcut")
                .font(.system(size: 16, weight: .semibold))

            Text("Current Shortcut")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Group {
                if let shortcut = viewModel.currentShortcut {
                    ShortcutPreview(shortcut: shortcut)
                } else {
                    Text("Not Set")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }
            }

            HStack(spacing: 10) {
                Button(viewModel.isRecording ? "Recording…" : "Record Shortcut") {
                    viewModel.beginRecording()
                }
                .keyboardShortcut(.defaultAction)

                Button("Clear") {
                    viewModel.clearShortcut()
                }
                .disabled(viewModel.currentShortcut == nil)
            }

            Text(
                viewModel.validationMessage
                    ?? "Press a modifier key with a regular key. Conflicting macOS shortcuts cannot be saved."
            )
                .font(.system(size: 11))
                .foregroundStyle(
                    viewModel.validationMessage == nil
                        ? AnyShapeStyle(.secondary)
                        : AnyShapeStyle(Color.red)
                )
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(18)
        .frame(width: 360, height: 240)
        .background {
            if viewModel.isRecording {
                ShortcutCaptureView { event in
                    viewModel.handle(event: event)
                }
            }
        }
    }
}

private extension ShortcutModifiers {
    init(modifierFlags: NSEvent.ModifierFlags) {
        var modifiers: ShortcutModifiers = []
        if modifierFlags.contains(.command) { modifiers.insert(.command) }
        if modifierFlags.contains(.option) { modifiers.insert(.option) }
        if modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if modifierFlags.contains(.control) { modifiers.insert(.control) }
        self = modifiers
    }
}

private struct ShortcutPreview: View {
    let shortcut: AppKeyboardShortcut

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(shortcut.displaySegments.enumerated()), id: \.offset) { _, segment in
                ShortcutKeycap(label: segment)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }
}

private struct ShortcutKeycap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.95))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }

    private var horizontalPadding: CGFloat {
        label.count > 2 ? 12 : 10
    }
}
