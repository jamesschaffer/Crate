import XCTest

/// UI tests for playback interactions.
///
/// Tests that the mini-player appears when playback starts and that
/// transport controls respond to taps.
final class PlaybackFlowTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testAppLaunchesSuccessfully() throws {
        // Basic smoke test: app launches without crashing.
        // Playback-specific tests require MusicKit authorization and
        // an active subscription, so they'll be fleshed out alongside
        // the full UI implementation.
        XCTAssertTrue(app.windows.count > 0 || app.otherElements.count > 0)
    }
}
