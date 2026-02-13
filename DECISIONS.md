# Architectural Decision Records -- Crate

This document captures key architectural decisions for Crate, with context and rationale. Decisions are numbered and dated. If a decision is revisited, the original is preserved and the revision is appended.

**Note:** ADRs 001-014 (Spotify/Next.js era) were superseded on 2026-02-09 by a full platform pivot from Spotify Web to Apple Music Native. The original ADRs are archived in git history. This file now contains the Apple Music / MusicKit / SwiftUI decisions starting at ADR-100.

For the architecture overview, see [Section 7 of the PRD](./PRD.md#7-architecture-and-technical-decisions).

---

## Index

| ADR | Title | Status |
|-----|-------|--------|
| 100 | [Platform Pivot: Native SwiftUI over Next.js Web](#adr-100-platform-pivot-native-swiftui-over-nextjs-web) | Accepted |
| 101 | [Apple Music (MusicKit) over Spotify](#adr-101-apple-music-musickit-over-spotify) | Accepted |
| 102 | [MVVM with @Observable for App Architecture](#adr-102-mvvm-with-observable-for-app-architecture) | Accepted |
| 103 | [ApplicationMusicPlayer for Playback](#adr-103-applicationmusicplayer-for-playback) | Accepted |
| 104 | [Charts API for Genre-to-Album Pipeline](#adr-104-charts-api-for-genre-to-album-pipeline) | Accepted |
| 105 | [SwiftData for Local Persistence](#adr-105-swiftdata-for-local-persistence) | Accepted |
| 106 | [Local-Only Favorites (Not Apple Music Library)](#adr-106-local-only-favorites-not-apple-music-library) | Superseded by ADR-118 |
| 107 | [Genre Taxonomy as Static Swift Configuration](#adr-107-genre-taxonomy-as-static-swift-configuration) | Accepted |
| 108 | [No Server / No Backend for MVP](#adr-108-no-server--no-backend-for-mvp) | Accepted |
| 109 | [iOS 17+ and macOS 14+ Minimum Deployment Targets](#adr-109-ios-17-and-macos-14-minimum-deployment-targets) | Accepted |
| 110 | [Multiplatform Xcode Project with Shared Code](#adr-110-multiplatform-xcode-project-with-shared-code) | Accepted |
| 111 | [XCTest + Swift Testing for Test Strategy](#adr-111-xctest--swift-testing-for-test-strategy) | Accepted |
| 112 | [App Store + TestFlight for Distribution](#adr-112-app-store--testflight-for-distribution) | Accepted |
| 113 | [In-Memory View Model Cache (No Multi-Layer Caching)](#adr-113-in-memory-view-model-cache-no-multi-layer-caching) | Accepted |
| 114 | [Album-Sequential Playback with No Shuffle](#adr-114-album-sequential-playback-with-no-shuffle) | Accepted |
| 115 | [Crate Wall as Default Landing Experience](#adr-115-crate-wall-as-default-landing-experience) | Accepted |
| 116 | [Single-Row Transforming Filter Bar with Search-Based Subcategory Browsing](#adr-116-single-row-transforming-filter-bar-with-search-based-subcategory-browsing) | Accepted |
| 117 | [Blurred Artwork Background for Album Detail](#adr-117-blurred-artwork-background-for-album-detail) | Accepted |
| 118 | [Personalized Genre Feeds with Feedback Loop](#adr-118-personalized-genre-feeds-with-feedback-loop) | Accepted |
| 119 | [Concurrency Isolation, Error Logging, and Dead Code Removal](#adr-119-concurrency-isolation-error-logging-and-dead-code-removal) | Accepted |
| 120 | [Scatter/Fade Grid Transition for Genre Switching](#adr-120-scatterfade-grid-transition-for-genre-switching) | Accepted |
| 121 | [Now-Playing Progress Bar with Artwork-Derived Gradient](#adr-121-now-playing-progress-bar-with-artwork-derived-gradient) | Accepted |
| 122 | [Staggered Slide Animation for Genre Bar Pills](#adr-122-staggered-slide-animation-for-genre-bar-pills) | Accepted |
| 123 | [Slide-Up Control Bar on Launch + AlbumCrate Rename](#adr-123-slide-up-control-bar-on-launch--albumcrate-rename) | Accepted |
| 124 | [Brand Identity: App Icon, Welcome Screen, and Brand Color](#adr-124-brand-identity-app-icon-welcome-screen-and-brand-color) | Accepted |
| 125 | [Typed Navigation Path, Scrubber Relocation, and Footer Progress Toggle](#adr-125-typed-navigation-path-scrubber-relocation-and-footer-progress-toggle) | Accepted |
| 126 | [Codebase Audit — MainActor Isolation, Guard Hardening, macOS Build Fix, Test Coverage, and Concurrency Cleanup](#adr-126-codebase-audit--mainactor-isolation-guard-hardening-macos-build-fix-test-coverage-and-concurrency-cleanup) | Accepted |
| 127 | [Radio Selection for Crate Dial and Standardized Spinners](#adr-127-radio-selection-for-crate-dial-and-standardized-spinners) | Accepted |
| 128 | [Artist Catalog View with Typed Navigation Destinations](#adr-128-artist-catalog-view-with-typed-navigation-destinations) | Accepted |

---

## ADR-100: Platform Pivot: Native SwiftUI over Next.js Web

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-001 (Next.js + React + Tailwind CSS for Frontend), ADR-011 (Vercel for Deployment)
**PRD Reference:** [Section 6.3 (Platform)](./PRD.md#63-platform), [Section 7.1 (Tech Stack)](./PRD.md#71-tech-stack)

**Context:** The original Crate architecture was a responsive web application built with Next.js, deployed to Vercel. This worked as a starting point, but the Spotify platform constraints (detailed in ADR-101) made the web approach untenable for the core product experience -- specifically, mobile playback required the Spotify app running separately, which broke the "open Crate and listen" promise.

The product needs to play music directly, on mobile, without any external dependency. This is a hard requirement that cannot be met by a web application using Spotify's SDK.

**Decision:** Build Crate as a native SwiftUI multiplatform application targeting iOS and macOS.

**Rationale:**
- MusicKit (the Apple Music framework) is a first-party Swift framework. It requires a native app. There is no JavaScript/web equivalent with the same capabilities.
- SwiftUI multiplatform allows a single codebase to target iOS and macOS with minimal platform-specific code (estimated 95%+ shared).
- Native app means direct playback, background audio, lock screen controls, and system-level integration -- all automatic with MusicKit.
- The builder uses Apple Music, not Spotify, so the smaller subscriber base is irrelevant for a personal project.
- SwiftUI + Swift is our team standard for iOS projects.

**Trade-offs:**
- **No web version.** Users must install the app from the App Store. There is no "just visit a URL" experience. For a personal project, this is acceptable. If we later wanted a web experience, we would build it separately using the Apple Music Web API (MusicKit.js).
- **Apple ecosystem only.** No Android, no Windows, no Linux. This is fine for a personal project. If cross-platform became a requirement, we would re-evaluate.
- **Xcode-only toolchain.** Development requires a Mac with Xcode. This is already the case for our iOS standard stack.
- **No SEO benefit.** A web app could theoretically attract organic search traffic. A native app relies on App Store discovery. For a personal tool, this does not matter.

**What would change this:** If the product needed to reach users who do not have Apple devices, or if web distribution became a hard requirement, we would add a web client using MusicKit.js alongside the native app (not instead of it).

---

## ADR-101: Apple Music (MusicKit) over Spotify

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-002 (Genre-to-Album Pipeline via Artist Search), ADR-009 (Spotify Web Playback SDK), ADR-010 (Mobile Playback via Spotify Connect Fallback), ADR-014 (Scoped Spotify Permissions)
**PRD Reference:** [Section 7.1 (Tech Stack)](./PRD.md#71-tech-stack), [Section 7.2 (Genre-to-Album Pipeline)](./PRD.md#72-genre-to-album-pipeline-apple-music-charts)

**Context:** The Spotify architecture had five critical constraints:

1. **Mobile playback was broken.** Spotify's Web Playback SDK does not work on mobile browsers. On mobile, Crate was reduced to a remote control for the Spotify app -- the user had to have Spotify open separately. For a "mobile-first" product about listening to albums, this was a dealbreaker.
2. **Genre browsing was indirect and expensive.** Spotify associates genres with artists, not albums. Fetching albums by genre required a multi-step pipeline (search artists by genre -> fetch each artist's albums -> deduplicate -> sort), costing 20+ API calls per page.
3. **5-user developer limit.** Spotify's recent Development Mode restrictions cap the app at 5 authorized users. Expanding requires Extended Quota Mode (registered business, 250K+ MAU). For a personal project, this is an unnecessary obstacle.
4. **February 2026 API removals.** Spotify removed batch endpoints, browse categories, and new releases. The remaining viable path (search with genre filter) is fragile -- if Spotify further restricts it, the entire product breaks.
5. **macOS required a web wrapper.** The Spotify Web Playback SDK runs in a browser. A "native" macOS experience would require a WKWebView wrapper, which is a poor user experience.

**Decision:** Replace Spotify with Apple Music via the MusicKit framework.

**Rationale:**
- **MusicKit plays audio directly in the app.** `ApplicationMusicPlayer` handles DRM, streaming, background audio, and lock screen controls natively on iOS and macOS. No external app dependency. This alone resolves the biggest product problem.
- **Direct genre-to-album APIs.** The Apple Music charts endpoint accepts a genre parameter and returns albums. One API call per page, not 20+.
- **No developer quota.** Apple imposes no user limits during development. TestFlight supports 10,000 beta testers.
- **Native macOS support.** Same MusicKit framework, same Swift code. True native experience on both platforms.
- **Simpler auth.** System-level Apple ID. One dialog, one tap. No OAuth browser flow, no token management, no cookie encryption.
- **Stable API.** Apple Music API has been stable since its introduction. No recent removals or deprecations.

**Trade-offs:**
- **Smaller subscriber base.** Apple Music has roughly 100 million subscribers vs. Spotify's 250 million+. For a personal project where the builder uses Apple Music, this is irrelevant. For a commercial product, this would be a significant consideration.
- **Apple ecosystem lock-in.** MusicKit only works on Apple platforms. No Android, no web (without a separate MusicKit.js implementation). Acceptable for a personal project.
- **Less genre granularity.** Spotify has hundreds of micro-genres. Apple Music's genre taxonomy is more conservative (roughly 20-30 top-level genres). This may actually be better for our two-tier taxonomy since it reduces the mapping complexity, but it means fewer hyper-specific sub-categories.
- **No equivalent of Spotify's "popularity" score on individual albums.** Apple Music charts are ranked by streams, but individual albums do not expose a numeric popularity field. Within a genre chart, the ordering itself represents popularity (position 1 = most popular).

**What would change this:** If the product pivoted to targeting Spotify users specifically, or if cross-platform (Android) became a hard requirement, we would need to revisit. But those scenarios fundamentally change the product's audience.

---

## ADR-102: MVVM with @Observable for App Architecture

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-006 (Zustand for Client-Side State Management)

**Context:** SwiftUI applications need a pattern for organizing business logic separately from view code. The main options are:

1. **MVVM with ObservableObject** -- the traditional SwiftUI approach. Requires `@Published` on every property, `@StateObject` / `@ObservedObject` / `@EnvironmentObject` wrappers.
2. **MVVM with @Observable** -- the modern approach (iOS 17+). Automatic property tracking, simpler wrappers (`@State`, `@Environment`).
3. **TCA (The Composable Architecture)** -- a third-party framework for unidirectional data flow. Powerful but complex, steep learning curve.
4. **No pattern (logic in views)** -- works for trivial apps but does not scale.

**Decision:** MVVM using the `@Observable` macro (Observation framework). Five view models: `AuthViewModel`, `BrowseViewModel`, `AlbumDetailViewModel`, `PlaybackViewModel`, `CrateWallViewModel`.

**Rationale:**
- `@Observable` is Apple's recommended approach as of iOS 17. It is the direction the platform is heading.
- Automatic fine-grained tracking means views only re-render when the specific properties they read change. This is critical for the playback footer, which updates a progress bar every second -- with `ObservableObject`, every view reading any property from the playback model would re-render on every tick. With `@Observable`, only the progress bar re-renders.
- MVVM maps naturally to SwiftUI's view/model separation. ViewModels own the business logic. Views are purely declarative UI.
- TCA was considered and rejected. It introduces significant complexity (reducers, effects, stores, dependencies) that is not warranted for an app with three views and a straightforward data flow. TCA shines in apps with complex state interactions and large teams. Crate is neither.
- The app's state is genuinely simple: genre selection, a list of albums, playback state, favorites. No complex state machines, no multi-step workflows, no offline/online sync. MVVM with `@Observable` handles this cleanly.

**Trade-offs:**
- Requires iOS 17+ / macOS 14+. This is already our minimum target (see ADR-109), so no additional cost.
- `@Observable` is newer and some edge cases may be less well-documented than `ObservableObject`. In practice, for our simple state model, this is low risk.
- No unidirectional data flow enforcement. If the app grew significantly more complex, we might miss TCA's structure. The app currently has five views (Auth, Browse/Wall, Album Detail, Playback Footer, Settings) and five view models, which remains well within MVVM's comfort zone.

**What would change this:** If the app grew to 10+ views with complex shared state and multi-step workflows (e.g., social features, playlists, user profiles), we would revisit TCA. The PRD's design philosophy makes this unlikely.

---

## ADR-103: ApplicationMusicPlayer for Playback

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-009 (Spotify Web Playback SDK), ADR-010 (Mobile Playback via Spotify Connect Fallback)
**PRD Reference:** [Section 3.4 (Playback Footer)](./PRD.md#34-playback-footer), [Section 7.4 (Playback Architecture)](./PRD.md#74-playback-architecture)

**Context:** MusicKit provides two player types:
- `SystemMusicPlayer` -- shares the playback queue with the system Music app. When Crate plays something, it replaces whatever the user had playing in Music.
- `ApplicationMusicPlayer` -- owns an independent playback queue. Crate's playback does not affect the Music app, and vice versa.

**Decision:** Use `ApplicationMusicPlayer`.

**Rationale:**
- Crate is a dedicated album listening experience. It should own its playback context completely. If the user was listening to a playlist in Music and opens Crate to browse albums, Crate should not hijack their Music app queue.
- `ApplicationMusicPlayer` provides automatic Now Playing integration (lock screen, Control Center, menu bar on macOS) without additional code.
- Background audio on iOS works automatically with the `audio` background mode entitlement.
- The player works identically on iOS and macOS. Zero platform-specific code for playback.

**Key implementation details:**
- Album playback is initiated by loading tracks into the player's queue and calling `play()`.
- Shuffle mode is explicitly set to `.off` to enforce album-sequential playback (see ADR-114).
- Transport controls (play, pause, skip, seek) are direct method calls on the shared player instance.
- Playback state is observable. The `PlaybackViewModel` reads `player.state.playbackStatus`, `player.queue.currentEntry`, and `player.playbackTime` to keep the UI in sync.

**Trade-offs:**
- `ApplicationMusicPlayer` requires the app to be running (even if backgrounded) for playback to continue. If the system terminates the app (memory pressure, user force-quit), playback stops. This is standard behavior for music apps and is acceptable.
- Volume control is system-level, not app-level. We cannot provide an in-app volume slider on iOS (this is an Apple platform constraint, not a MusicKit limitation). On macOS, we can adjust the system volume programmatically, but most users will use keyboard volume keys.

**What would change this:** If we wanted Crate to enhance the Music app experience (like a smart queue manager), `SystemMusicPlayer` would be more appropriate. But Crate's product vision is an independent, focused listening environment, so `ApplicationMusicPlayer` is correct.

---

## ADR-104: Charts API for Genre-to-Album Pipeline

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-002 (Genre-to-Album Pipeline via Artist Search), ADR-003 (Server-Side API Proxy Layer)
**Refined by:** ADR-116 (subcategory browsing uses Search endpoint instead of Charts)
**PRD Reference:** [Section 7.2 (Genre-to-Album Pipeline)](./PRD.md#72-genre-to-album-pipeline-apple-music-charts)

**Context:** The central technical problem in Crate is: "Given a genre, show me albums." The Spotify architecture required a complex multi-step pipeline because Spotify does not associate genres with albums. Apple Music does, via the charts endpoint.

**Decision:** Use the Apple Music Catalog Charts endpoint (`GET /v1/catalog/{storefront}/charts?types=albums&genre={genreID}`) as the primary data source for the album grid.

**How it works:**
1. User selects a sub-category in the taxonomy.
2. Taxonomy lookup produces one or more Apple Music genre IDs.
3. For each genre ID, fetch `charts?types=albums&genre={id}&limit=50&offset={page * 50}`.
4. If multiple genre IDs (multi-select), merge results, deduplicate by album ID, maintain chart-rank ordering.
5. Display in grid. Paginate by incrementing offset.

**Rationale:**
- **One API call per page of results.** The Spotify pipeline required ~20+ calls (artist searches + individual album fetches). This is a 20x reduction in API calls.
- **No server-side aggregation.** The response is already a sorted, deduplicated list of albums. No proxy layer needed.
- **Albums are ranked by popularity** (most-played) within the genre. This matches the PRD's requirement for popularity-sorted results.
- **Standard pagination.** Limit and offset parameters work like any REST API. No cursor math, no virtual pagination over aggregated data.

**Supplementary strategy for sparse genres:**

Some niche genres may have limited chart data. If a genre query returns fewer results than expected, we can supplement with `MusicCatalogSearchRequest` using genre-related search terms. This is a fallback, not the primary path.

**Trade-offs:**
- **Charts data reflects recent popularity, not all-time catalog depth.** The charts endpoint returns what people are listening to now, which biases toward newer and more popular albums. Deep catalog cuts from the 1970s may not appear unless they are currently popular. This is a trade-off between discoverability of "current popular" vs. "deep catalog." For MVP, current popular is the right default. Deep catalog exploration could be added later via search.
- **Genre granularity is limited to Apple's taxonomy.** We cannot query arbitrary micro-genres the way Spotify's artist genre tags allowed. Apple Music has roughly 20-30 genres. Some sub-categories in our taxonomy may map to the same Apple Music genre ID, producing identical results. This needs to be validated during taxonomy mapping.
- **Offset-based pagination may have undocumented limits.** We need to test empirically how deep the pagination goes. If it caps at, say, 200 albums per genre, that is still sufficient for browsing but worth knowing.

**What would change this:** If the charts endpoint proved too shallow for good browsing (e.g., only returning 50 albums per genre), we would supplement with search-based approaches. If Apple introduced a more granular genre-filtering endpoint, we would adopt it.

---

## ADR-105: SwiftData for Local Persistence

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-013 (No Supabase or External Database for MVP)
**PRD Reference:** [Section 7.7 (Favorites)](./PRD.md#77-favorites)

**Context:** The Spotify architecture used no database because auth lived in cookies, favorites synced with Spotify's library, and the taxonomy was a static JSON file. With the pivot to a native app, the persistence question needs to be re-evaluated.

Favorites need to be stored somewhere. Options:
1. Apple Music Library (write to the user's actual library)
2. UserDefaults / @AppStorage (simple key-value)
3. SwiftData (structured local database)
4. Core Data (legacy structured database)
5. No persistence (in-memory only, lost on app restart)

**Decision:** Use SwiftData for local persistence. The primary use case at MVP is storing favorited albums.

**Rationale:**
- SwiftData is Apple's modern persistence framework, purpose-built for SwiftUI. It integrates natively with `@Query`, `@Model`, and the SwiftUI view lifecycle.
- It provides structured storage (not just key-value), which is appropriate for album objects with multiple fields (ID, title, artist, artwork URL, date added).
- It supports CloudKit sync with minimal additional code if we later want favorites to sync across devices (see ADR-106).
- It requires iOS 17+ / macOS 14+, which is already our minimum target (see ADR-109).
- UserDefaults could technically store an array of Codable objects, but it is not designed for structured, queryable data. SwiftData is the right tool for the job.
- Core Data works but is legacy. SwiftData is its successor and is significantly simpler to use.

**What we store:**
- `FavoriteAlbum` model: album ID, title, artist name, artwork URL, date added
- `DislikedAlbum` model: album ID, title, artist name, artwork URL, date added
- Future: listening history, user preferences, cached genre data

**Implementation note -- modelContext injection:** ViewModels are created as `@State` properties on views, which means they are initialized before the SwiftUI environment is available. Services that need a `ModelContext` (FavoritesService, DislikeService) are therefore initialized with `nil` contexts. Views must call `viewModel.configure(modelContext:)` in their `.task` modifier, passing the `@Environment(\.modelContext)` value, before any CRUD operations. Without this step, all SwiftData operations silently no-op. This pattern was introduced after discovering that favorites and dislikes appeared to work (UI toggled correctly) but never persisted to SwiftData.

**Trade-offs:**
- Adds a persistence layer that the Spotify architecture did not need. This is a small amount of additional complexity, but it is well-justified by the favorites feature and the benefits of owning data locally.
- SwiftData is newer (introduced WWDC 2023) and has had some rough edges in early releases. As of iOS 17.2+ / macOS 14.2+, it is stable for our use case.
- If the data model needs to change (migration), SwiftData handles lightweight migrations automatically. Complex migrations would require more effort, but our model is simple enough that this is unlikely.

**What would change this:** If we decided favorites should sync with Apple Music's library (see ADR-106 for why we chose not to), we would not need SwiftData for MVP. But even then, SwiftData is useful for future features (history, preferences).

---

## ADR-106: Local-Only Favorites (Not Apple Music Library)

**Date:** 2026-02-09
**Status:** Superseded by ADR-118
**Supersedes:** ADR-007 (Favorites Stored in Spotify's Library)
**PRD Reference:** [Section 3.5 (Favorites)](./PRD.md#35-favorites), [Section 7.7 (Favorites)](./PRD.md#77-favorites)

**Context:** The Spotify architecture synced favorites with Spotify's saved albums. This made sense because it meant no database and bi-directional sync between Crate and Spotify. The Apple Music equivalent would be using `MusicLibrary` to add albums to the user's Apple Music library.

**Decision:** Store favorites locally in SwiftData. Do not write to the user's Apple Music library.

**Rationale:**
- **Respect the user's library.** The user's Apple Music library is their personal collection. Crate favoriting an album should not pollute their library with albums they were just bookmarking for later. "Favorite in Crate" and "Add to my Apple Music library" are different intents.
- **No unexpected side effects.** If a user favorites 50 albums in a browsing session, they should not find 50 new albums in their Music app's library. That would feel invasive.
- **Simpler mental model.** Favorites are a Crate feature, not an Apple Music feature. They live in Crate.
- **No network dependency for favorites.** Favoriting and unfavoriting work instantly, offline, with no API calls.
- **Future flexibility.** We can add an explicit "Add to Apple Music Library" action as a separate button if users want it. This gives the user control rather than making the decision for them.

**Trade-offs:**
- **No bi-directional sync.** Albums saved in the Music app do not appear in Crate's favorites. This is intentional -- Crate favorites are Crate-specific.
- **Favorites are device-local by default.** If the user has Crate on their iPhone and Mac, favorites do not sync between them unless we enable CloudKit. This is acceptable for MVP and can be addressed with a CloudKit toggle later.
- **Requires SwiftData** (see ADR-105), adding a persistence layer. This is a small cost for a clean user experience.

**What would change this:** If user research revealed that people strongly expect favorites to sync with their Apple Music library, we would add it as an explicit opt-in action. We would not make it the default behavior.

---

## ADR-107: Genre Taxonomy as Static Swift Configuration

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-008 (Genre Taxonomy as Static JSON Configuration)
**PRD Reference:** [Section 2.2 (Structure)](./PRD.md#22-structure), [Section 7.8 (Genre Taxonomy Storage)](./PRD.md#78-genre-taxonomy-storage)

**Context:** The Spotify architecture stored the genre taxonomy as a JSON file validated at build time with Zod. For the native app, we need to decide how to store and validate the taxonomy.

**Decision:** Store the taxonomy as a Swift source file (`Genres.swift`) containing typed struct instances. No JSON. No runtime parsing.

**Rationale:**
- The Swift compiler validates the taxonomy at compile time. Typos in genre IDs, missing fields, or structural errors are caught before the app ever runs. This is strictly stronger than Zod validation at build time, because it is the same language and toolchain -- no separate validation step.
- Swift structs are type-safe. An `appleMusicGenreIDs` field is an array of strings. You cannot accidentally put an integer in it. With JSON, a missing quote or wrong type is a runtime error.
- No parsing overhead at app launch. The data is compiled into the binary.
- The taxonomy is small (9 super-genres, ~50 subcategories) and changes infrequently. A Swift file is the simplest representation with the strongest guarantees.

**Schema:**

```swift
struct GenreCategory: Identifiable, Sendable {
    let id: String
    let label: String
    let subCategories: [SubCategory]
}

struct SubCategory: Identifiable, Sendable {
    let id: String
    let label: String
    let appleMusicGenreIDs: [String]
}
```

**Open question:** Apple Music may have a hierarchical genre structure that closely maps to our desired Tier 1 / Tier 2 taxonomy. If so, we could dynamically fetch the genre tree from the API and eliminate the static file entirely. This should be investigated during implementation. Even if we go dynamic, having a static fallback is a good safety net.

**Trade-offs:**
- Updating the taxonomy requires a code change and app update. Given that taxonomy changes are infrequent (quarterly at most) and require an app review cycle anyway, this is acceptable.
- Non-technical team members cannot edit the taxonomy without developer help. For a personal project, the "team" is one person, so this is irrelevant.

**What would change this:** If the taxonomy needed to be updated without an app release (e.g., A/B testing genre labels), we would move it to a remote configuration service (Firebase Remote Config, or a simple JSON file hosted on a CDN). This is overkill for MVP.

---

## ADR-108: No Server / No Backend for MVP

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-003 (Server-Side API Proxy Layer), ADR-004 (Spotify OAuth with Server-Side Token Management)
**PRD Reference:** [Section 6.4 (No Server / No Backend)](./PRD.md#64-no-server--no-backend)

**Context:** The Spotify architecture required a Next.js server for three reasons: (1) protect the Spotify client secret, (2) run the genre-to-album aggregation pipeline, (3) manage OAuth token refresh. With MusicKit, all three reasons are eliminated.

**Decision:** No server. No backend. The app is fully client-side.

**Rationale:**
- **No secret to protect.** MusicKit authentication is handled by the provisioning profile and system-level Apple ID. There is no client secret, no API key in the code, no JWT to sign. The developer token is generated automatically by the MusicKit entitlement.
- **No aggregation pipeline.** The charts endpoint returns albums directly. No multi-step server-side processing needed.
- **No token management.** MusicKit manages both the developer token and the Music User Token automatically. No refresh flow to implement.
- **No rate limit proxy.** With 1 API call per page (instead of 20+), and Apple's 20 req/sec per-user limit, rate limiting is not a concern that requires server-side throttling.

**Trade-offs:**
- **No server-side analytics.** We cannot log API usage, popular genres, or user behavior server-side. We rely on App Store Connect analytics and any future in-app analytics SDK (e.g., Firebase Analytics) if needed.
- **No shared cache.** Each device makes its own API calls. There is no shared cache layer to reduce Apple Music API load across users. At personal-project scale, this is irrelevant.
- **Cannot enforce business logic server-side.** Everything runs on the user's device. For a personal project with no commercial logic, this is fine.

**What would change this:** If we needed user accounts (social features, cross-device sync without iCloud, server-side playlists), or if we needed server-side analytics, we would introduce a backend. Supabase or a lightweight Vapor (Swift server) would be the natural choices.

---

## ADR-109: iOS 17+ and macOS 14+ Minimum Deployment Targets

**Date:** 2026-02-09
**Status:** Accepted

**Context:** Several framework choices require minimum OS versions:
- `@Observable` macro: iOS 17.0+ / macOS 14.0+
- SwiftData: iOS 17.0+ / macOS 14.0+
- Latest MusicKit APIs: iOS 16.0+ / macOS 13.0+ (but newer features require 17+)
- Swift Testing: Xcode 16+ (any deployment target)

**Decision:** Set minimum deployment targets to iOS 17.0 and macOS 14.0 (Sonoma).

**Rationale:**
- iOS 17 adoption is approximately 85-90% of active iPhones as of early 2026 (roughly 18 months after release). The remaining 10-15% are mostly older devices that would provide a poor experience regardless.
- macOS Sonoma (14.0) adoption among Mac users is high, and the Mac user base for this app is secondary to iOS.
- Targeting iOS 17+ lets us use `@Observable` (ADR-102) and SwiftData (ADR-105) without compatibility shims. These are not just nice-to-haves -- they are significantly simpler than their predecessors and reduce the code we need to write and maintain.
- Supporting iOS 16 would require falling back to `ObservableObject` and Core Data, nearly doubling the complexity of the data and state layers for a shrinking minority of devices.

**Trade-offs:**
- Excludes iPhone 8 and earlier (which cannot run iOS 17). These devices are 6+ years old. Acceptable.
- Excludes Macs that cannot run Sonoma. These are pre-2018 models. Acceptable.
- If a user has an older device, they cannot use Crate. For a personal project, this is not a concern. For a commercial product, we would need to evaluate the market.

**What would change this:** If Apple significantly changed the APIs in iOS 18 in a way that benefited Crate (e.g., new MusicKit features), we might raise the minimum to iOS 18. We would not lower it below iOS 17 given the framework dependencies.

---

## ADR-110: Multiplatform Xcode Project with Shared Code

**Date:** 2026-02-09
**Status:** Accepted

**Context:** Crate targets both iOS and macOS. We need to decide how to structure the Xcode project:
1. Single multiplatform target (Xcode's "Multiplatform" template)
2. Separate iOS and macOS targets with shared code via a framework/package
3. Two entirely separate projects

**Decision:** Single Xcode project using the multiplatform app template. Shared code in one main target. Platform-specific code in separate iOS and macOS target folders, used sparingly.

**Rationale:**
- The multiplatform template is Apple's recommended approach for apps that share most of their code across platforms. It generates separate build schemes for iOS and macOS from the same source.
- SwiftUI views, MusicKit integration, SwiftData models, and view models are all platform-agnostic. Estimated 95%+ of code is shared.
- Platform-specific code is minimal: background audio entitlement (iOS), menu bar commands (macOS), window sizing (macOS).
- A shared framework or Swift Package would add indirection without meaningful benefit at this scale. If the app grew to include watchOS or tvOS targets, we would consider extracting shared code into a package.

**How platform branching works:**
- Most differences are handled by SwiftUI automatically (adaptive layouts, system controls).
- Where explicit branching is needed, use `#if os(iOS)` / `#if os(macOS)` within shared files.
- Files that are entirely platform-specific (e.g., macOS menu bar commands) go in the platform-specific target folder.

**Trade-offs:**
- Conditional compilation (`#if os(...)`) can become messy if overused. We mitigate this by keeping platform-specific logic in dedicated files rather than sprinkling `#if` blocks throughout shared code.
- Build times may be slightly longer than a single-platform project because Xcode builds for both platforms. Negligible at our project size.

**What would change this:** If the iOS and macOS experiences diverged significantly (e.g., macOS got a completely different navigation paradigm), we would split into separate targets with a shared Swift Package for the data and service layers. The current product design does not call for this.

---

## ADR-111: XCTest + Swift Testing for Test Strategy

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** Vitest + React Testing Library (web-era test stack)

**Context:** The native app needs a testing strategy. Options:
1. XCTest only (Apple's traditional test framework)
2. Swift Testing only (Apple's new test framework, Xcode 16+)
3. Both (XCTest for UI tests, Swift Testing for unit tests)

**Decision:** Use both. Swift Testing for unit tests. XCTest for UI tests.

**Rationale:**
- Swift Testing (introduced at WWDC 2024) provides more expressive assertions, parameterized tests (`@Test(arguments:)`), and better error messages. It is the future of unit testing on Apple platforms.
- XCTest is still required for UI testing (`XCUITest`). Swift Testing does not have a UI testing equivalent.
- Both frameworks can coexist in the same test target. No conflict.

**What to test:**
- **Unit tests (Swift Testing):** `MusicService` (API call construction and response parsing), `BrowseViewModel` (genre selection logic, pagination), `GenreTaxonomy` (taxonomy structure validation), `FavoritesService` (CRUD operations), `DislikeService` (CRUD, dedup, fetchAllDislikedIDs), `FeedbackLoop` (mutual exclusion between likes/dislikes, GenreFeedWeights correctness, weighted interleave).
- **UI tests (XCTest/XCUITest):** Browse flow (select genre -> see albums), album detail flow (tap album -> see detail), playback flow (tap play -> footer appears).
- **Note:** MusicKit does not work in the Simulator. Unit tests that mock the MusicKit layer can run in the Simulator. Integration tests and UI tests that require actual MusicKit playback must run on physical devices.

**Test infrastructure note:** The test target's `TEST_HOST` must reference the iOS app bundle as `Crate-iOS` (not `Crate`), and test files must use `@testable import Crate_iOS` (the module name, with underscore replacing the hyphen). SwiftData tests use in-memory `ModelContainer` instances (`ModelConfiguration(isStoredInMemoryOnly: true)`) to avoid touching disk.

**Trade-offs:**
- Two test frameworks is slightly more complexity than one. In practice, the boundary is clean: Swift Testing for logic, XCTest for UI.
- Physical device requirement for integration testing adds friction. We accept this because it is a MusicKit platform constraint, not a choice.

**What would change this:** If Swift Testing added UI testing support, we would migrate XCUITests. This is likely a future development but not available today.

---

## ADR-112: App Store + TestFlight for Distribution

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-011 (Vercel for Deployment)

**Context:** A native app needs a distribution strategy. Options:
1. App Store (public distribution)
2. TestFlight only (beta distribution)
3. Ad-hoc / enterprise distribution
4. Direct download (macOS only, outside App Store)

**Decision:** App Store for both iOS and macOS (universal purchase). TestFlight for beta testing during development.

**Rationale:**
- App Store is the standard distribution channel for consumer iOS apps. There is no alternative on iOS (sideloading is not practical for end users).
- Mac App Store provides the same distribution for macOS, and a universal purchase means users buy once for both platforms.
- TestFlight is free, supports up to 10,000 external beta testers, and provides crash reports and feedback tools. This is a massive improvement over Spotify's 5-user developer limit.
- Xcode Cloud can automate the build -> test -> TestFlight pipeline.

**Trade-offs:**
- App Store review adds a delay (typically 1-3 days) to every release. For a personal project with no urgent release schedule, this is fine.
- Apple takes a 15% commission on in-app purchases (first year for small developers). Crate has no in-app purchases, so this is irrelevant.
- The app must comply with App Store Review Guidelines. MusicKit apps are common and well-understood by Apple's review team, so no unusual compliance risk.

**What would change this:** If we wanted to distribute a macOS version outside the App Store (e.g., direct download from a website), we could do so with Developer ID signing. This would allow faster iteration on macOS without App Store review. Not needed for MVP.

---

## ADR-113: In-Memory View Model Cache (No Multi-Layer Caching)

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-005 (Multi-Layer Caching Strategy)

**Context:** The Spotify architecture required three caching layers (server in-memory, CDN, client-side) because the genre pipeline was expensive (20+ API calls per page). With Apple Music's charts endpoint, each page is a single API call.

**Decision:** Cache chart results in the `BrowseViewModel`'s in-memory state. No server cache (there is no server). No CDN cache. No disk cache for API responses.

**Implementation:**
- `BrowseViewModel` maintains a dictionary of `[GenreCacheKey: [Album]]` where the cache key combines the genre ID(s) and page range.
- When the user switches genres, results for the previous genre remain in memory.
- When the user returns to a previously viewed genre, results are served from this cache instantly.
- Cache is cleared when the app is terminated. Fresh data on every app launch.
- TTL: none within a session. The chart rankings do not change fast enough to warrant mid-session invalidation.

**For album artwork:**
- `AsyncImage` with the system URL cache handles artwork caching automatically. The system manages cache eviction based on available storage.
- If we find that artwork loading is too slow (e.g., on scroll), we can add a dedicated image cache library (Kingfisher, Nuke). But the system cache should be tested first.

**Rationale:**
- 1 API call per page eliminates the need for aggressive caching to stay within rate limits.
- In-memory caching in the view model is the simplest approach and is sufficient for the browsing pattern (select genre, scroll, switch genre, come back).
- Adding disk caching for API responses would speed up app relaunch but adds complexity. Chart data changes daily, so yesterday's cache is stale anyway. Not worth the complexity for MVP.

**Trade-offs:**
- Every app launch fetches fresh data. On a fast connection, this is imperceptible. On a slow connection, there is a brief loading state. Acceptable.
- Memory usage grows as the user browses more genres. With 50 albums per page and a few pages per genre, this is kilobytes of data. Not a concern.

**What would change this:** If users reported slow load times when switching between previously viewed genres (unlikely given the single API call), we would add a lightweight disk cache with a 1-hour TTL. Or if network conditions were frequently poor (e.g., if this were a travel/offline-focused app), we would add offline support with persistent caching. Neither applies to Crate.

---

## ADR-114: Album-Sequential Playback with No Shuffle

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 3.4 (Playback Footer)](./PRD.md#34-playback-footer), [Section 8 (Design Principles)](./PRD.md#8-design-principles)

**Context:** The PRD states: "No shuffle button. Shuffle is deliberately excluded. Crate is an album listening experience. Tracks play in album order. This is a product decision, not an oversight."

**Decision:** Explicitly enforce `shuffleMode = .off` on `ApplicationMusicPlayer` whenever playback is initiated. Do not expose a shuffle control in the UI.

**Implementation:**

```swift
let player = ApplicationMusicPlayer.shared
player.state.shuffleMode = .off
player.state.repeatMode = .off  // or .all if we want album-repeat
```

This is set every time we start playing an album, to guard against the shuffle mode being set from a previous MusicKit session or by another app.

**Rationale:**
- This is a core product principle, not a technical decision. The architecture enforces it.
- MusicKit defaults to `shuffleMode = .off`, so in most cases this is redundant. But being explicit is defensive programming -- it costs nothing and prevents a class of bugs.
- The repeat mode is set to `.off` by default (album plays once, then stops). If the product team decides album repeat is desirable, changing to `.all` is a one-line change.

**Trade-offs:**
- Users who want shuffle cannot get it. This is intentional. If user feedback strongly requests it as an option, it would be a product decision to add it, not an architecture change.

**What would change this:** A product decision to add shuffle as an opt-in feature. The architecture supports it trivially (expose a toggle that sets `shuffleMode = .songs`). The bar for adding it should be high -- it goes against the product philosophy.

---

## ADR-115: Crate Wall as Default Landing Experience

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** Crate Wall feature specification

**Context:** The original Browse view launched with an empty state ("Pick a genre"), requiring the user to make a choice before seeing any content. This creates a cold-start problem — new users see a blank screen. Additionally, chart-sourced albums showed placeholder icons because `AlbumArtworkView` only handled MusicKit `Artwork` objects, not the `artworkURL` strings returned by the Charts API.

**Decision:** Replace the empty state with an algorithm-driven wall of album art as the default landing experience. The wall blends five signals (Listening History, Recommendations, Popular Charts, New Releases, Wild Card) weighted by a "Crate Dial" settings slider. The user can still browse by genre by selecting a genre pill.

**Architecture:**

- **CrateDial model** (`CrateDialPosition` enum, `CrateDialWeights` struct): Defines 5 dial positions from "My Crate" (personal-heavy) to "Mystery Crate" (random-heavy), each with a weight table mapping signals to fractional proportions.
- **CrateDialStore**: Persists dial position to UserDefaults. Defaults to `.mixedCrate`.
- **CrateWallService**: Orchestrates parallel fetches across signal sources using `TaskGroup`, deduplicates by album ID, and performs a weighted-interleave shuffle so higher-weighted signals appear more frequently but aren't clustered.
- **CrateWallViewModel**: `@Observable` class owned as `@State` on `BrowseView`. Persists within a session (survives navigation push/pop), resets on cold launch.
- **AlbumArtworkView artworkURL fix**: Resolves Apple Music artwork URL templates (`{w}` and `{h}` placeholders) and displays via `AsyncImage`. Fixes both the wall and existing genre browse.
- **AlbumGridView dual style**: `.wall` mode (zero-gap, artwork only, 2 fixed columns on iOS) vs `.browse` mode (existing layout with spacing and text labels).
- **GenreBarView "Crate" pill**: First pill in the genre bar returns to the wall. Highlighted when no genre is selected.
- **SettingsView**: Half-sheet with discrete slider for the Crate Dial position. Dial changes regenerate the wall live via a debounced callback (1s delay).

**Graceful degradation:** Personal signals (recently played, recommendations) may fail if the user has limited listening history or if the API is unavailable. `CrateWallService` catches these errors and redistributes those counts to chart-based signals (which require only an Apple Music subscription, not listening history).

**Rationale:**
- Eliminates cold-start empty state. Users see content immediately on launch.
- The five-signal blend creates a serendipitous browsing experience that gets more personalized as the user listens more.
- The Crate Dial gives users control over the exploration/familiarity balance without requiring them to understand the algorithm.
- `@State` ownership on `BrowseView` means the wall persists within a session (no re-fetch when navigating back from album detail) but regenerates fresh on cold launch or when the user adjusts the Crate Dial (debounced at 1 second).
- Infinite scroll via `fetchMore(excluding:)` provides bottomless content.

**Trade-offs:**
- Multiple parallel API calls on launch (~8-12 concurrent requests). Apple Music's 20 req/sec per-user limit is sufficient, but on slow connections the wall may take a few seconds to populate.
- The wall is generated client-side with random genre picks, so two launches produce different walls. This is a feature (serendipity), not a bug.
- No server-side curation or editorial input. The "quality" of the wall depends on Apple Music's chart data and the user's listening history.

**What would change this:** If Apple introduced a personalized "For You" albums API with genre diversity, we might use it as a simpler alternative to the five-signal blend. Or if the wall proved too slow on launch, we might cache the previous wall to SwiftData and show it while refreshing in the background.

---

## ADR-116: Single-Row Transforming Filter Bar with Search-Based Subcategory Browsing

**Date:** 2026-02-10
**Status:** Accepted
**Refines:** ADR-104 (Charts API for Genre-to-Album Pipeline)

**Context:** The genre browsing UI previously had two separate bars -- a `GenreBarView` for super-genres and a `SubCategoryBarView` that appeared as a second row below it when a genre was selected. This created a layout height jump every time the user selected or deselected a genre, causing the album grid below to shift vertically. Additionally, subcategory browsing originally used the same Charts API endpoint as parent genres, but the Charts API does not reliably support sub-genre IDs -- many subcategory genre IDs returned empty or incorrect results, leaving the album grid sparse or unpopulated.

**Decision:** Consolidate `GenreBarView` and `SubCategoryBarView` into a single-row, two-state filter bar. Use the Apple Music Search endpoint (`/v1/catalog/{storefront}/search`) for subcategory browsing instead of the Charts endpoint.

**Architecture:**

- **Single-row filter bar (GenreBarView)**: The bar occupies one fixed row at all times. In the default state, it shows genre pills (including the "Crate" pill for the wall). When a genre is selected, the bar transforms in-place to show the selected genre name with a dismiss button (x) followed by that genre's subcategory pills. `SubCategoryBarView` was deleted; its functionality is absorbed into `GenreBarView`.
- **Two fetch strategies in BrowseViewModel**: Parent genre selection continues to use the Charts endpoint (proven reliable for top-level genre IDs). Subcategory selection uses the Search endpoint with the subcategory label as the search term, filtered to albums. This dual strategy is necessary because the Charts API does not reliably return results for sub-genre IDs.
- **Multi-select subcategory search**: When multiple subcategories are selected, parallel search queries run concurrently, and results are merged and deduplicated by album ID.
- **Catalog batch enrichment**: After chart fetches for parent genres, albums are batch-enriched via the catalog endpoint to ensure reliable `genreNames` metadata (the charts response sometimes omits genre details).
- **Visual feedback**: Selected subcategory pills display in accent color (blue) to distinguish them from unselected pills.
- **MusicService.searchAlbums**: New method added to `MusicService` using `/v1/catalog/{storefront}/search?types=albums&term={term}&limit={limit}&offset={offset}`.

**Rationale:**
- **No layout jumps.** A single fixed-height row means the album grid never shifts vertically when the user interacts with genre/subcategory filters. This is a smoother, less jarring experience.
- **Search endpoint works for subcategories.** The Charts API is designed for top-level genres and does not reliably support Apple Music's sub-genre IDs. Many subcategory queries returned zero results. The Search endpoint, using the subcategory label as a search term (e.g., "Indie Rock", "Bossa Nova"), reliably returns albums and ensures the grid is always populated.
- **Simpler view hierarchy.** One view component instead of two. The parent view (`BrowseView`) no longer needs to conditionally show/hide a second bar.
- **Catalog enrichment for reliable metadata.** Charts responses sometimes return albums with incomplete metadata (missing `genreNames`). Batch-enriching via the catalog endpoint after chart fetches ensures consistent genre metadata for display and filtering purposes.

**Alternatives Considered:**
1. **Keep two rows, animate the height change.** Would still cause content shift, just smoothly. The fundamental UX problem (grid moves when filter state changes) remains.
2. **Use Charts API with sub-genre IDs.** Tested and found unreliable -- many sub-genre IDs return empty results from the Charts endpoint. This is an Apple Music API limitation, not a bug in our code.
3. **Client-side filtering of parent genre results.** Fetch all albums for a parent genre via Charts, then filter by `genreNames` to show subcategories. This was attempted but has two problems: (a) chart results are popularity-biased and may not include enough albums tagged with niche subcategories, and (b) it wastes API calls fetching albums that will be filtered out.

**Trade-offs:**
- **Search results are relevance-ranked, not popularity-ranked.** Charts results are ordered by streaming popularity. Search results are ordered by Apple Music's search relevance algorithm, which considers factors beyond popularity. For subcategory browsing, this is arguably better -- it surfaces a wider variety of albums rather than just the most-streamed ones.
- **Search term matching is approximate.** Searching for "Indie Rock" returns albums that Apple Music's search algorithm associates with that term, which may include some tangentially related results. In practice, the results are good enough for genre exploration, and the occasional unexpected album adds to the serendipity.
- **Two different data strategies.** Parent genres use Charts; subcategories use Search. This means the code has two fetch paths, adding some complexity to `BrowseViewModel`. The complexity is contained within the view model and the two paths share the same downstream display logic.

**What would change this:** If Apple added reliable sub-genre support to the Charts endpoint, we could unify both paths back to Charts. Or if the Search endpoint proved insufficient for certain subcategories (returning too few or irrelevant results), we might revisit a hybrid approach combining search with catalog browsing.

---

## ADR-117: Blurred Artwork Background for Album Detail

**Date:** 2026-02-10
**Status:** Accepted

**Context:** The Album Detail screen had a flat, utilitarian appearance -- white background, genre pills, a divider between controls and track list, and no visual connection to the album being viewed. The screen needed a richer, more immersive feel that reinforced the "focused album listening" identity of Crate without adding clutter.

**Decision:** Use a blurred, scaled-up copy of the album artwork as an ambient background layer behind the entire Album Detail view. The view is restructured as a ZStack with three layers: (1) the artwork rendered at 400pt and scaled 3x with 60pt blur, ignoring safe areas; (2) a `systemBackground`-colored dimming overlay at 50% opacity for text readability (reduced from 75% to let more blurred artwork color bleed through the background); (3) the scrollable content on top. Genre pills and the horizontal divider are removed. The play button uses a black background (replacing accent color). Track list typography is bumped from `caption` to `footnote` for artist names and durations. A now-playing indicator (play.fill icon in accent color) replaces the track number for the currently playing track.

**Alternatives Considered:**
1. **Solid gradient background derived from artwork dominant color.** Would require a color extraction step (either at runtime or via a third-party library). More complex, and the blurred artwork approach achieves a similar ambient effect with zero additional dependencies.
2. **Keep genre pills and divider, just add the background.** Tested and found cluttered. The genre information is available on the browse screen; repeating it on the detail screen adds visual noise without adding value to the listening experience.
3. **Use a translucent material (`.ultraThinMaterial`) instead of a color overlay.** SwiftUI materials can produce inconsistent results depending on the artwork colors. A fixed-opacity `systemBackground` overlay provides more predictable contrast across light and dark albums.

**Rationale:**
- The blurred artwork background creates a visual connection between the album art and the full-screen experience, making the detail view feel like it "belongs" to the album rather than being a generic container.
- Removing genre pills and the divider reduces visual clutter. The album detail screen is for listening, not categorization. Genre context is already visible on the browse screen.
- The separate dimming overlay (rather than applying opacity to the blur layer) ensures uniform coverage across the full screen including safe areas, preventing bright artwork from bleeding through unevenly.
- The now-playing indicator in the track list provides immediate visual feedback for which track is currently playing without requiring the user to check the playback footer.
- Changing the play button from accent color to black is a deliberate design choice to make it feel more like a physical control and less like a tappable link.

**Consequences:**
- The ZStack with blur and scale is rendered continuously while the view is visible. On modern devices this is lightweight, but it is worth monitoring for performance on older hardware (iPhone 15 and earlier).
- The dimming overlay opacity was reduced from 75% to 50% to let more album color bleed through the background, creating a richer ambient feel. If specific artwork causes readability issues, this value may need to be increased or made adaptive.
- The `cornerRadius: 0` parameter was added to `AlbumArtworkView` to support the background usage (no rounded corners for a full-bleed background), which means the artwork view now accepts an optional corner radius.

**What would change this:** If the blur layer caused noticeable performance issues on target devices, we would consider pre-rendering a blurred image at a lower resolution instead of using the real-time `.blur()` modifier. Or if the design language evolved toward a more minimal/flat aesthetic, the background could be simplified to a solid color derived from the artwork.

---

## ADR-118: Personalized Genre Feeds with Feedback Loop

**Date:** 2026-02-10
**Status:** Accepted
**Supersedes:** ADR-106 (Local-Only Favorites)
**Refines:** ADR-104 (Charts API for Genre-to-Album Pipeline), ADR-115 (Crate Wall)

**Context:** Genre browsing showed the same chart albums to every user — a flat, paginated list from one source that ran out fast and repeated across sessions. The Crate Wall had a proven multi-signal blending system (5 signals, weighted interleave, CrateDial control), but it only applied to the main wall, not genre feeds. Users also had no way to signal displeasure with album recommendations, and favoriting albums did not influence Apple Music's recommendation algorithm.

**Decision:** Three interconnected changes:

1. **Feedback loop (like/dislike → Apple Music write-back).** Favoriting an album fires three concurrent API calls: (a) `addToLibrary` adds it to the user's Apple Music library, (b) `rateAlbum(.love)` marks it as loved, and (c) `favoriteAlbum` via `POST /v1/me/favorites` marks it with the star icon in Apple Music's cross-platform Favorites system (iOS 17.1+). Running these concurrently avoids user-token expiry between sequential calls. A new dislike button (xmark icon, top-left of album artwork) rates the album as "dislike" in Apple Music and persists to a local `DislikedAlbum` SwiftData model. Like and dislike are mutually exclusive. Disliked albums are filtered from all feeds. All write-back calls use explicit `do/catch` error logging (replacing silent `try?`). This reverses ADR-106 — interactions now write back to Apple Music to train its recommendation algorithm.

2. **Multi-signal genre feeds (GenreFeedService).** Genre browsing now uses 6 blended signals instead of single-source charts:
   - **Personal History:** Heavy rotation + library albums + recently played, filtered to the selected genre
   - **Recommendations:** Apple Music recommendations filtered to genre
   - **Trending:** Chart albums for the genre with randomized offset
   - **New Releases:** New release charts for the genre
   - **Subcategory Rotation:** Random subcategories within the genre for variety
   - **Seed Expansion:** Related albums and artist albums seeded from user's favorited albums in the genre

   Weights follow the CrateDial system (same 5 positions), with a separate `GenreFeedWeights` table tuned for genre context. The weighted interleave algorithm is extracted into a shared `weightedInterleave()` utility used by both `CrateWallService` and `GenreFeedService`.

3. **Enriched Crate Wall.** The main wall's genre extraction now uses heavy rotation and library albums alongside recently played for richer user preference signal. Disliked albums are filtered from wall results.

**Architecture:**

- **DislikedAlbum** (`@Model`): SwiftData model mirroring FavoriteAlbum.
- **DislikeService**: CRUD + `fetchAllDislikedIDs()` for efficient feed filtering.
- **GenreFeedSignal** (enum): 6 signal cases for genre feeds.
- **GenreFeedWeights**: Weight tables per CrateDial position for genre feeds, with `albumCounts(total:)` using largest-remainder method.
- **GenreFeedService**: Parallel fetch → dedup → weighted interleave, scoped to a genre. Takes seed albums from favorites for expansion.
- **WeightedInterleave**: Generic shared function extracted from CrateWallService.
- **MusicService additions**: `addToLibrary()`, `rateAlbum()`, `favoriteAlbum()`, `fetchHeavyRotation()`, `fetchLibraryAlbums()`, `fetchRelatedAlbums()`, `fetchAlbumsByArtist()`.

**New API endpoints used:**
- `PUT /v1/me/ratings/albums/{id}` — rate album as love/dislike
- `POST /v1/me/favorites?ids[albums]={id}` — mark album as Favorite (star icon, cross-platform, iOS 17.1+)
- `GET /v1/me/history/heavy-rotation` — user's heavy rotation
- `GET /v1/me/library/albums` — user's library albums with catalog include
- `MusicCatalogResourceRequest<Album>` with `.relatedAlbums` property — related albums

**Critical build requirement:** All `/v1/me/*` endpoints require `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` to be set in the Xcode build settings. Without these, MusicKit rejects every personalized request with "Missing requesting bundle version." This affects heavy rotation, recently played, recommendations, library albums, ratings, and favorites — essentially the entire personalization layer.

**Rationale:**
- The feedback loop closes the gap between Crate interactions and Apple Music's algorithm. Over time, the user's likes/dislikes improve Apple Music's recommendations, which feed back into Crate's recommendation signal — a virtuous cycle.
- Multi-signal genre feeds eliminate the "same charts for everyone" problem. Two users with different listening histories see different genre feeds, even for the same genre.
- Seed expansion from favorites creates a "more like this" effect without requiring an explicit UI. The more albums a user favorites in a genre, the deeper and more personalized the genre feed becomes.
- Extracting the weighted interleave into a shared utility eliminates code duplication between CrateWallService and GenreFeedService.

**Trade-offs:**
- **More API calls per genre feed.** A blended genre feed makes 8-15 concurrent API calls vs. 1 for the old chart pagination. Apple Music's 20 req/sec limit is sufficient, but on slow connections this may feel slower than the old single-source approach.
- **Write-back is one-directional.** We write to Apple Music (love/dislike), but removing a like/dislike in Crate does not remove the rating in Apple Music. This is deliberate — removing from Apple Music could be destructive if the user also uses the Music app.
- **Seed expansion quality depends on favorites.** A user with no favorites in a genre gets no seed expansion — those slots are redistributed to other signals (subcategory rotation and trending).
- **Reverses ADR-106.** We previously decided not to write to Apple Music to avoid "polluting" the user's library. The product direction has changed — the user explicitly wants Crate interactions to influence Apple Music's algorithm.

**What would change this:** If Apple Music's recommendation API improved to provide genre-scoped recommendations directly, we could simplify the genre feed to lean more heavily on that signal and reduce the number of parallel fetches.

---

## ADR-119: Concurrency Isolation, Error Logging, and Dead Code Removal

**Date:** 2026-02-11
**Status:** Accepted
**Refines:** ADR-102 (MVVM with @Observable), ADR-115 (Crate Wall), ADR-118 (Personalized Genre Feeds with Feedback Loop)

**Context:** After completing the Crate Wall and personalized genre feeds, a review of the codebase revealed several concurrency bugs, silent error swallowing, unnecessary re-renders, duplicated code, and dead code left over from earlier iterations. These were addressed as a single cleanup pass.

**Decision:** Eight targeted changes:

1. **ContentView playback observation isolation.** `ContentView` was reading `playbackViewModel.stateChangeCounter` directly, causing the entire `NavigationStack` to re-render on every playback state change (every second during playback). Extracted a child `PlaybackFooterOverlay` view that owns the `stateChangeCounter` observation, so only the footer re-renders. The parent `ContentView` no longer depends on `PlaybackViewModel`.

2. **`@MainActor` on `fetchSubcategoryAlbums`.** `BrowseViewModel.fetchSubcategoryAlbums` mutates `@Observable` properties (`albums`, `isLoading`) but was not isolated to the main actor, creating a data race. Added `@MainActor` annotation.

3. **Consistent `do/catch` error logging.** All silent `try?` patterns across `CrateWallService`, `GenreFeedService`, `FavoritesService`, and `DislikeService` were replaced with `do/catch` blocks that `print` errors with a `[Crate]` prefix. This ensures API failures and SwiftData save errors are always visible in the Xcode console. Graceful degradation behavior is preserved (functions still return empty arrays or continue on error).

4. **Shared `distributeByWeight()` utility.** Both `CrateDialWeights.albumCounts(total:)` and `GenreFeedWeights.albumCounts(total:)` contained identical largest-remainder implementations for converting fractional weight tables to integer counts. Extracted a generic `distributeByWeight<Key: Hashable>(_:total:)` function into `WeightedInterleave.swift`. Both call sites now delegate to this shared function.

5. **`PlaybackRowContent` extraction.** `BrowseView` contained a 40-line inline playback row (artwork + track info + play/pause) that duplicated `PlaybackFooterView`. Extracted a shared `PlaybackRowContent` view in `PlaybackFooterView.swift`. Both `PlaybackFooterView` and `BrowseView` now use `PlaybackRowContent`, with `PlaybackFooterView` wrapping it in material styling.

6. **Dead code removal.** Deleted three files that were no longer referenced:
   - `GenreService.swift` -- genre browsing logic was absorbed by `BrowseViewModel` and `GenreFeedService` during ADR-118. `BrowseViewModel` no longer depends on `GenreService`.
   - `View+Extensions.swift` -- contained SwiftUI view modifiers that were no longer used after UI refactoring.
   - `MusicKit+Extensions.swift` -- contained MusicKit type extensions that were no longer used.
   The `/Extensions` directory is now empty and removed.

7. **`@Environment(\.displayScale)` for artwork resolution.** `AlbumArtworkView` was hardcoding `2x` (retina) when resolving Apple Music artwork URL templates. Replaced with `@Environment(\.displayScale)` to use the actual device display scale, producing correct pixel sizes on all devices (2x on standard retina, 3x on iPhone Plus/Max/Pro models).

8. **`CrateDialStore` as `@State` on `BrowseView`.** `BrowseView` was creating a new `CrateDialStore()` instance on every render to read the dial label. Changed to `@State private var dialStore = CrateDialStore()` so the instance is created once and persists across re-renders.

**Rationale:**
- The `PlaybackFooterOverlay` isolation is a significant performance fix. During playback, `stateChangeCounter` increments every second. Without isolation, the entire view hierarchy (NavigationStack, BrowseView, genre bar, album grid) was re-rendering every second. With isolation, only the small footer overlay re-renders.
- Replacing `try?` with `do/catch` changes no runtime behavior (all call sites still degrade gracefully) but makes debugging significantly easier. Silent `try?` was the root cause of the "Missing requesting bundle version" issue going undetected for days.
- The `distributeByWeight()` extraction and `PlaybackRowContent` extraction follow the DRY principle. Duplicated code is harder to maintain and easier to accidentally diverge.
- Deleting dead code reduces cognitive overhead for anyone reading the codebase. `GenreService` in particular was confusing because it appeared to be in use but was actually orphaned after ADR-118.

**Consequences:**
- The `/Extensions` directory no longer exists. If future extensions are needed, the directory will need to be recreated.
- The `[Crate]` logging prefix provides a greppable tag for filtering console output during development on physical devices (where system noise is significant).
- `PlaybackRowContent` is now the single source of truth for the playback row UI. Any future changes to the playback row appearance only need to be made in one place.

**What would change this:** These are cleanup and correctness changes with no product-facing trade-offs. They would only be revisited if the architecture changed substantially (e.g., moving to structured concurrency actors instead of `@MainActor` annotation).

---

## ADR-120: Scatter/Fade Grid Transition for Genre Switching

**Date:** 2026-02-11
**Status:** Accepted
**Refines:** ADR-115 (Crate Wall), ADR-116 (Single-Row Transforming Filter Bar)

**Context:** Switching between genres (or between the Crate Wall and a genre feed) caused a jarring visual experience: the album grid was cleared instantly and replaced with a loading state, then the new albums popped in all at once. This happened because `BrowseView` conditionally swapped between two separate content builders (`wallContent` and `genreBrowseContent`) using `@ViewBuilder`, which meant SwiftUI tore down the old grid and rebuilt a new one on every switch. The result felt abrupt and mechanical, especially on fast connections where the loading state flashed briefly.

**Decision:** Replace the conditional view swapping with a single always-mounted `AlbumGridView` and add a coordinated scatter/fade animation managed by a dedicated `GridTransitionCoordinator` state machine. The coordinator orchestrates a four-phase cycle -- exit (old albums scatter out), waiting (scroll resets, API fetch runs concurrently), enter (new albums scatter in), and idle (passthrough, zero overhead).

**Architecture:**

- **GridTransitionCoordinator** (`@Observable`, `@MainActor`): State machine with four phases (`idle`, `exiting`, `waiting`, `entering`). Owns `displayAlbums` and per-item `ItemState` (scale + opacity) during transitions. During `idle`, it holds no data -- the grid reads directly from the view models. The `transition(from:fetch:)` method takes a snapshot of current albums for the exit animation and an async closure for the data fetch, which runs concurrently during the waiting phase. Supports cancellation: rapid genre taps cancel the in-progress transition and start a new one.

- **AnimatedGridItemView**: Thin wrapper around `WallGridItemView` that reads `coordinator.itemStates[index]` via `@Environment`. During idle, returns 1.0 scale / 1.0 opacity (no animation overhead). During transitions, applies the coordinator's per-item scale and opacity.

- **GridTransitionConstants** (`GridTransition` enum): Tuning values for the animation -- scatter item count (16), stagger window (0.4s), per-item duration (0.25s), jitter range, bulk fade duration, easing curves. Centralized so timing can be adjusted without touching the coordinator.

- **BrowseView refactor**: Replaced conditional `@ViewBuilder` (wallContent vs. genreBrowseContent) with a single always-mounted `AlbumGridView` inside a `ZStack`. A `currentAlbums` computed property reads from the coordinator during transitions or from the appropriate view model during idle. Overlay states (loading, error, empty) are layered via ZStack on top of the grid. All genre selection callbacks (`onSelect`, `onHome`, `onToggleSubcategory`) now route through `coordinator.transition(from:fetch:)`.

- **AlbumGridView changes**: Added `ScrollViewReader` with a `scrollToTopTrigger` binding (toggled by the coordinator during the waiting phase). Uses `enumerated()` ForEach to pass item indices to `AnimatedGridItemView`.

- **GenreBarView**: Added `isDisabled` parameter. During transitions, the genre bar is dimmed (60% opacity) and disabled to prevent double-tap race conditions.

**Stagger algorithm:** Items are split into two groups (first 8 and second 8 of the 16 scatter items), then interleaved (A0, B0, A1, B1...) so the animation does not sweep linearly across the grid. Each item's delay includes a small random jitter (0-40ms) to prevent mechanical uniformity. Items beyond the scatter set (16+) receive a single bulk fade for performance.

**Alternatives Considered:**

1. **SwiftUI `.transition()` modifiers on the grid.** SwiftUI's built-in transitions (`.opacity`, `.scale`, `.move`) apply uniformly to the entire view. They cannot stagger individual items, interleave groups, or add per-item jitter. The result would be a simple simultaneous fade, which lacks the "record crate" tactile quality the product aims for.

2. **`matchedGeometryEffect` for shared element transitions.** This would animate individual album tiles from their old positions to new positions. However, the old and new album sets are entirely different (different genre, different albums), so there are no shared elements to match. The effect would not apply.

3. **Keep conditional view swapping, animate the swap.** Wrapping the conditional in a `.transition()` modifier would fade between two separate grids. This still requires SwiftUI to tear down and rebuild the grid identity, which defeats lazy loading optimizations and does not support per-item stagger.

4. **Hero animation (zoom into selected genre pill, expand into grid).** Visually interesting but adds significant complexity and does not map well to the "flip through a crate" metaphor. Deferred for potential future exploration.

**Rationale:**

- The single always-mounted grid means SwiftUI preserves the `LazyVGrid` identity across transitions, maintaining scroll position state and avoiding teardown/rebuild costs.
- The four-phase state machine is explicit and debuggable. Each phase has clear entry/exit conditions, and the phase is observable for UI (spinner during waiting, disabled genre bar during any non-idle phase).
- Cancellation on rapid taps prevents animation pile-up. If the user taps three genres quickly, only the last one completes.
- Zero overhead during idle. The coordinator holds no display data and `AnimatedGridItemView` returns constant 1.0/1.0 values. The `@Observable` property tracking means no re-renders from the coordinator during normal scrolling.
- The `GridTransition` constants enum makes the animation tunable without touching the state machine logic. Adjusting timing, easing, or scatter count is a single-file change.

**Consequences:**

- `BrowseView` no longer has separate `wallContent` and `genreBrowseContent` builders. All grid content flows through the single `currentAlbums` computed property, which checks the coordinator's phase.
- `GridTransitionCoordinator` is injected into the environment (`.environment(coordinator)` on `BrowseView`) so `AnimatedGridItemView` can read it without prop drilling through `AlbumGridView`.
- The animation uses `Task.sleep` for stagger delays, which means it participates in cooperative cancellation. If the task is cancelled mid-animation, items snap to their final state via `resetToIdle()`.
- The 16-item scatter count was chosen because a 2-column grid on iPhone shows roughly 8-10 items in the viewport. Scattering 16 covers the visible area plus a small buffer. Items below the fold get a faster bulk fade since they are not visible.

**What would change this:** If the product direction moved toward a different transition metaphor (e.g., page curl, 3D flip, carousel), the coordinator's phase model would remain but the animation implementation in `AnimatedGridItemView` and the stagger schedule would change. If SwiftUI introduced native per-item stagger transitions in a future release, the custom coordinator could be simplified or replaced.

---

## ADR-121: Now-Playing Progress Bar with Artwork-Derived Gradient

**Date:** 2026-02-11
**Status:** Accepted
**Refines:** ADR-103 (ApplicationMusicPlayer for Playback), ADR-117 (Blurred Artwork Background for Album Detail), ADR-119 (PlaybackRowContent Extraction)

**Context:** The playback footer and BrowseView control bar showed track info and a play/pause button but had no visual indication of track progress. Users had no way to see how far into a song they were or to scrub to a different position. Additionally, the playback UI had no visual connection to the album artwork -- it used generic system colors regardless of the album being played. The Album Detail view's play button also used a hardcoded black background with no connection to the artwork.

**Decision:** Add a scrubbable progress bar filled with a two-color gradient extracted from the current album's artwork. Use a dedicated `ArtworkColorExtractor` service built on pure CoreGraphics/ImageIO (no UIKit/AppKit) for cross-platform color extraction. Position the progress bar as a layout sibling above the playback row (not an overlay) to avoid blocking touch targets. Apply the same extracted colors to the Album Detail view's play button and track list now-playing indicator.

**Architecture:**

- **ArtworkColorExtractor** (`@Observable`, `@MainActor`): Downloads a 40x40 thumbnail of the current artwork, downsamples to a 10x10 pixel grid via CGContext, quantizes pixels into RGB buckets (32-per-channel granularity), and selects the two most prominent colors with a minimum Euclidean distance threshold of 60 to ensure visual contrast. Color scoring uses saturation-cubed weighting (`frequency * saturation^3 * brightnessFloor`) instead of pure frequency, so vivid saturated colors are strongly preferred over whites, grays, pastels, and near-blacks. Buckets with saturation below 0.15 or brightness below 0.12 are filtered out entirely. If all buckets are filtered (e.g., monochrome artwork), scoring falls back to raw frequency. An `rgbToHSB()` helper converts quantized RGB buckets to HSB for the scoring calculations. Results are cached by URL. If no distinct second color exists, one is derived by shifting the first color's brightness. Falls back to semi-transparent white when no artwork is available. Uses `ImageIO` and `CoreGraphics` exclusively -- no UIKit (`UIImage`) or AppKit (`NSImage`) -- so it compiles on both iOS and macOS without `#if os()` branching.

- **PlaybackProgressBar**: A `GeometryReader`-based view that shows a thin (4pt rest / 8pt expanded) progress bar. The filled portion uses a leading-to-trailing `LinearGradient` from the two extracted colors, masked to the current progress width. A `DragGesture` enables scrubbing -- during drag the bar expands with a spring animation and fires a haptic on iOS. On drag end, it calls `PlaybackViewModel.seek(to:)`. Progress is updated via a 0.5s `Timer.publish` to avoid per-frame re-renders. Artwork colors are extracted via `.task(id:)` keyed on the current artwork, so extraction reruns when the track changes and cancels automatically if the artwork changes mid-extraction.

- **PlaybackViewModel additions**: `trackDuration: TimeInterval?` stores the duration of the currently playing track. `currentTracks: MusicItemCollection<Track>?` holds the track collection from the most recent `play(tracks:)` call. `syncTrackDuration()` matches the current queue entry title against `currentTracks` to update `trackDuration` when the player advances to the next track. `seek(to:)` method sets `player.playbackTime` directly.

- **PlaybackFooterView restructure**: The progress bar is placed as a `VStack` sibling above `PlaybackRowContent`, not as an overlay. This ensures the bar does not block tap targets on the playback row.

- **BrowseView changes**: Accepts a `@Binding var navigationPath: NavigationPath` from `ContentView` so the playback row can navigate to the now-playing album's detail view. The progress bar is included in the control bar above the playback row, matching the footer's layout.

- **ContentView changes**: Passes `$navigationPath` to `BrowseView` via binding.

- **PlaybackRowContent self-sufficient observation**: `PlaybackRowContent` now reads `viewModel.stateChangeCounter` directly in its own body, making it self-sufficient for state observation regardless of where it is used. Parent views no longer need to ensure the counter is read upstream.

- **AlbumDetailView color integration**: Uses `ArtworkColorExtractor` to derive colors from the album artwork. The play button background uses the primary extracted color (replacing hardcoded black). The `TrackListView` receives the extracted color as a `tintColor` parameter for the now-playing indicator.

- **TrackListView tintColor parameter**: Accepts an optional `tintColor: Color` parameter (defaulting to `.accentColor`) that controls the color of the now-playing `play.fill` icon. This allows the Album Detail view to pass artwork-derived color while other consumers use the default.

**Alternatives Considered:**

1. **Overlay the progress bar on top of the playback row.** Placing the bar as a thin overlay at the top of the footer would eliminate the need for layout changes. However, overlays can intercept touch events and make the area beneath them harder to tap. A layout sibling is cleaner and avoids accessibility issues.

2. **Use UIKit/AppKit for color extraction (UIImage.getPixelColor, NSImage).** Would require `#if os(iOS)` / `#if os(macOS)` branching. CoreGraphics is available on both platforms identically, so using it directly avoids platform-specific code entirely.

3. **Use a third-party color extraction library (e.g., ColorThief, Chameleon).** Adds a dependency for a task that is straightforward with CoreGraphics pixel sampling. The extraction operates on a 10x10 downsampled image (100 pixels), so performance is not a concern. No external dependency warranted.

4. **Continuous playback time observation via Combine timer.** The progress bar could observe `player.playbackTime` via a Combine publisher firing every frame (~60Hz). A 0.5s `Timer.publish` was chosen instead to avoid unnecessary re-renders. At 4pt bar height, sub-second visual precision is imperceptible.

5. **Extract colors server-side or at cache time.** Would require a server or pre-processing step. Since the extraction downsamples to 10x10 pixels and runs on a 40x40 thumbnail, it completes in milliseconds on-device. No server or pre-computation needed.

**Rationale:**

- The progress bar provides essential playback feedback that was previously missing. Users can see track progress at a glance and scrub to reposition.
- Artwork-derived colors create a visual thread between the album art and the playback UI, reinforcing the "focused album experience" identity. The same color flows through the progress bar gradient, the play button, and the now-playing track indicator.
- Pure CoreGraphics avoids platform branching. `CGImageSourceCreateWithData`, `CGContext`, and `CGImage` are identical on iOS and macOS. No `#if os()` needed anywhere in `ArtworkColorExtractor`.
- Layout stacking (VStack sibling) instead of overlay ensures the progress bar and playback row have independent, non-overlapping touch targets. This is important for the drag gesture on the progress bar, which must not interfere with the play/pause button or the track info tap target below it.
- The 0.5s timer update rate balances smoothness against efficiency. At 4pt bar height, half-second updates produce visually smooth progress. During scrubbing, the bar is driven by the drag gesture position (not the timer), so scrub responsiveness is immediate.
- Caching extracted colors by URL means the same album art is only processed once per session, even if the user navigates away and returns.

**Consequences:**

- `PlaybackViewModel` now stores `trackDuration` and `currentTracks`, adding a small amount of state. The `syncTrackDuration()` method runs on every queue change to keep the duration in sync as the player advances through tracks.
- `BrowseView` now requires a `navigationPath` binding, which changes its initialization signature. `ContentView` passes this binding down.
- `ArtworkColorExtractor` is used in two places: `PlaybackProgressBar` (for the gradient) and `AlbumDetailView` (for the play button and track list tint). Each instance maintains its own cache, which is acceptable since they operate on different artwork (current playing track vs. displayed album).
- The progress bar adds a `Timer.publish` that fires every 0.5s during playback. This is lightweight but means the bar (and only the bar) re-renders twice per second while music is playing.
- The Album Detail play button now uses a dynamic color instead of black. On albums with very light artwork, the primary extracted color may be light, potentially reducing contrast against the white play icon. The brightness-shift fallback in `ArtworkColorExtractor` mitigates this for monochromatic artwork, but multi-color light artwork could still produce a light primary color.

**What would change this:** If the 0.5s timer proved too coarse (e.g., for a larger, more prominent progress bar in a future redesign), we would increase the timer frequency or switch to observing `player.playbackTime` directly. If artwork color extraction needed to support album artwork that is only available as a URL string (not MusicKit `Artwork`), we would add a parallel extraction path that downloads from the URL directly. If Apple introduced a native API for artwork dominant colors (similar to `UIImageColors`), we would adopt it.

---

## ADR-122: Staggered Slide Animation for Genre Bar Pills

**Date:** 2026-02-11
**Status:** Accepted
**Refines:** ADR-120 (Scatter/Fade Grid Transition for Genre Switching), ADR-116 (Single-Row Transforming Filter Bar)

**Context:** The scatter/fade grid transition (ADR-120) animated the album grid when switching genres, but the genre bar pills remained static -- they swapped instantly while the grid below performed its coordinated animation. This created a visual disconnect: the grid had a polished, staggered transition while the filter bar above it jumped abruptly to its new state.

An initial attempt to animate the pills using opacity and scaleEffect failed due to a Liquid Glass compositing limitation in SwiftUI. Views with `.glassEffect()` applied are split into separate compositing layers for the glass capsule and the text/icon content. This layer bifurcation causes two problems: (1) animated opacity is not supported at all on Liquid Glass layers -- setting opacity has no visible effect during animation, and (2) `scaleEffect` only reaches the capsule layer, leaving the text/icon content at its original scale, producing a visual mismatch where the capsule shrinks but the label does not.

**Decision:** Animate genre bar pills using a staggered vertical offset (slide down on exit, slide up on enter) synchronized with the grid transition timing. Apply the offset in two locations per pill -- on the label content (inside the button) and on the view after `.glassEffect()` -- to work around the Liquid Glass layer bifurcation. Use `.clipped()` on the enclosing ScrollView to hide pills when they are offset below the bar's visible area.

**Architecture:**

- **`animateGenreBar` flag on GridTransitionCoordinator**: A boolean property set by the `transition(from:animateGenreBar:fetch:)` call. When `true`, the genre bar participates in the transition animation. When `false` (the default), the genre bar is simply disabled during the transition (dimmed at 60% opacity). Genre-level transitions (selecting a genre from the wall, returning home from a genre) pass `animateGenreBar: true`. Subcategory toggles do not animate the genre bar because the bar content does not change -- only the subcategory selection state changes.

- **GenreBarView stagger animation**: Reads the coordinator from `@Environment`. When `coordinator.phase` changes to `.exiting`, runs `runExitStagger()` which sequentially animates each pill's vertical offset from 0 to 60pt (the `slideDistance`) using the same `GridTransition.staggerWindow` and `GridTransition.exitCurve` timing as the grid. When the phase changes to `.entering`, runs `runEnterStagger()` which reverses the process -- pills start at 60pt offset and stagger back to 0. The stagger step is evenly distributed across the pill count using `GridTransition.staggerWindow / (pillCount - 1)`.

- **Dual offset application**: Each pill button applies `offset(y:)` in two places: (1) on the label content (Text/HStack inside the button, before `.glassEffect()`) and (2) on the outer view (after `.glassEffect()`). This is necessary because Liquid Glass compositing separates the text layer from the capsule layer. A single offset on the outer view would move the capsule but leave the text in place. Applying the same offset to both the label and the post-glass view ensures the entire pill -- text and capsule -- moves together.

- **`.clipped()` on ScrollView**: The genre bar's ScrollView has `.clipped()` applied, which masks any content that extends beyond the ScrollView's frame. When pills are offset downward by 60pt during exit, they slide below the visible bar area and are clipped from view rather than overlapping content below.

- **`pillOffsets` state dictionary**: A `[Int: CGFloat]` dictionary on `GenreBarView` tracks the current vertical offset for each pill by index. The `pillOffset(for:)` helper returns the appropriate offset based on the coordinator's phase: during `exiting`, defaults to 0 (visible) so pills start in place before the stagger slides them down; during `waiting`/`entering`, defaults to `slideDistance` (hidden below) so new pills start hidden before the stagger slides them up; during `idle`, always 0.

**Alternatives Considered:**

1. **Opacity animation on pills.** The natural first choice for show/hide animations. Does not work with Liquid Glass -- opacity changes are not rendered during animation on `.glassEffect()` views. The pills remain fully visible regardless of the opacity value during the animation.

2. **Scale animation on pills.** Another common approach for staggered entrance/exit effects. Partially broken with Liquid Glass -- `scaleEffect` reaches the glass capsule layer but not the text layer, so the capsule shrinks while the text stays at full size. This looks worse than no animation at all.

3. **Transition modifiers (`.transition(.move(edge: .bottom))`) on the pills.** SwiftUI transitions only fire when a view is inserted or removed from the hierarchy. The genre bar pills are not removed -- the bar transforms in place (ADR-116). Transitions would require conditionally removing and re-inserting the entire bar, which conflicts with the single-row design.

4. **No animation on the genre bar.** Acceptable but creates a visual inconsistency -- the grid animates smoothly while the bar above it changes instantly. Since the genre bar and album grid represent the same state change (switching genres), animating both feels more cohesive.

**Rationale:**

- Vertical offset is the one transform that works reliably with Liquid Glass compositing. Unlike opacity (ignored) and scale (partially applied), offset moves the entire compositing stack -- both the glass capsule and the text layer -- because it operates at the layout level rather than the rendering level.
- Applying offset in dual locations (label + post-glass) is a targeted workaround for the layer bifurcation. It is slightly redundant by construction, but it ensures correctness regardless of how SwiftUI distributes the offset across compositing layers.
- The stagger timing reuses `GridTransition.staggerWindow` and the exit/enter curves from `GridTransitionConstants.swift`, so the genre bar animation feels synchronized with the grid scatter without requiring separate tuning constants.
- `.clipped()` is the simplest way to hide offset pills. The alternative would be conditional `opacity(0)` at the offset threshold, but opacity is unreliable with Liquid Glass (the very problem that led to the offset approach).
- The `animateGenreBar` flag keeps subcategory toggles simple. When the user taps a subcategory pill, the genre bar does not change its pill set -- only the selection highlight changes. Animating the bar for subcategory changes would be distracting and unnecessary.

**Consequences:**

- GenreBarView now depends on `GridTransitionCoordinator` via `@Environment`. It was already being passed the `isDisabled` flag from the coordinator's `isTransitioning` property; now it reads the coordinator directly to observe phase changes.
- The dual offset pattern is specific to the Liquid Glass workaround. If Apple fixes Liquid Glass to support animated opacity or uniform scaleEffect in a future SwiftUI release, the dual offset could be simplified to a single transform at the outer level.
- The `staggerTask` on `GenreBarView` is cancellable and self-cleaning. Rapid genre switches cancel the in-progress stagger via `staggerTask?.cancel()` before starting a new one, consistent with the coordinator's cancellation behavior.
- Pills slide 60pt downward during exit. If the genre bar's vertical padding or height changes significantly, `slideDistance` may need to be adjusted to ensure pills are fully hidden when clipped.

**What would change this:** If Apple resolves the Liquid Glass compositing limitations (animated opacity, uniform scaleEffect), the offset-based approach could be replaced with a more conventional opacity or scale animation. The dual-location offset application could also be simplified to a single outer offset. The `animateGenreBar` flag and stagger timing would remain unchanged.

---

## ADR-123: Slide-Up Control Bar on Launch + AlbumCrate Rename

**Date:** 2026-02-12
**Status:** Accepted
**Refines:** ADR-115 (Crate Wall as Default Landing Experience), ADR-116 (Single-Row Transforming Filter Bar)

**Context:** Two changes in this commit:

1. **Control bar launch animation.** The control bar (genre filter pills + playback row) was visible from the moment the app launched, sitting on top of an empty/loading grid while the Crate Wall fetched albums. This created an awkward visual state -- interactive UI chrome sitting over content that was not ready yet. The bar also had a subtle opacity seam at the bottom edge where the material background ended at the safe area boundary, leaving the home indicator region without the frosted material fill.

2. **Display name rename.** The app's display name (the label under the icon on the home screen) was changed from "Crate" to "AlbumCrate" via Xcode's Signing & Capabilities UI.

**Decision:**

1. Hide the control bar during initial wall load using a `@State private var showControlBar = false` boolean. After `wallViewModel.generateWallIfNeeded()` completes (albums are ready), wait 400ms, then animate the bar in with `.spring(duration: 0.5, bounce: 0.15)` using `.transition(.move(edge: .bottom).combined(with: .opacity))`. The result is that albums fill the screen first, then the control bar slides up from the bottom edge with a gentle spring.

2. Extend the control bar's material background into the home indicator safe area by converting `controlBar` from a computed property to a function accepting `bottomSafeArea: CGFloat` from the enclosing `GeometryReader`. Apply `.padding(.bottom, bottomSafeArea)` to the control bar's content so the `.ultraThinMaterial` background stretches to the screen edge, eliminating the opacity seam.

3. Set the display name to "AlbumCrate" via Xcode's UI. This is a build settings change in `project.pbxproj` -- it was done through Xcode, not by hand-editing the file.

**Architecture:**

- **`showControlBar` state on BrowseView**: A boolean defaulting to `false`. The `.task` modifier awaits wall generation, then after a 400ms `Task.sleep` delay, sets `showControlBar = true` inside a `withAnimation` block. The `safeAreaInset(edge: .bottom)` block conditionally renders the control bar only when `showControlBar` is true, with the `.transition(.move(edge: .bottom).combined(with: .opacity))` modifier providing the slide-up + fade-in effect.

- **`controlBar(bottomSafeArea:)` function**: Accepts the bottom safe area inset from the `GeometryReader` that wraps the entire BrowseView body. Applies `.padding(.bottom, bottomSafeArea)` to the VStack content, then `.background(.ultraThinMaterial.opacity(0.85))` covers the full area including the padding, extending the frosted material into the home indicator region.

**Lessons Learned:**

- **Never hand-edit pbxproj for build settings.** The display name change was done through Xcode's UI (Signing & Capabilities). External edits to `project.pbxproj` can cause Xcode to get stuck showing raw XML source instead of the project editor. Build setting changes should always go through Xcode's GUI.

- **`safeAreaInset` content does NOT propagate safe area information to children.** Applying `.ignoresSafeArea(edges: .bottom)` to a background within `safeAreaInset` content has no effect because the content does not know about the safe area it is inset from. The workaround is to read the safe area explicitly via `GeometryReader` and pass the value as explicit padding.

**Alternatives Considered:**

1. **Animate with opacity only (fade in).** A simple fade would work but feels less physical than a slide. The slide-up motion reinforces the "bar docking into place" metaphor and matches the bottom-anchored position of the control bar.

2. **Show the control bar immediately with a loading indicator.** The bar would be visible during wall load, with a spinner or shimmer in the album grid behind it. This was the previous behavior and felt unpolished -- the bar appeared before there was meaningful content to interact with.

3. **Use `.ignoresSafeArea(edges: .bottom)` on the material background.** The natural approach for extending a background into the safe area. Does not work within `safeAreaInset` content because the safe area information is not propagated to the inset view's children. Explicit `GeometryReader` padding is the correct workaround.

**Rationale:**

- Hiding the control bar during load creates a cleaner launch sequence: the screen fills with album art first, then the interactive chrome appears. This directs attention to the content (albums) rather than the controls.
- The 400ms delay after wall load gives the user a moment to register the album grid before the bar slides in. Without the delay, the bar appears simultaneously with the albums, which feels rushed.
- The spring animation (0.5s duration, 0.15 bounce) gives the slide-up a physical, slightly bouncy feel consistent with iOS interaction patterns.
- Extending the material into the safe area eliminates a visible seam between the frosted bar and the unblurred content below it. On devices with a home indicator (iPhone X and later), this seam was particularly noticeable.

**Consequences:**

- The control bar is not interactive during the initial wall load. If the wall takes a long time to load (slow network), the user cannot access genre browsing or settings until the wall completes. This is acceptable because the wall is the default experience and the user has nothing to filter until content is present.
- The `controlBar` is now a function rather than a computed property, which slightly changes the call site syntax but has no functional impact.
- The `GeometryReader` wrapping the BrowseView body was already present for `topInset`; it now also provides `bottomSafeArea` to the control bar, so no additional layout cost.

**What would change this:** If the wall load became significantly slower (e.g., cold start on a poor network connection), we might show the control bar earlier with a skeleton/shimmer state, or show a dedicated loading screen before revealing the browse UI. If Apple fixes `safeAreaInset` to propagate safe area information to its content, the explicit `GeometryReader` padding could be replaced with `.ignoresSafeArea(edges: .bottom)` on the background.

---

## ADR-124: Brand Identity: App Icon, Welcome Screen, and Brand Color

**Date:** 2026-02-12
**Status:** Accepted
**Refines:** ADR-123 (Slide-Up Control Bar on Launch + AlbumCrate Rename)

**Context:** The app had no visual identity -- it used SF Symbols as a placeholder logo, the system default blue accent color, and a generic authorization prompt. With the display name settled as "AlbumCrate" (ADR-123), the app needed a cohesive brand: a recognizable icon, a branded welcome screen, and a consistent accent color replacing the default iOS blue.

**Decision:**

1. **App icon.** A magenta wireframe cube (the "crate") at all required iOS and macOS sizes (16x16 through 1024x1024) in `AppIcon.appiconset`.

2. **Brand color.** Define `brandPink` (#df00b6, magenta) as a static `Color` extension in `AppColors.swift`. Apply it app-wide via `.tint(.brandPink)` on the root view in `CrateApp.swift`. Also set `AccentColor.colorset` to the same value as a fallback for system controls that read accent color directly. Replace all explicit `.accentColor` references in GenreBarView pill text and TrackListView's default `tintColor` with `.brandPink` for consistency.

3. **Welcome screen.** Redesign `AuthView` from a generic authorization prompt into a branded welcome screen: black background, `AlbumCrateLogo` and `AlbumCrateWordmark` image assets centered vertically, "Link to Apple Music" button in brand magenta near the bottom. The view is refactored into extracted subviews (`bottomContent`, `connectButton`, `deniedContent`) for readability.

**Architecture:**

- **`AppColors.swift`**: `brandPink` is a static `ShapeStyle` extension on `Color`, computed from RGB (0.875, 0.0, 0.714). Centralizes the brand color so it can be referenced as `.brandPink` anywhere in the codebase.
- **Root `.tint()` modifier**: Applied on the root view in `CrateApp.swift`, this sets the tint for all child views (buttons, toggles, navigation links, pickers) without requiring per-view overrides. The `AccentColor.colorset` in Assets.xcassets is set to the same value as a belt-and-suspenders fallback.
- **Image assets**: `AlbumCrateLogo.imageset` (128x128 display, @1x/@2x/@3x) and `AlbumCrateWordmark.imageset` (300pt wide, @1x/@2x/@3x) are standard image sets in Assets.xcassets. AuthView references them by name string (`Image("AlbumCrateLogo")`).
- **AuthView refactor**: The single large `body` is split into `bottomContent` (switch on auth status), `connectButton`, and `deniedContent` computed properties. The black background with `.preferredColorScheme(.dark)` ensures the welcome screen is always dark regardless of system appearance.

**Alternatives Considered:**

1. **Use `AccentColor.colorset` only (no `.tint()` or explicit `.brandPink` references).** The asset catalog accent color works for many system controls, but not all views read it -- particularly custom text styling in GenreBarView pills. The explicit `.brandPink` references ensure consistent color everywhere.

2. **Define brand color in asset catalog only (no Swift constant).** Asset catalog colors require `Color("name")` string lookups, which are not compile-time checked. A static Swift extension is type-safe and autocompletes in Xcode.

3. **Keep the welcome screen minimal (just a button).** The welcome screen is the user's first impression. A branded experience with logo and wordmark establishes identity before the user even sees album content.

**Rationale:**

- A single brand color applied via root `.tint()` creates visual consistency across all interactive elements (buttons, toggles, navigation) with one line of code, rather than per-view overrides.
- The welcome screen is the only view the user sees before authorizing Apple Music. Making it branded and polished sets expectations for the rest of the app.
- Defining the color as a Swift static extension (`.brandPink`) rather than only an asset catalog entry gives compile-time safety and Xcode autocompletion.
- The app icon (magenta wireframe cube) reinforces the "crate" metaphor and uses the brand color, creating a consistent identity from the home screen through the welcome screen into the app.

**Consequences:**

- All UI elements that previously used the default blue accent color now appear in brand magenta. Any new interactive elements added in the future will automatically pick up the brand color via the root `.tint()` modifier.
- Views that need a different tint (e.g., artwork-derived colors in AlbumDetailView) must explicitly override the tint, which they already do.
- The `AuthView` now forces dark mode via `.preferredColorScheme(.dark)`. This is intentional for the welcome screen but does not affect the rest of the app (ContentView does not set a preferred color scheme).

**What would change this:** If the brand identity evolves (different color, different logo), the changes are centralized: `AppColors.swift` for the color, Assets.xcassets for the icon and image assets, and `AuthView` for the welcome screen layout. No scatter across the codebase.

---

## ADR-125: Typed Navigation Path, Scrubber Relocation, and Footer Progress Toggle

**Date:** 2026-02-12
**Status:** Accepted
**Refines:** ADR-121 (Now-Playing Progress Bar with Artwork-Derived Gradient), ADR-119 (ContentView Playback Observation Isolation)

**Context:** Three related issues prompted this change:

1. **Duplicate navigation.** `NavigationPath` is type-erased, making it impossible to inspect its contents. `PlaybackFooterOverlay.navigateToNowPlaying()` could push the same album onto the stack multiple times because there was no way to check whether the album was already at the top. Users tapping the footer while already viewing the now-playing album would stack duplicate detail views.

2. **Footer scrubber was too small for reliable interaction.** The `PlaybackProgressBar` in the footer provided a 4pt-to-8pt drag target. On a mini-player row that competes with the play/pause button and track info tap target, the scrubber was difficult to hit consistently. The footer's primary job is showing progress at a glance and navigating to the album -- not precise scrubbing.

3. **Duplicate progress bars.** When viewing the now-playing album's detail page, the footer progress bar was visible simultaneously with whatever progress UI appeared on the detail view. Two bars tracking the same playback felt redundant and cluttered.

**Decision:**

1. **Replace `NavigationPath` with a typed `[CrateAlbum]` array** in `ContentView` and `BrowseView`. This makes the path inspectable so `PlaybackFooterOverlay.navigateToNowPlaying()` can guard against pushing the same album by checking `navigationPath.last?.id`.

2. **Create a dedicated `PlaybackScrubber` component** (`Crate/Views/Playback/PlaybackScrubber.swift`) and place it in `AlbumDetailView` between the transport controls and the track list. The scrubber uses the same artwork-derived gradient from `ArtworkColorExtractor` with rounded corners, a 54pt touch target height, and 6-to-12px visual height expansion on touch for tactile feedback. It only appears when the user is viewing the currently-playing album (`isPlayingThisAlbum`).

3. **Make the footer progress bar visual-only.** Remove the `DragGesture` from `PlaybackProgressBar` so it serves purely as a non-interactive progress indicator. Scrubbing is now exclusively available on the Album Detail view where there is ample space.

4. **Add a `showProgressBar` parameter to `PlaybackFooterView`** (defaults to `true`). When `AlbumDetailView` detects it is showing the now-playing album, the footer hides its progress bar to avoid the duplicate-bar problem.

5. **Animate the scrubber appearance** with `.transition(.opacity)` and `.animation(.easeInOut(duration: 0.35))` scoped to `isPlayingThisAlbum`, so the scrubber fades in smoothly when the user navigates to the now-playing album.

**Architecture:**

- **Typed navigation path**: `ContentView` declares `@State private var navigationPath: [CrateAlbum] = []` instead of `NavigationPath()`. The `NavigationStack(path:)` binding uses this typed array. `BrowseView` accepts `@Binding var navigationPath: [CrateAlbum]`. `PlaybackFooterOverlay.navigateToNowPlaying()` checks `navigationPath.last?.id == album.id` before appending, preventing duplicate pushes.

- **PlaybackScrubber** (`Crate/Views/Playback/PlaybackScrubber.swift`): A standalone view that accepts `PlaybackViewModel` and `ArtworkColorExtractor` and renders a scrub-capable progress bar. Uses `DragGesture` with a 54pt frame height for reliable touch targeting. The visual bar expands from 6pt to 12pt during active scrubbing with a spring animation. The gradient fill uses the same two-color artwork-derived gradient as the footer progress bar. On drag end, calls `PlaybackViewModel.seek(to:)`. Placed in `AlbumDetailView` between the transport controls row and `TrackListView`.

- **PlaybackProgressBar simplification**: The `DragGesture`, scrub state (`isScrubbing`, `scrubProgress`), and haptic feedback code are removed from `PlaybackProgressBar`. It retains the gradient fill, 0.5s timer-driven progress updates, and artwork color extraction -- it simply no longer responds to touch.

- **PlaybackFooterView `showProgressBar` parameter**: `PlaybackFooterView` accepts `showProgressBar: Bool = true`. When `false`, the `PlaybackProgressBar` is omitted from the VStack. `AlbumDetailView` (via `PlaybackFooterOverlay` or the parent view) passes `showProgressBar: false` when `isPlayingThisAlbum` is true.

- **Scrubber animation**: The scrubber is wrapped in an `if isPlayingThisAlbum` conditional with `.transition(.opacity)` and `.animation(.easeInOut(duration: 0.35), value: isPlayingThisAlbum)`. This produces a smooth fade-in when the user navigates to the now-playing album and a fade-out when they navigate away.

**Alternatives Considered:**

1. **Keep `NavigationPath` and maintain a separate shadow array for dedup.** Would work but adds a parallel data structure that must be kept in sync with the actual navigation state. A typed array eliminates the need for a shadow copy -- the path itself is the source of truth.

2. **Keep scrubbing in the footer but increase the touch target.** Expanding the footer's drag area would conflict with the play/pause button and track info row. The footer is spatially constrained. Moving scrubbing to the detail view provides a dedicated, full-width interaction area.

3. **Always show the footer progress bar, even on the now-playing album page.** The two bars track identical progress and create visual noise. Hiding the footer bar when the detail scrubber is visible keeps the UI clean.

4. **Use `matchedGeometryEffect` to morph the footer bar into the detail scrubber.** Visually interesting but adds significant complexity for a transition the user may not even notice. The simple hide/show approach is pragmatic.

**Rationale:**

- A typed `[CrateAlbum]` array provides compile-time safety and inspectability that `NavigationPath` cannot. The only trade-off is that the path can only contain `CrateAlbum` values, which is the only navigation destination in the app. If additional destination types are needed in the future, a typed enum can replace the array.
- Relocating the scrubber to the Album Detail view gives it a full-width interaction area (minus side padding) instead of competing with the footer's compact layout. The 54pt touch target meets Apple's Human Interface Guidelines minimum of 44pt with room to spare.
- Making the footer bar visual-only simplifies its implementation (no gesture handling, no scrub state) and clarifies its role: a progress-at-a-glance indicator, not an interaction surface.
- The `showProgressBar` parameter is a minimal API change that keeps `PlaybackFooterView` reusable. Callers that do not pass the parameter get the default behavior (bar visible).
- The 0.35s ease-in-out animation for scrubber appearance is subtle enough not to delay interaction but visible enough to signal the transition from "viewing an album" to "viewing the now-playing album."

**Consequences:**

- `NavigationPath` is no longer used anywhere. All navigation is through the typed `[CrateAlbum]` array. If the app later needs to navigate to non-album destinations (e.g., artist pages, playlists), the path type would need to change to an enum or `NavigationPath` would need to be reintroduced.
- `PlaybackProgressBar` no longer handles touch. Any code that expected the footer bar to be scrubbable will find it is now display-only.
- `PlaybackScrubber` is a new file that must be added to both iOS and macOS build phases in the Xcode project.
- The footer progress bar is conditionally hidden on the now-playing album's detail page. If the user navigates to a different album's detail page while music is playing, the footer bar remains visible (since the detail view's scrubber only appears for the currently-playing album).
- `BrowseView` now receives `@Binding var navigationPath: [CrateAlbum]` instead of `@Binding var navigationPath: NavigationPath`, which changes its initialization signature.

**What would change this:** If the app introduced additional navigation destinations (artist pages, playlist views), the typed `[CrateAlbum]` array would need to become either an enum-based typed array or revert to `NavigationPath` with a separate dedup mechanism. If Apple improved `NavigationPath` to support content inspection in a future SwiftUI release, the typed array could be replaced. If user feedback indicated that scrubbing in the footer was important (e.g., for quick scrubbing without opening the detail view), a larger footer scrub target could be reconsidered.

---

## ADR-126: Codebase Audit — MainActor Isolation, Guard Hardening, macOS Build Fix, Test Coverage, and Concurrency Cleanup

**Date:** 2026-02-12
**Status:** Accepted
**Refines:** ADR-102 (MVVM with @Observable), ADR-111 (XCTest + Swift Testing for Test Strategy), ADR-118 (Personalized Genre Feeds with Feedback Loop), ADR-119 (Concurrency Isolation, Error Logging, and Dead Code Removal)

**Context:** A systematic audit of the codebase after the Crate Wall, genre feeds, and playback scrubber features were complete revealed five categories of issues: incomplete concurrency isolation on view models, unconfigured-ModelContext guards that silently no-oped, a broken macOS build, thin test coverage, and remaining silent error patterns. These were addressed as five sequential commits.

**Decision:** Five targeted changes:

1. **`@MainActor` on all `@Observable` view model classes.** `BrowseViewModel`, `AlbumDetailViewModel`, `CrateWallViewModel`, `PlaybackViewModel`, and `AuthViewModel` were annotated with `@MainActor` at the class level. This ensures all property mutations (which drive SwiftUI view updates) occur on the main thread, eliminating data races. With class-level isolation in place, 12 redundant per-method `@MainActor` annotations were removed. `BrowseViewModelTests` was updated to use `@MainActor` on its test struct to match the new isolation.

2. **`assertionFailure()` in ModelContext guard blocks.** `FavoritesService` and `DislikeService` each have `guard let ctx = modelContext else { return }` guards at the top of every method (8 guards total). These guards exist because the services are initialized with `nil` context and must have `configure(modelContext:)` called before use. In the previous state, if `configure()` was never called, all SwiftData operations silently did nothing -- a subtle bug that would be very difficult to trace. Added `assertionFailure("[Crate] modelContext is nil — did you forget to call configure()?")` inside each guard's else block. This crashes in DEBUG builds, making the misconfiguration immediately obvious during development, while remaining a safe no-op in production (RELEASE builds).

3. **macOS build errors resolved.** Three platform-specific issues were preventing the macOS target from compiling:
   - `Color(.systemBackground)` in `AlbumDetailView` -- `UIColor.systemBackground` is iOS-only. Replaced with `#if os(iOS) Color(.systemBackground) #else Color(nsColor: .windowBackgroundColor) #endif`.
   - `MusicLibrary.shared.add()` in `MusicService` -- `MusicLibrary` is iOS-only. Wrapped the call in `#if os(iOS)`.
   - `.toolbar(.hidden, for: .navigationBar)` in `BrowseView` -- `.navigationBar` toolbar placement is iOS-only. Wrapped in `#if os(iOS)`.

4. **MockMusicService and expanded test coverage.** Created `MockMusicService` -- a configurable mock implementing `MusicServiceProtocol` that returns preset albums, tracks, and error states. Used it to expand test coverage:
   - `CrateWallServiceTests` (new, 3 tests): validates wall generation, empty-signal handling, and dislike filtering.
   - `BrowseViewModelTests` (expanded from 2 stub tests to 4 real tests): validates album loading via mock, empty state handling, genre selection, and subcategory search using `MockMusicService`.
   - Fixed the macOS test target's `project.pbxproj` entries -- `DislikeServiceTests` and `FeedbackLoopTests` were missing from the macOS Sources build phase.

5. **Parallelized subcategory search and error logging.** `BrowseViewModel.fetchSubcategoryAlbums()` was calling the search API sequentially in a for-loop across subcategory terms. Replaced with `withThrowingTaskGroup` so all subcategory searches run concurrently, reducing latency proportionally to the number of terms. Also replaced 2 silent `try?` patterns in `GenreFeedService` with `do/catch` blocks using `[Crate]`-prefixed logging. Added `[Crate]`-prefixed URL construction failure logging to all 8 `guard let url` blocks in `MusicService` that previously failed silently.

**Rationale:**

- **Class-level `@MainActor`** is the idiomatic Swift concurrency pattern for `@Observable` view models. Per-method annotations are error-prone (easy to forget on a new method) and redundant when the entire class should be main-actor-isolated. The 12 removed annotations were all on methods already inheriting class-level isolation.

- **`assertionFailure` in guards** follows the "crash early in development, degrade gracefully in production" principle. The `configure()` pattern is a known footgun -- views must remember to call it in `.task`. A DEBUG crash at the guard makes the mistake obvious immediately, rather than manifesting as "favorites don't save" hours later. In production, the existing silent no-op behavior is preserved to avoid crashes for end users.

- **macOS build fix** is straightforward platform correctness. The iOS-only APIs were introduced during rapid feature development when testing was focused on the iOS target. The `#if os()` conditionals follow the existing codebase pattern established by `ArtworkColorExtractor` (which already uses pure CoreGraphics to avoid platform branching).

- **MockMusicService** enables real unit testing of business logic. The previous `BrowseViewModelTests` had 2 tests that used a minimal stub returning empty arrays -- they verified the test infrastructure worked but did not exercise meaningful behavior. With a configurable mock, tests can validate actual data flow (loading states, genre filtering, dislike exclusion, wall generation).

- **Parallelized subcategory search** is a straightforward concurrency improvement. The sequential for-loop was an accidental bottleneck -- there was no data dependency between subcategory term searches, so running them concurrently is strictly better. The `withThrowingTaskGroup` pattern collects results as they arrive and handles errors per-task.

- **Eliminating remaining `try?` patterns** completes the work started in ADR-119. Every `try` in the codebase now uses `do/catch` with `[Crate]`-prefixed logging, making the error logging policy fully consistent.

**Consequences:**

- All `@Observable` view models are now `@MainActor`-isolated. Any new methods added to these classes automatically inherit main-actor isolation. Non-main-actor work (e.g., background data processing) must be explicitly dispatched with `Task.detached` or `nonisolated` methods.
- `FavoritesService` and `DislikeService` will crash in DEBUG if `configure(modelContext:)` is not called before use. This is intentional. Developers working on new views that use these services will see the crash immediately if they forget the configuration step.
- The macOS target now compiles. It should be periodically built to catch future iOS-only API introductions early.
- `MockMusicService` is available in `CrateTests/` for all future test files. It supports configurable albums, tracks, chart results, search results, and error injection.
- `CrateWallServiceTests` and the expanded `BrowseViewModelTests` provide regression coverage for the wall generation and browse flows. Future changes to these areas will be caught by tests.
- Subcategory search is now faster, especially for genres with many subcategory terms. The trade-off is slightly higher peak concurrency (multiple simultaneous API calls instead of sequential), which is well within Apple Music's rate limit of ~20 requests/second.
- There are no remaining `try?` patterns in the codebase. All error paths are logged with `[Crate]` prefix.

**What would change this:** If Swift introduced a better pattern for "configure after init" (e.g., if SwiftData's `@ModelContext` macro could be used in services), the `assertionFailure` guards could be removed in favor of compile-time safety. If Apple Music's rate limit became a concern, the parallel subcategory search could be throttled with a semaphore or limited task group concurrency. If the project adopted a dependency injection framework, `MockMusicService` could be replaced by the framework's mocking utilities.

---

## ADR-127: Radio Selection for Crate Dial and Standardized Spinners

**Date:** 2026-02-12
**Status:** Accepted
**Refines:** ADR-115 (Crate Wall as Default Landing Experience), ADR-124 (Brand Identity: App Icon, Welcome Screen, and Brand Color)

**Context:** Two UX issues prompted this change:

1. **Slider was imprecise for 5 discrete positions.** The Crate Dial used a continuous `Slider` mapped to 5 discrete positions (My Crate, Curated, Mixed Crate, Deep Dig, Mystery Crate). Users had to drag to approximate positions and the UI converted the continuous value to discrete snap points. The slider obscured the available options -- users could not see all 5 positions at once, read their descriptions, or tap directly to a specific position. A debounce timer (1s) was required to avoid regenerating the wall during drag, adding latency to selection.

2. **Spinners were inconsistent.** The 5 `ProgressView` instances across the app (AuthView x2, BrowseView, AlbumGridView, LoadingView) used different styles -- some were `.tint(.white)` with `.scaleEffect(1.5)`, others used system defaults. This created visual inconsistency and did not align with the brand identity established in ADR-124.

**Decision:**

1. **Replace the Slider with a radio selection list.** SettingsView now renders all 5 `CrateDialPosition.allCases` as tappable rows in a `ForEach`. Each row shows a filled/empty circle indicator (brandPink when selected, secondary when not) alongside the position's title and description. Selection immediately updates `CrateDialStore.position` and fires `onDialChanged` -- no debounce needed since tapping is a discrete action. A `@State selectedPosition` drives the UI because `CrateDialStore` is not `@Observable`. The section title was renamed from "Crate Dial" to "Crate Algorithm Settings" with spectrum labels ("My Personal Taste" at top, "Mystery Selections" at bottom) framing the radio list.

2. **Expand the settings sheet.** The `.presentationDetents` on BrowseView changed from `.medium` to `.large` to accommodate the 5 radio rows with descriptions, which do not fit in a half-sheet.

3. **Rename diagnostics toggle.** The toggle label changed from "Show Feed Diagnostics" / "Hide Diagnostics" to "Show Algorithm Settings" / "Hide Algorithm Settings" for consistency with the new section title.

4. **Bump FeedDiagnosticsView font sizes.** All font sizes in FeedDiagnosticsView were increased one level for readability: `subheadline` to `body` for labels, `caption` to `subheadline` for values, `caption2` to `caption` for tertiary text.

5. **Standardize all ProgressView spinners.** All 5 `ProgressView` instances across the app (AuthView x2, BrowseView, AlbumGridView, LoadingView) now use `.tint(.brandPink)` at the system default size. Removed `.tint(.white)` and `.scaleEffect(1.5)` overrides.

**Alternatives Considered:**

1. **Keep the Slider with better labels.** Adding tick marks or position labels around the slider would improve discoverability, but a slider is fundamentally the wrong control for 5 discrete options. Sliders communicate "continuous range" to users. A radio list communicates "pick one of these options" -- which is the actual interaction.

2. **Segmented picker (`Picker` with `.segmentedStyle()`).** Compact and tappable, but 5 segments with text labels would be too cramped on iPhone. The labels would be truncated or require abbreviation, losing the descriptions that help users understand each position.

3. **Menu picker (`Picker` with `.menuStyle()`).** Hides the options behind a dropdown, requiring a tap to reveal them. The radio list shows all options simultaneously, making the spectrum from "My Personal Taste" to "Mystery Selections" visible at a glance.

**Rationale:**

- A radio list makes all 5 positions visible simultaneously, with titles and descriptions. Users can immediately understand the full spectrum of options and tap directly to their preferred position. This is a better mapping for discrete selection than a continuous slider.
- Removing the debounce timer eliminates the 1-second lag between selection and wall regeneration. Tapping a radio row is inherently discrete, so no debounce is needed.
- Standardizing spinners to brandPink completes the brand color rollout from ADR-124. The root `.tint()` modifier does not reach `ProgressView` in all contexts (e.g., when inside sheets or overlays with their own tint), so explicit `.tint(.brandPink)` on each `ProgressView` ensures consistency.
- The font size bump in FeedDiagnosticsView improves readability of the debug panel, which previously used caption-sized text that was difficult to read on smaller devices.
- Renaming from "Feed Diagnostics" to "Algorithm Settings" in the toggle label aligns with the new "Crate Algorithm Settings" section title and uses language that is more meaningful to non-developers.

**Consequences:**

- The `sliderValue` state, `debounceTask`, and `onAppear` sync logic are removed from SettingsView. The view is simpler -- `@State selectedPosition` and `CrateDialStore` are the only state.
- The settings sheet is now full-height (`.large`) on iOS. Users scroll if needed, but the radio list with 5 options, spectrum labels, and diagnostics toggle fits comfortably.
- Wall regeneration is now immediate on radio tap rather than debounced by 1 second. If the wall generation API is slow, the user sees the loading state immediately after tapping.
- All spinners across the app now share the same appearance. Any new `ProgressView` added in the future should include `.tint(.brandPink)` for consistency (the root tint may not propagate to all contexts).

**What would change this:** If additional dial positions were added (more than 5), the radio list could become too long and a different control might be warranted (e.g., a picker wheel or segmented control with a separate description area). If `CrateDialStore` became `@Observable`, the `@State selectedPosition` workaround could be removed in favor of direct observation.

---

## ADR-128: Artist Catalog View with Typed Navigation Destinations

**Date:** 2026-02-12
**Status:** Accepted
**Refines:** ADR-125 (Typed Navigation Path, Scrubber Relocation, and Footer Progress Toggle)

**Context:** Two related needs motivated this change:

1. **Artist discovery from Album Detail.** When a user is viewing an album and wants to explore more of the artist's work, they had no in-app path. The only option was to leave Crate entirely and find the artist in the Apple Music app. For an album-focused listening experience, browsing an artist's full discography is a natural next step.

2. **Navigation path supported only one destination type.** The NavigationStack used a `[CrateAlbum]` path array (ADR-125), which worked when the only destination was album detail. Adding artist catalog as a second destination type required a more flexible navigation model -- the path needed to support heterogeneous destination types.

**Decision:**

1. **Introduce `CrateDestination` enum for typed navigation.** Replace the `[CrateAlbum]` navigation path with `[CrateDestination]`, where `CrateDestination` is an enum with cases `.album(CrateAlbum)` and `.artist(name: String, albumID: MusicItemID)`. This supports multiple destination types in a single NavigationStack while keeping the path inspectable (not type-erased).

2. **Add artist catalog view.** `ArtistCatalogView` displays a full-bleed grid of all albums by an artist, sorted oldest-first (chronological discography order). It reuses `AlbumGridView` for the grid layout. `ArtistCatalogViewModel` handles the two-step fetch: resolve the artist ID from the album, then fetch all albums by that artist.

3. **Add two new MusicService methods.** `fetchArtistID(forAlbumID:)` uses `MusicCatalogResourceRequest<Album>` with the `.artists` relationship property to resolve the artist. `fetchArtistAlbums(artistID:)` uses `MusicDataRequest` against `/v1/catalog/{storefront}/artists/{id}/albums` with a limit of 100. Both are on the `MusicServiceProtocol`, so they are mockable in tests.

4. **Wire artist navigation from AlbumDetailView.** The artist name text in AlbumDetailView is wrapped in a `NavigationLink(value: .artist(...))`, making it tappable. BrowseView's `.navigationDestination(for: CrateDestination.self)` switches on the enum to route to either `AlbumDetailView` or `ArtistCatalogView`.

**Alternatives Considered:**

1. **Type-erased `NavigationPath`.** SwiftUI provides `NavigationPath` as a type-erased heterogeneous path. This would avoid the enum but loses inspectability -- the footer overlay's duplicate-push guard (`navigationPath.last`) needs to pattern-match on the path to check if the user is already viewing the now-playing album. Type erasure would prevent this check.

2. **Separate NavigationStack for artist browsing.** Presenting the artist catalog in a sheet or a secondary NavigationStack. This would keep the path type simple but break the navigation metaphor -- users expect to push/pop within a single stack, not jump between stacks. It would also prevent navigating from an artist catalog album into that album's detail view using the same back stack.

3. **AnyHashable wrapper.** Wrapping different destination types in `AnyHashable` and using multiple `.navigationDestination(for:)` modifiers. This is more fragile and less readable than a single enum with pattern matching.

**Rationale:**

- The `CrateDestination` enum is the standard SwiftUI pattern for multi-destination NavigationStacks. It keeps the path typed and inspectable while supporting any number of destination types in the future (e.g., playlist, search results).
- Oldest-first sorting matches how discographies are conventionally presented (chronological order). Users scanning an artist's catalog want to see the progression from early work to recent releases.
- The two-step fetch (album -> artist ID -> artist albums) is necessary because the navigation originates from an album context, not an artist context. MusicKit's `MusicCatalogResourceRequest` with `.artists` relationship is the correct way to resolve the artist from an album.
- Reusing `AlbumGridView` in `ArtistCatalogView` maintains visual consistency with the rest of the app and avoids duplicating grid layout code.

**Consequences:**

- The navigation path type changed from `[CrateAlbum]` to `[CrateDestination]` in ContentView, PlaybackFooterOverlay, and BrowseView. All `navigationPath.append()` and `navigationPath.last` call sites now use the enum (e.g., `.append(.album(album))`, `case .album(let a) = navigationPath.last`).
- `AlbumGridView`'s NavigationLink values changed from raw `CrateAlbum` to `CrateDestination.album(album)`.
- Adding future navigation destinations (e.g., a playlist view, a search result detail) requires only adding a new case to `CrateDestination` and a corresponding `case` in BrowseView's `navigationDestination` switch.
- `ArtistCatalogViewModel` follows the established pattern: `@MainActor @Observable`, error handling with `[Crate]`-prefixed logging, `MusicServiceProtocol` dependency injection.
- The artist albums endpoint returns up to 100 albums per request. For artists with very large catalogs (100+ albums), pagination would need to be added. This is sufficient for the vast majority of artists.

**What would change this:** If we needed more destination types frequently, a protocol-based approach (each destination type conforms to a `Routable` protocol) might scale better than a growing enum. But for 2-3 destination types, the enum is simpler and more readable. If artist catalogs needed richer features (filtering by album type, sorting options), `ArtistCatalogView` would evolve but the navigation architecture would remain the same.

---

*End of Decision Records*
