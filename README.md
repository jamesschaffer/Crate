# Crate

A focused album listening experience built on Apple Music. Browse by genre, pick an album, listen start to finish.

**Status: Active development** -- Core features implemented. Crate Wall landing experience, genre feeds, grid transitions, and now-playing progress bar complete. Visual design polish in progress.

---

## What is Crate?

Crate is a single-purpose native app for Apple Music that removes playlists, podcasts, and social features. It presents albums as a grid of cover art organized by a two-tier genre taxonomy (9 super-genres, ~50 subcategories). On launch, an algorithm-driven "Crate Wall" fills the screen with album art drawn from five blended signals -- listening history, recommendations, charts, new releases, and wild card picks -- controlled by a "Crate Dial" settings slider. The experience is designed to feel like browsing a record store, not using a streaming app.

Crate is a SwiftUI multiplatform app targeting **iOS** and **macOS** from a single codebase, powered by **MusicKit** for Apple Music integration. There is no server or backend -- the app is fully client-side.

For the full product specification, see the [PRD](./PRD.md).

## Documentation

| Document | Description |
|----------|-------------|
| [PRD](./PRD.md) | Product requirements, UX specification, and architecture |
| [DECISIONS.md](./DECISIONS.md) | Architectural decision records (22 ADRs, ADR-100 through ADR-121) |
| [project_context.md](./project_context.md) | Quick-reference project context for new contributors |

## Tech Stack

- **Platform:** SwiftUI Multiplatform (iOS + macOS)
- **Architecture:** MVVM with `@Observable` (iOS 17+ / macOS 14+)
- **Music Integration:** MusicKit (Apple Music)
- **Playback:** `ApplicationMusicPlayer`
- **Local Persistence:** SwiftData (favorites, dislikes)
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

### Entitlements Required

| Entitlement | Platform | Purpose |
|-------------|----------|---------|
| MusicKit | iOS + macOS | Apple Music API access and playback |
| Background Modes -> Audio | iOS only | Continued playback when app is backgrounded |

### No Environment Variables

Unlike a web app, there are no `.env` files or API keys to configure. MusicKit authentication is handled automatically via the provisioning profile and MusicKit entitlement. There is no client secret, no API key, and no server-side configuration.

## Key Constraints

- **Physical device required.** MusicKit does not work in the Simulator. All testing involving Apple Music playback or subscription checks must run on a physical device.
- **Bundle version build settings required.** `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` must be set in all build configurations. Without them, MusicKit silently rejects all personalized API calls (`/v1/me/*`).
- **Apple Music subscription required.** The app requires an active Apple Music subscription for playback. Non-subscribers can browse but cannot play.
- **Apple ecosystem only.** iOS 17+ and macOS 14+ (Sonoma). No Android, no web.
- **No server.** The app is fully client-side. MusicKit handles auth, API access, and playback on-device.

## Project Structure

```
Crate/
  Crate.xcodeproj
  Crate/                        # Shared code (iOS + macOS)
    CrateApp.swift              # App entry point
    ContentView.swift           # Root view (auth gate) + PlaybackFooterOverlay
    /Models                     # CrateAlbum, Genre, GenreTaxonomy, FavoriteAlbum, DislikedAlbum,
                                # CrateDial, GenreFeedSignal, GenreFeedWeights
    /ViewModels                 # Browse, AlbumDetail, Playback, Auth, CrateWall,
                                # GridTransitionCoordinator
    /Views
      /Browse                   # BrowseView, AlbumGridView, AlbumGridItemView,
                                # WallGridItemView, AnimatedGridItemView, GenreBarView
      /AlbumDetail              # AlbumDetailView, TrackListView
      /Auth                     # AuthView
      /Playback                 # PlaybackFooterView, PlaybackRowContent,
                                # PlaybackProgressBar
      /Settings                 # SettingsView (Crate Dial control), FeedDiagnosticsView
      /Shared                   # AlbumArtworkView, LoadingView, EmptyStateView
    /Services                   # MusicService, FavoritesService, DislikeService,
                                # CrateWallService, GenreFeedService, WeightedInterleave,
                                # ArtworkColorExtractor
    /Config                     # Genres.swift (static taxonomy), CrateDialStore.swift,
                                # GridTransitionConstants.swift
    /Resources                  # Assets.xcassets
  Crate-iOS/                    # iOS entitlements, Info.plist
  Crate-macOS/                  # macOS entitlements, Info.plist, MacCommands.swift
  CrateTests/                   # Unit tests (Swift Testing): MusicServiceTests,
                                # BrowseViewModelTests, GenreTaxonomyTests,
                                # FavoritesServiceTests, DislikeServiceTests,
                                # FeedbackLoopTests
  CrateUITests/                 # UI tests (XCTest)
```

## License

Private project. Not open source.
