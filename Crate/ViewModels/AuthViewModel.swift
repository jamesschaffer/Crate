import Foundation
import MusicKit
import Observation

/// Manages MusicKit authorization state and Apple Music subscription status.
///
/// This is injected into the environment at the app level so any view
/// can check whether the user has granted music access.
@Observable
final class AuthViewModel {

    // MARK: - Published State

    /// Current MusicKit authorization status.
    var authorizationStatus: MusicAuthorization.Status = .notDetermined

    /// Whether the user has an active Apple Music subscription.
    var hasSubscription: Bool = false

    /// True while we're actively checking authorization or subscription.
    var isLoading: Bool = false

    /// Human-readable error message if something goes wrong.
    var errorMessage: String?

    // MARK: - Computed

    /// Convenience: true when authorized AND subscribed.
    var isAuthorizedAndSubscribed: Bool {
        authorizationStatus == .authorized && hasSubscription
    }

    // MARK: - Actions

    /// Check the current authorization status without prompting.
    func checkCurrentStatus() {
        authorizationStatus = MusicAuthorization.currentStatus
    }

    /// Request MusicKit authorization from the user (shows system prompt).
    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil

        let status = await MusicAuthorization.request()
        authorizationStatus = status

        if status == .authorized {
            await checkSubscription()
        } else {
            isLoading = false
        }
    }

    /// Check whether the user has an active Apple Music subscription.
    func checkSubscription() async {
        do {
            // MusicSubscription requires iOS 15.4+ / macOS 12.3+
            let subscription = try await MusicSubscription.current
            hasSubscription = subscription.canPlayCatalogContent
        } catch {
            errorMessage = "Could not verify Apple Music subscription: \(error.localizedDescription)"
            hasSubscription = false
        }
        isLoading = false
    }
}
