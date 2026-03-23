import XCTest

final class MobileClawUITests: XCTestCase {
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // Verify the app launches without crashing
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
