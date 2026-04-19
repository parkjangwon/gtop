import Foundation
import ServiceManagement

public enum LaunchAtLoginMenuState: Equatable {
    case enabled
    case disabled
    case requiresApproval

    public var menuTitle: String {
        switch self {
        case .enabled:
            return "Disable Launch at Login"
        case .disabled:
            return "Enable Launch at Login"
        case .requiresApproval:
            return "Open Login Items Settings…"
        }
    }
}

protocol LaunchAtLoginServicing: AnyObject {
    var status: SMAppService.Status { get }

    func register() throws
    func unregister() throws
    func openSystemSettingsLoginItems()
}

final class MainAppLaunchAtLoginService: LaunchAtLoginServicing {
    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }

    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

public final class LaunchAtLoginController {
    private let service: LaunchAtLoginServicing

    public convenience init() {
        self.init(service: MainAppLaunchAtLoginService())
    }

    init(service: LaunchAtLoginServicing) {
        self.service = service
    }

    public var menuState: LaunchAtLoginMenuState {
        Self.menuState(for: service.status)
    }

    @discardableResult
    public func toggle() throws -> LaunchAtLoginMenuState {
        switch menuState {
        case .enabled:
            try service.unregister()
        case .disabled:
            try service.register()
        case .requiresApproval:
            service.openSystemSettingsLoginItems()
        }

        return menuState
    }

    static func menuState(for status: SMAppService.Status) -> LaunchAtLoginMenuState {
        switch status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notRegistered, .notFound:
            return .disabled
        @unknown default:
            return .disabled
        }
    }
}
