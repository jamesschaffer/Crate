# AlbumCrate

A focused album listening experience built on Apple Music. Browse by genre, pick an album, listen start to finish.

**Status: Active development** -- Core features implemented. Crate Wall landing experience, genre feeds, grid transitions, now-playing progress bar, playback scrubber, launch animation, brand identity, artist catalog browsing, auto-advance album playback, and AI album reviews complete. Both iOS and macOS targets are buildable and testable. Visual design polish in progress.

---

## What is AlbumCrate?

AlbumCrate is a single-purpose native app for Apple Music that removes playlists, podcasts, and social features. It presents albums as a grid of cover art organized by a two-tier genre taxonomy (9 super-genres, ~50 subcategories). On launch, an algorithm-driven "Crate Wall" fills the screen with album art, then a control bar slides up from the bottom with a spring animation once content is ready. The wall draws from five blended signals -- listening history, recommendations, charts, new releases, and wild card picks -- controlled by a "Crate Dial" radio selector in settings. When you play an album from any grid, playback automatically continues through the remaining albums -- no need to manually pick the next record. The experience is designed to feel like browsing a record store, not using a streaming app.

AlbumCrate is a SwiftUI multiplatform app targeting **iOS** and **macOS** from a single codebase, powered by **MusicKit** for Apple Music integration. The app is primarily client-side, with one server dependency: AI album reviews are generated via a Firebase Cloud Function. The codebase still uses "Crate" internally for the project name, targets, and module names.

For the full product specification, see the [PRD](./PRD.md).

## Documentation

| Document | Description |
|----------|-------------|
| [PRD](./PRD.md) | Product requirements, UX specification, and architecture |
| [DECISIONS.md](./DECISIONS.md) | Architectural decision records (32 ADRs, ADR-100 through ADR-131) |
| [project_context.md](./project_context.md) | Quick-reference project context for new contributors |

## Tech Stack

- **Platform:** SwiftUI Multiplatform (iOS + macOS)
- **Architecture:** MVVM with `@Observable` (iOS 17+ / macOS 14+)
- **Music Integration:** MusicKit (Apple Music)
- **Playback:** `ApplicationMusicPlayer`
- **AI Reviews:** Firebase Cloud Functions (Gemini) + App Check
- **Local Persistence:** SwiftData (favorites, dislikes, reviews)
- **Testing:** XCTest (UI tests) + Swift Testing (unit tests)
- **Deployment:** App Store + Mac App Store, TestFlight for beta
- **CI/CD:** Xcode Cloud

## Prerequisites

- **macOS** with **Xcode 16+** (required for Swift Testing, latest MusicKit, and SwiftUI features)
- **Apple Developer Program membership** (required for MusicKit entitlement, TestFlight, and App Store distribution)
- **Apple Music subscription** (required for playback and subscription-dependent features during development)
- **Physical iOS device** (iPhone or iPad) for testing -- MusicKit does not work in the iOS Simulator
- **Physical Mac** for macOS target testing

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd Crate
   ```

2. **Open the Xcode project**
   ```bash
   open Crate.xcodeproj
   ```

3. **Configure signing**
   - Select the `Crate` target in Xcode
   - Under Signing & Capabilities, select your Apple Developer team
   - Ensure the MusicKit capability is enabled

4. **Run on a physical device**
   - Select your connected iPhone or Mac as the build destination
   - Build and run (Cmd+R)
   - On first launch, the app will request Apple Music authorization
   - After authorization, the Crate Wall loads as the default landing screen
   - On macOS, standard keyboard shortcuts are available: Space (play/pause), Cmd+Right Arrow (next track), Cmd+Left Arrow (previous track), Cmd+. (stop)

### Entitlements Required

| Entitlement | Platform | Purpose |
|-------------|----------|---------|
| MusicKit | iOS + macOS | Apple Music API access and playback |
| Background Modes -> Audio | iOS only | Continued playback when app is backgrounded |

### Configuration

- **MusicKit:** No API keys or environment variables needed. Authentication is handled automatically via the provisioning profile and MusicKit entitlement.
- **Firebase (AI Reviews):** `GoogleService-Info.plist` is included in the repository and configures the Firebase project connection. No additional setup is required for the Cloud Function. In DEBUG builds and on macOS, an App Check debug token is printed to the Xcode console -- this token must be registered in the [Firebase Console](https://console.firebase.google.com/) under App Check > Debug Tokens for the function calls to succeed during development.

## Key Constraints

- **Physical device required.** MusicKit does not work in the Simulator. All testing involving Apple Music playback or subscription checks must run on a physical device.
- **Bundle version build settings required.** `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` must be set in all build configurations. Without them, MusicKit silently rejects all personalized API calls (`/v1/me/*`).
- **Apple Music subscription required.** The app requires an active Apple Music subscription for playback. Non-subscribers can browse but cannot play.
- **Apple ecosystem only.** iOS 17+ and macOS 14+ (Sonoma). No Android, no web.
- **Mostly client-side.** MusicKit handles auth, API access, and playback on-device. The one exception is AI album reviews, which call a Firebase Cloud Function (Gemini). If the function is unavailable, reviews fail gracefully; all other features work offline.

## Project Structure

```
Crate/
  Crate.xcodeproj
  GoogleService-Info.plist      # Firebase configuration (AI reviews)
  Crate/                        # Shared code (iOS + macOS)
    CrateApp.swift              # App entry point (Firebase + App Check init, SwiftData schema)
    ContentView.swift           # Root view (auth gate) + PlaybackFooterOverlay + ShaderWarmUpView
    /Models                     # CrateAlbum, CrateDestination, Genre, GenreTaxonomy,
                                # FavoriteAlbum, DislikedAlbum, AlbumReview, CrateDial,
                                # GenreFeedSignal, GenreFeedWeights
    /ViewModels                 # Browse, AlbumDetail, AlbumReview, ArtistCatalog,
                                # Playback, Auth, CrateWall, GridTransitionCoordinator
    /Views
      /Browse                   # BrowseView, AlbumGridView, AlbumGridItemView,
                                # WallGridItemView, AnimatedGridItemView, GenreBarView
      /AlbumDetail              # AlbumDetailView, AlbumTransportControls, TrackListView,
                                # AlbumReviewView
      /ArtistCatalog            # ArtistCatalogView (artist discography grid)
      /Auth                     # AuthView
      /Playback                 # PlaybackFooterView, PlaybackRowContent,
                                # PlaybackProgressBar, PlaybackScrubber
      /Settings                 # SettingsView (Crate Algorithm radio selector),
                                # FeedDiagnosticsView, QueueDiagnosticsView
      /Shared                   # AlbumArtworkView, LoadingView, EmptyStateView
    /Services                   # MusicService, FavoritesService, DislikeService,
                                # CrateWallService, GenreFeedService, ReviewService,
                                # WeightedInterleave, ArtworkColorExtractor,
                                # AlbumQueueManager
    /Config                     # Genres.swift (static taxonomy), CrateDialStore.swift,
                                # GridTransitionConstants.swift, AppColors.swift (brand color)
    /Resources                  # Assets.xcassets
  Crate-iOS/                    # iOS entitlements, Info.plist
  Crate-macOS/                  # macOS entitlements, Info.plist, MacCommands.swift
  CrateTests/                   # Unit tests (Swift Testing): MusicServiceTests,
                                # BrowseViewModelTests, CrateWallServiceTests,
                                # GenreTaxonomyTests, FavoritesServiceTests,
                                # DislikeServiceTests, FeedbackLoopTests,
                                # AlbumQueueManagerTests, ReviewServiceTests,
                                # MockMusicService (shared test mock)
  CrateUITests/                 # UI tests (XCTest)
```

## License

Private project. Not open source.
