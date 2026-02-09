# Architectural Decision Records -- Crate

This document captures key architectural decisions for Crate, with context and rationale. Decisions are numbered and dated. If a decision is revisited, the original is preserved and the revision is appended.

**Note:** ADRs 001-014 (Spotify/Next.js era) were superseded on 2026-02-09 by a full platform pivot from Spotify Web to Apple Music Native. The original ADRs are archived in git history. This file now contains the Apple Music / MusicKit / SwiftUI decisions starting at ADR-100.

For the architecture overview, see [Section 7 of the PRD](./Spotify%20Album%20UI%20Redesign.md#7-architecture-and-technical-decisions).

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
| 106 | [Local-Only Favorites (Not Apple Music Library)](#adr-106-local-only-favorites-not-apple-music-library) | Accepted |
| 107 | [Genre Taxonomy as Static Swift Configuration](#adr-107-genre-taxonomy-as-static-swift-configuration) | Accepted |
| 108 | [No Server / No Backend for MVP](#adr-108-no-server--no-backend-for-mvp) | Accepted |
| 109 | [iOS 17+ and macOS 14+ Minimum Deployment Targets](#adr-109-ios-17-and-macos-14-minimum-deployment-targets) | Accepted |
| 110 | [Multiplatform Xcode Project with Shared Code](#adr-110-multiplatform-xcode-project-with-shared-code) | Accepted |
| 111 | [XCTest + Swift Testing for Test Strategy](#adr-111-xctest--swift-testing-for-test-strategy) | Accepted |
| 112 | [App Store + TestFlight for Distribution](#adr-112-app-store--testflight-for-distribution) | Accepted |
| 113 | [In-Memory View Model Cache (No Multi-Layer Caching)](#adr-113-in-memory-view-model-cache-no-multi-layer-caching) | Accepted |
| 114 | [Album-Sequential Playback with No Shuffle](#adr-114-album-sequential-playback-with-no-shuffle) | Accepted |

---

## ADR-100: Platform Pivot: Native SwiftUI over Next.js Web

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-001 (Next.js + React + Tailwind CSS for Frontend), ADR-011 (Vercel for Deployment)
**PRD Reference:** [Section 6.3 (Platform)](./Spotify%20Album%20UI%20Redesign.md#63-platform), [Section 7.1 (Tech Stack)](./Spotify%20Album%20UI%20Redesign.md#71-tech-stack)

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
**PRD Reference:** [Section 7.1 (Tech Stack)](./Spotify%20Album%20UI%20Redesign.md#71-tech-stack), [Section 7.2 (Genre-to-Album Pipeline)](./Spotify%20Album%20UI%20Redesign.md#72-genre-to-album-pipeline-apple-music-charts)

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

**Decision:** MVVM using the `@Observable` macro (Observation framework). Four view models: `AuthViewModel`, `BrowseViewModel`, `AlbumDetailViewModel`, `PlaybackViewModel`.

**Rationale:**
- `@Observable` is Apple's recommended approach as of iOS 17. It is the direction the platform is heading.
- Automatic fine-grained tracking means views only re-render when the specific properties they read change. This is critical for the playback footer, which updates a progress bar every second -- with `ObservableObject`, every view reading any property from the playback model would re-render on every tick. With `@Observable`, only the progress bar re-renders.
- MVVM maps naturally to SwiftUI's view/model separation. ViewModels own the business logic. Views are purely declarative UI.
- TCA was considered and rejected. It introduces significant complexity (reducers, effects, stores, dependencies) that is not warranted for an app with three views and a straightforward data flow. TCA shines in apps with complex state interactions and large teams. Crate is neither.
- The app's state is genuinely simple: genre selection, a list of albums, playback state, favorites. No complex state machines, no multi-step workflows, no offline/online sync. MVVM with `@Observable` handles this cleanly.

**Trade-offs:**
- Requires iOS 17+ / macOS 14+. This is already our minimum target (see ADR-109), so no additional cost.
- `@Observable` is newer and some edge cases may be less well-documented than `ObservableObject`. In practice, for our simple state model, this is low risk.
- No unidirectional data flow enforcement. If the app grew significantly more complex, we might miss TCA's structure. But the PRD explicitly limits the app to three views with no settings, no modes, no complex workflows. The simplicity is a feature, not a limitation.

**What would change this:** If the app grew to 10+ views with complex shared state and multi-step workflows (e.g., social features, playlists, user profiles), we would revisit TCA. The PRD's design philosophy makes this unlikely.

---

## ADR-103: ApplicationMusicPlayer for Playback

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-009 (Spotify Web Playback SDK), ADR-010 (Mobile Playback via Spotify Connect Fallback)
**PRD Reference:** [Section 3.4 (Playback Footer)](./Spotify%20Album%20UI%20Redesign.md#34-playback-footer), [Section 7.4 (Playback Architecture)](./Spotify%20Album%20UI%20Redesign.md#74-playback-architecture)

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
**PRD Reference:** [Section 7.2 (Genre-to-Album Pipeline)](./Spotify%20Album%20UI%20Redesign.md#72-genre-to-album-pipeline-apple-music-charts)

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
**PRD Reference:** [Section 7.7 (Favorites)](./Spotify%20Album%20UI%20Redesign.md#77-favorites)

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
- Future: listening history, user preferences, cached genre data

**Trade-offs:**
- Adds a persistence layer that the Spotify architecture did not need. This is a small amount of additional complexity, but it is well-justified by the favorites feature and the benefits of owning data locally.
- SwiftData is newer (introduced WWDC 2023) and has had some rough edges in early releases. As of iOS 17.2+ / macOS 14.2+, it is stable for our use case.
- If the data model needs to change (migration), SwiftData handles lightweight migrations automatically. Complex migrations would require more effort, but our model is simple enough that this is unlikely.

**What would change this:** If we decided favorites should sync with Apple Music's library (see ADR-106 for why we chose not to), we would not need SwiftData for MVP. But even then, SwiftData is useful for future features (history, preferences).

---

## ADR-106: Local-Only Favorites (Not Apple Music Library)

**Date:** 2026-02-09
**Status:** Accepted
**Supersedes:** ADR-007 (Favorites Stored in Spotify's Library)
**PRD Reference:** [Section 3.5 (Favorites)](./Spotify%20Album%20UI%20Redesign.md#35-favorites), [Section 7.7 (Favorites)](./Spotify%20Album%20UI%20Redesign.md#77-favorites)

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
**PRD Reference:** [Section 2.2 (Structure)](./Spotify%20Album%20UI%20Redesign.md#22-structure), [Section 7.8 (Genre Taxonomy Storage)](./Spotify%20Album%20UI%20Redesign.md#78-genre-taxonomy-storage)

**Context:** The Spotify architecture stored the genre taxonomy as a JSON file validated at build time with Zod. For the native app, we need to decide how to store and validate the taxonomy.

**Decision:** Store the taxonomy as a Swift source file (`Genres.swift`) containing typed struct instances. No JSON. No runtime parsing.

**Rationale:**
- The Swift compiler validates the taxonomy at compile time. Typos in genre IDs, missing fields, or structural errors are caught before the app ever runs. This is strictly stronger than Zod validation at build time, because it is the same language and toolchain -- no separate validation step.
- Swift structs are type-safe. An `appleMusicGenreIDs` field is an array of strings. You cannot accidentally put an integer in it. With JSON, a missing quote or wrong type is a runtime error.
- No parsing overhead at app launch. The data is compiled into the binary.
- The taxonomy is small (15 categories, ~100 sub-categories) and changes infrequently. A Swift file is the simplest representation with the strongest guarantees.

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
**PRD Reference:** [Section 6.4 (No Server / No Backend)](./Spotify%20Album%20UI%20Redesign.md#64-no-server--no-backend)

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
- **Unit tests (Swift Testing):** `MusicService` (API call construction and response parsing), `BrowseViewModel` (genre selection logic, pagination), `GenreTaxonomy` (taxonomy structure validation), `FavoritesService` (CRUD operations).
- **UI tests (XCTest/XCUITest):** Browse flow (select genre -> see albums), album detail flow (tap album -> see detail), playback flow (tap play -> footer appears).
- **Note:** MusicKit does not work in the Simulator. Unit tests that mock the MusicKit layer can run in the Simulator. Integration tests and UI tests that require actual MusicKit playback must run on physical devices.

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
**PRD Reference:** [Section 3.4 (Playback Footer)](./Spotify%20Album%20UI%20Redesign.md#34-playback-footer), [Section 8 (Design Principles)](./Spotify%20Album%20UI%20Redesign.md#8-design-principles)

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

*End of Decision Records*
