import ServiceManagement
import XCTest
@testable import gtopCore

final class LaunchAtLoginControllerTests: XCTestCase {
    func testMenuTitleForDisabledState() {
        let controller = LaunchAtLoginController(
            service: MockLaunchAtLoginService(status: .notRegistered)
        )

        XCTAssertEqual(controller.menuState.menuTitle, "Enable Launch at Login")
    }

    func testMenuTitleForEnabledState() {
        let controller = LaunchAtLoginController(
            service: MockLaunchAtLoginService(status: .enabled)
        )

        XCTAssertEqual(controller.menuState.menuTitle, "Disable Launch at Login")
    }

    func testToggleRegistersWhenDisabled() throws {
        let service = MockLaunchAtLoginService(status: .notRegistered)
        let controller = LaunchAtLoginController(service: service)

        try controller.toggle()

        XCTAssertEqual(service.registerCallCount, 1)
        XCTAssertEqual(service.unregisterCallCount, 0)
    }

    func testToggleUnregistersWhenEnabled() throws {
        let service = MockLaunchAtLoginService(status: .enabled)
        let controller = LaunchAtLoginController(service: service)

        try controller.toggle()

        XCTAssertEqual(service.registerCallCount, 0)
        XCTAssertEqual(service.unregisterCallCount, 1)
    }

    func testToggleOpensSystemSettingsWhenApprovalIsRequired() throws {
        let service = MockLaunchAtLoginService(status: .requiresApproval)
        let controller = LaunchAtLoginController(service: service)

        try controller.toggle()

        XCTAssertEqual(service.openSettingsCallCount, 1)
    }
}

private final class MockLaunchAtLoginService: LaunchAtLoginServicing {
    var status: SMAppService.Status
    var registerCallCount = 0
    var unregisterCallCount = 0
    var openSettingsCallCount = 0

    init(status: SMAppService.Status) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        status = .notRegistered
    }

    func openSystemSettingsLoginItems() {
        openSettingsCallCount += 1
    }
}
