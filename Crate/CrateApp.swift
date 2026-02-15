import SwiftUI
import SwiftData
import MusicKit
import FirebaseCore
import FirebaseAppCheck

/// App Check provider factory — uses debug tokens in development,
/// App Attest in production on iOS, and debug tokens on macOS.
private class CrateAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        #if DEBUG
        let provider = AppCheckDebugProvider(app: app)
        if let token = provider?.localDebugToken() {
            print("[Crate] App Check debug token: \(token)")
        }
        return provider
        #else
        #if os(iOS)
        return AppAttestProvider(app: app)
        #else
        // macOS: App Attest unavailable — use debug provider with registered token.
        // Token is NOT logged in release builds to avoid leaking it via Console.app.
        return AppCheckDebugProvider(app: app)
        #endif
        #endif
    }
}

/// Main entry point for the Crate app.
///
/// Sets up Firebase, App Check, and the SwiftData model container for
/// persistence. Shows the authorization flow if the user hasn't granted
/// MusicKit access, or the main content if they have.
@main
struct CrateApp: App {

    // MARK: - Shared State

    @State private var authViewModel = AuthViewModel()
    @State private var playbackViewModel = PlaybackViewModel()

    // MARK: - SwiftData

    private var modelContainer: ModelContainer

    init() {
        // Configure App Check BEFORE Firebase.configure()
        AppCheck.setAppCheckProviderFactory(CrateAppCheckProviderFactory())
        FirebaseApp.configure()

        do {
            let schema = Schema([FavoriteAlbum.self, DislikedAlbum.self, AlbumReview.self])
            let configuration = ModelConfiguration(
                "CrateFavorites",
                schema: schema
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // If SwiftData fails to initialize, crash early with a clear message.
            // This should never happen in production — if it does, something is
            // fundamentally wrong with the data model or device storage.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.authorizationStatus == .authorized {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .tint(.brandPink)
            .environment(authViewModel)
            .environment(playbackViewModel)
            .task {
                authViewModel.checkCurrentStatus()
                if authViewModel.authorizationStatus == .authorized {
                    await authViewModel.checkSubscription()
                }
            }
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .defaultSize(width: 800, height: 800)
        .commands { PlaybackCommands(playbackViewModel: playbackViewModel) }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .frame(minWidth: 400, minHeight: 300)
                .environment(playbackViewModel)
        }
        .modelContainer(modelContainer)
        #endif
    }
}
