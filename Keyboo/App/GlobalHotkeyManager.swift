import AppKit
import Carbon
import Foundation

@MainActor
final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private enum Action: Int {
        case toggleEnabled = 1
        case nextProfile = 2
    }

    private struct Registration {
        let hotKeyRef: EventHotKeyRef?
        let id: EventHotKeyID
    }

    private var eventHandlerRef: EventHandlerRef?
    private var registrations: [Registration] = []
    private var isRegistered = false

    private init() {}

    func register() {
        guard !isRegistered else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        registerHotKey(.toggleEnabled, keyCode: UInt32(kVK_ANSI_E))
        registerHotKey(.nextProfile, keyCode: UInt32(kVK_RightArrow))

        isRegistered = true
    }

    func unregister() {
        guard isRegistered else { return }
        registrations.forEach { registration in
            if let hotKeyRef = registration.hotKeyRef {
                UnregisterEventHotKey(hotKeyRef)
            }
        }
        registrations.removeAll()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        isRegistered = false
    }

    private func registerHotKey(_ action: Action, keyCode: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: fourCharCode(from: "KBOO"), id: UInt32(action.rawValue))
        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        registrations.append(Registration(hotKeyRef: hotKeyRef, id: hotKeyID))
    }

    fileprivate func handleHotKey(id: UInt32) {
        guard let action = Action(rawValue: Int(id)) else { return }
        let settings = AppSettings.shared
        switch action {
        case .toggleEnabled:
            settings.isEnabled.toggle()
        case .nextProfile:
            settings.cycleToNextProfile()
        }
    }
}

private let hotKeyCallback: EventHandlerUPP = { _, eventRef, userData in
    guard
        let eventRef,
        let userData
    else {
        return noErr
    }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        eventRef,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return noErr }

    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        manager.handleHotKey(id: hotKeyID.id)
    }
    return noErr
}

private func fourCharCode(from string: String) -> OSType {
    string.utf16.reduce(0) { ($0 << 8) + OSType($1) }
}
