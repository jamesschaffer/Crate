import Testing
@testable import Crate_iOS

/// Tests for the MusicService layer.
///
/// NOTE: These tests require a mock MusicServiceProtocol implementation
/// since real MusicKit calls need device authorization and a subscription.
/// The mock will be built out as part of the testing infrastructure.
struct MusicServiceTests {

    @Test("MusicService protocol has required methods")
    func protocolConformance() {
        // Verify that MusicService conforms to MusicServiceProtocol.
        let service: any MusicServiceProtocol = MusicService()
        #expect(service is MusicService)
    }
}
