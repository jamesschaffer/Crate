# Project Context -- Crate

## Overview

Crate is a single-purpose native app built on Apple Music that strips away playlists, podcasts, algorithmic feeds, and social features to deliver a focused album listening experience. Users browse a two-tier genre taxonomy (inspired by musicmap.info), see a grid of album cover art, pick an album, and listen to it start to finish. The interface is designed to feel like thumbing through records in a store, not using a software application.

Crate is a SwiftUI multiplatform app targeting iOS and macOS, powered by MusicKit for Apple Music integration. There is no server or backend -- the app is fully client-side.

## Current Status

**Active development.** Core features, Crate Wall, personalized genre feeds, grid transition animations, and now-playing progress bar are implemented. Visual design polish is in progress.

- PRD: Complete (Draft -- Architecture Complete, MusicKit Pivot)
- Architecture decisions: 23 ADRs documented (ADR-100 through ADR-122)
- Core app: Implemented (Browse, Album Detail, Playback, Auth, Favorites, Dislikes)
- Crate Wall: Complete -- algorithm-driven landing experience with 5 blended signals, Crate Dial settings, enriched genre extraction (heavy rotation + library albums), dislike filtering, infinite scroll, graceful degradation
- Genre feeds: Complete -- multi-signal blended genre feeds (6 signals: Personal History, Recommendations, Trending, New Releases, Subcategory Rotation, Seed Expansion), CrateDial-weighted, replaces single-source chart pagination
- Grid transitions: Complete -- coordinated scatter/fade animation when switching between wall and genre or between genres. GridTransitionCoordinator state machine orchestrates exit, scroll-reset, fetch, and enter phases. Genre bar disabled during transitions. Zero overhead during idle.
- Feedback loop: Complete -- like write-back fires 3 concurrent Apple Music calls (addToLibrary + rateAlbum(.love) + favoriteAlbum via POST /v1/me/favorites), dislike writes rateAlbum(.dislike), disliked albums filtered from all feeds, mutual exclusion between like and dislike, error logging on all write-back calls
- Genre taxonomy: Complete -- 9 super-genres with ~50 subcategories, mapped to real Apple Music genre IDs
- Genre bar: Complete -- single-row transforming filter bar (genres view OR selected-genre + subcategory pills view), search-based subcategory browsing, staggered slide animation synchronized with grid transitions for genre-level switches (pills slide down on exit, up on enter), disabled during transitions. Uses vertical offset workaround for Liquid Glass compositing limitations (animated opacity and scaleEffect do not work correctly with .glassEffect())
- Settings: Complete -- Crate Dial position control (half-sheet on iOS, Settings scene on macOS), dial changes regenerate the Crate Wall live with 1s debounce (no app restart required), Feed Diagnostics debug panel (validates favorites/dislikes persistence, mutual exclusion, weight correctness)
- Album Detail: Redesigned with blurred artwork ambient background, now-playing track indicator, like/dislike buttons in side gutters flanking artwork, play button and track list tinted with artwork-derived colors, streamlined layout
- Now-playing progress bar: Complete -- scrubbable progress bar with artwork-derived gradient, visible in both the playback footer and BrowseView control bar. ArtworkColorExtractor uses pure CoreGraphics (cross-platform, no UIKit/AppKit).
- Design: Visual design in progress (album detail and playback UI polished, other views pending)

**Note on history:** Crate was originally designed as a Spotify web app (Next.js + React). On 2026-02-09, the project pivoted to Apple Music + native SwiftUI. The original Spotify-era ADRs (001-014) are archived in git history. All current documentation reflects the Apple Music / MusicKit direction.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Platform | SwiftUI Multiplatform (iOS 17+ / macOS 14+) |
| Architecture Pattern | MVVM with `@Observable` |
| Music Integration | MusicKit (Apple Music) |
| Playback | `ApplicationMusicPlayer` |
| API Access | MusicKit Swift types + `MusicDataRequest` |
| Local Persistence | SwiftData |
| Image Caching | `AsyncImage` + system URL cache |
| Validation | Swift type system (compile-time) |
| Testing | XCTest (UI tests) + Swift Testing (unit tests) |
| Deployment | App Store (iOS + macOS), TestFlight for beta |
| CI/CD | Xcode Cloud |
| Server / Backend | None |
| Database | None (SwiftData is on-device only) |

## Key Constraints

- **No Simulator support for MusicKit.** MusicKit playback and subscription checks do not work in the iOS Simulator. Integration testing and UI testing require a physical device with an active Apple Music subscription. Unit tests with mocked MusicKit can run in the Simulator.
- **MARKETING_VERSION and CURRENT_PROJECT_VERSION are required for MusicKit personalized endpoints.** If these build settings are missing from the Xcode project, MusicKit silently fails every `/v1/me/*` API call (heavy rotation, recently played, recommendations, library albums, ratings, favorites) with "Missing requesting bundle version." Both settings must be present in all build configurations (Debug + Release) for both iOS and macOS targets. All API calls now use `do/catch` with `[Crate]`-prefixed `print` logging (not silent `try?`), so failures are always visible in the Xcode console.
- **Charts endpoint popularity bias.** The Apple Music Charts API returns albums ranked by current streaming popularity, not all-time catalog depth. Deep catalog albums from older decades may not appear unless they are currently popular. This is acceptable for MVP. Subcategory browsing now uses the Apple Music Search endpoint (not charts), which provides broader catalog coverage for sub-genre exploration.
- **Apple Music genre granularity.** Apple Music has roughly 20-30 top-level genres, which is more conservative than some platforms with hundreds of micro-genres. Some sub-categories in the taxonomy may map to the same genre ID. This needs validation during taxonomy mapping.
- **Rate limits.** Apple Music API allows approximately 20 requests per second per user token. With 1 API call per page of album results, this is nearly a non-issue. Defensive debounce and 429 retry are implemented as safety measures.
- **Token management is automatic.** MusicKit handles developer tokens and user tokens at the system level. There are no tokens to store, refresh, or rotate. The ~6-month token expiry concern applies only to the REST API used from servers, not to native MusicKit apps.
- **Apple ecosystem only.** No Android, no web, no Windows. The app requires an Apple device with iOS 17+ or macOS 14+. Cross-platform would require a separate effort (MusicKit.js for web, or a full rebuild for Android).
- **No server needed.** MusicKit handles auth, API access, and playback on-device. No client secret, no OAuth flow, no API proxy. The entire app is client-side.

## Key Documents

| Document | Path | Description |
|----------|------|-------------|
| PRD | [PRD.md](./PRD.md) | Full product requirements, UX specification, and architecture |
| Decision Log | [DECISIONS.md](./DECISIONS.md) | 23 architectural decision records (ADR-100 through ADR-122) |
| README | [README.md](./README.md) | Project overview and getting started |

## Architecture Summary

The application has five view areas (Auth, Browse with Crate Wall, Album Detail, Playback Footer, Settings) and no backend. The Album Detail view uses a ZStack with blurred, scaled album artwork as an ambient background layer, a dimming overlay at 50% opacity for readability (reduced from 75% to let more artwork color bleed through), and the scrollable content on top. All Apple Music API calls are made directly from the app via MusicKit. Auth is handled by the system via a single MusicKit authorization dialog. ContentView isolates playback state observation into a child `PlaybackFooterOverlay` view so that `stateChangeCounter` updates only re-render the footer, not the entire NavigationStack.

The default landing experience is the Crate Wall -- an algorithm-driven grid of album art blending five signals (Listening History, Recommendations, Popular Charts, New Releases, Wild Card), weighted by a user-controllable "Crate Dial" slider persisted to UserDefaults. Genre extraction uses heavy rotation, library albums, and recently played for richer personalization. The wall persists within a session and regenerates on cold launch or when the user adjusts the Crate Dial (with a 1-second debounce to avoid thrashing during slider interaction).

Users can switch to genre-based browsing via the genre bar. Genre feeds use a multi-signal blending system (GenreFeedService) with 6 signals: Personal History (heavy rotation + library filtered to genre), Recommendations (filtered to genre), Trending (charts with random offset), New Releases, Subcategory Rotation (random subcategories for variety), and Seed Expansion (related albums + artist albums from user's favorited seeds). Weights follow the CrateDial system via GenreFeedWeights. Subcategory selection uses the Apple Music Search endpoint for targeted browsing. Both CrateWallService and GenreFeedService share generic utilities from `WeightedInterleave.swift`: `weightedInterleave()` for the interleave algorithm and `distributeByWeight()` for converting fractional weight tables to integer album counts using the largest-remainder method (replacing duplicated implementations in CrateDialWeights and GenreFeedWeights).

Switching between the wall and a genre (or between genres) is animated via a `GridTransitionCoordinator` -- an `@Observable` state machine with four phases: `idle` (passthrough, no overhead), `exiting` (old albums scatter out with staggered scale+fade), `waiting` (scroll resets to top, API fetch runs concurrently, spinner shown if needed), and `entering` (new albums scatter in). `BrowseView` uses a single always-mounted `AlbumGridView` inside a `ZStack` with overlay states (loading, error, empty). During idle, the grid reads albums directly from the wall or genre view model. During transitions, it reads from the coordinator's `displayAlbums`. Each grid item is wrapped in `AnimatedGridItemView`, which reads per-item scale/opacity from the coordinator via `@Environment`. The first 16 items get a staggered scatter effect with interleaved groups and random jitter; items beyond 16 get a bulk fade. All genre selection callbacks route through `coordinator.transition(from:fetch:)`. The genre bar is disabled during transitions to prevent double-tap race conditions. Rapid taps cancel the in-progress transition and start a new one. Animation tuning constants are centralized in `GridTransitionConstants.swift` (`GridTransition` enum). The genre bar pills also participate in the transition animation for genre-level switches (not subcategory toggles): pills stagger-slide downward on exit and upward on enter, synchronized with the grid scatter timing. The `animateGenreBar` flag on the coordinator distinguishes genre-level transitions (animated pills) from subcategory toggles (pills not animated). The slide animation uses vertical `offset` instead of opacity or scaleEffect because Liquid Glass compositing layers (`.glassEffect()`) do not support animated opacity and render text/capsule as separate layers that break scaleEffect. Offset is applied in dual locations -- on the label content and post-glassEffect -- to handle the layer bifurcation. `.clipped()` on the ScrollView ensures pills are hidden when offset below the bar.

A feedback loop connects Crate interactions to Apple Music: favoriting an album fires three concurrent API calls -- `addToLibrary` (adds to library), `rateAlbum(.love)` (marks as loved), and `favoriteAlbum` (POST `/v1/me/favorites`, marks with the star icon in Apple Music's Favorites system, iOS 17.1+). Disliking fires `rateAlbum(.dislike)`. All write-back calls use explicit error logging (`do/catch` with print) instead of silent `try?`, so failures are visible in the console. Disliked albums (stored via SwiftData's `DislikedAlbum` model) are filtered from all feeds. Like and dislike are mutually exclusive. This trains Apple Music's recommendation algorithm over time, creating a virtuous cycle where Crate interactions improve the recommendations that feed back into Crate.

**Important: SwiftData modelContext injection.** ViewModels that use FavoritesService or DislikeService (`AlbumDetailViewModel`, `BrowseViewModel`) are created with `@State` (no modelContext at init time). Views must call `viewModel.configure(modelContext:)` in their `.task` modifier before any CRUD operations. The `modelContext` comes from `@Environment(\.modelContext)` in the view. Without this step, all SwiftData operations silently no-op (the services were initialized with `nil` contexts).

Playback uses `ApplicationMusicPlayer` with an independent queue, providing native background audio, lock screen controls, and Now Playing integration automatically. The track list shows a now-playing indicator (play icon replaces track number) for the currently playing track, tinted with a color extracted from the album artwork. A shared `PlaybackRowContent` view (in PlaybackFooterView.swift) provides the artwork + track info + play/pause row used by both the `PlaybackFooterView` mini-player and BrowseView's inline control bar, eliminating duplicated playback UI code. `PlaybackRowContent` reads `stateChangeCounter` directly in its body for self-sufficient state observation. A `PlaybackProgressBar` sits above the playback row (as a layout sibling, not an overlay) in both the footer and the BrowseView control bar. The bar shows track progress with a gradient fill derived from the album artwork's two most prominent colors, extracted by `ArtworkColorExtractor`. The bar is scrubbable via drag gesture (expands from 4pt to 8pt during scrub, fires haptic on iOS). Progress updates every 0.5s via `Timer.publish`. `PlaybackViewModel` tracks `trackDuration` and `currentTracks` to support the progress calculation, with `syncTrackDuration()` updating duration when the player advances tracks. `ArtworkColorExtractor` uses pure CoreGraphics/ImageIO (no UIKit/AppKit) for cross-platform compatibility -- it downloads a 40x40 thumbnail, downsamples to 10x10, quantizes pixels into RGB buckets, scores them with saturation-cubed weighting (biasing toward vivid saturated colors over whites/grays/pastels), filters out near-blacks and desaturated colors, and selects two colors with sufficient contrast. Results are cached by URL. The same extractor is used in `AlbumDetailView` to tint the play button and pass a `tintColor` to `TrackListView`. `BrowseView` accepts a `navigationPath` binding from `ContentView` so the playback row can navigate to the now-playing album's detail view. Favorites are stored locally via SwiftData and also synced to Apple Music library. The UI is built with SwiftUI using MVVM with five `@Observable` view models (`AuthViewModel`, `BrowseViewModel`, `AlbumDetailViewModel`, `PlaybackViewModel`, `CrateWallViewModel`). A single multiplatform codebase targets both iOS and macOS with 95%+ shared code.

## Open Items

- **Visual design.** The PRD defines the UX and layout but not the visual design system (colors, typography, spacing). Album Detail and playback UI have been polished (blurred artwork background, artwork-derived color theming on play button and track list, progress bar with artwork gradient). Other views still need visual polish.
- **Charts depth testing.** Apple does not document a maximum offset for the charts endpoint. Empirical testing is needed to determine how many albums per genre we can paginate through.
- **Testing coverage.** Unit tests exist for MusicServiceTests, BrowseViewModelTests, GenreTaxonomyTests, FavoritesServiceTests, DislikeServiceTests (CRUD, dedup, fetchAllDislikedIDs), and FeedbackLoopTests (mutual exclusion, GenreFeedWeights correctness, weighted interleave). UI test stubs exist (BrowseFlowTests, PlaybackFlowTests). Tests use `@testable import Crate_iOS` (the iOS target's module name) and in-memory SwiftData containers. Tests need to be run on physical devices for MusicKit-dependent paths.
- **CloudKit sync for favorites/dislikes.** Favorites and dislikes are currently device-local. Cross-device sync via CloudKit is a future consideration.
- **macOS build.** The macOS target has a pre-existing build failure (`.systemBackground` is iOS-only in AlbumDetailView). Needs platform-conditional fix.

## Resolved Items

- **MusicKit "Missing requesting bundle version" error.** Resolved. All personalized `/v1/me/*` endpoints were silently failing because `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` were missing from the Xcode build settings. Added to all four build configurations (iOS Debug, iOS Release, macOS Debug, macOS Release). All API calls and SwiftData saves now use `do/catch` with `[Crate]`-prefixed error logging instead of silent `try?` -- applied consistently across CrateWallService, GenreFeedService, FavoritesService, and DislikeService.
- **Genre taxonomy mapping.** Resolved. The taxonomy is implemented in `Genres.swift` with 9 super-genres and ~50 subcategories, mapped to real Apple Music genre IDs. The original PRD proposed 15 super-genres / ~100 sub-categories, but the actual Apple Music genre hierarchy supported 9 well-differentiated super-genres.
- **Super-genre count.** Resolved. Settled on 9: Rock, Pop, Hip-Hop, Electronic, R&B, Jazz, Country, Classical, Latin.
- **Hardware testing plan.** Development is happening on physical devices with an active Apple Music subscription.
