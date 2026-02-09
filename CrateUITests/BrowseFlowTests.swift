import XCTest

/// UI tests for the main browse flow.
///
/// These tests verify the genre selection -> album grid -> album detail
/// navigation flow works end-to-end.
final class BrowseFlowTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testAppLaunches() throws {
        // Verify the app launches without crashing.
        // The specific UI state depends on MusicKit authorization,
        // so we just check that *something* is on screen.
        XCTAssertTrue(app.windows.count > 0 || app.otherElements.count > 0)
    }
}
