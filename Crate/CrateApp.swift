import SwiftUI
import SwiftData
import MusicKit

/// Main entry point for the Crate app.
///
/// Sets up the SwiftData model container for favorites persistence
/// and injects shared view models into the environment. Shows the
/// authorization flow if the user hasn't granted MusicKit access,
/// or the main content if they have.
@main
struct CrateApp: App {

    // MARK: - Shared State

    @State private var authViewModel = AuthViewModel()
    @State private var playbackViewModel = PlaybackViewModel()

    // MARK: - SwiftData

    private var modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([FavoriteAlbum.self])
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
        Settings {
            SettingsView()
                .frame(minWidth: 400, minHeight: 300)
        }
        #endif
    }
}
