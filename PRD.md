# PRODUCT REQUIREMENTS DOCUMENT

# Crate
*The Album Listening Experience*

---

| | |
|---|---|
| **Version** | 1.0 -- MVP |
| **Date** | February 9, 2026 |
| **Status** | Draft -- Architecture Complete (MusicKit Pivot) |
| **Author** | Product Management |
| **Architecture** | Engineering Architecture |
| **Audience** | Engineering, Design, Leadership |

---

## Table of Contents

1. [Overview](#1-overview)
2. [Genre Taxonomy](#2-genre-taxonomy)
3. [User Experience](#3-user-experience)
4. [Information Architecture](#4-information-architecture)
5. [MVP Scope](#5-mvp-scope)
6. [Technical Considerations](#6-technical-considerations)
7. [Architecture and Technical Decisions](#7-architecture-and-technical-decisions)
8. [Design Principles](#8-design-principles)
9. [Open Questions](#9-open-questions)

---

## 1. Overview

### 1.1 Problem Statement

Modern music streaming applications have optimized for playlist consumption, algorithmic recommendations, and engagement metrics at the expense of the album listening experience. The result is an interface that overwhelms users with choices, buries albums beneath layers of navigation, and fragments the intentional, start-to-finish listening session that albums are designed to deliver.

Users describe the experience of opening their streaming app as anxiety-inducing. The paradox of choice is real: dozens of navigation paths, auto-generated playlists, podcast suggestions, social features, and promotional content compete for attention before a user ever reaches an album. For listeners who value the album as an art form, the current experience is hostile to their intent.

### 1.2 Product Vision

**Crate** recreates the experience of thumbing through a vinyl collection at home or discovering albums in a record store bin. It is a single-purpose native app built on Apple Music that strips away everything except album discovery and album listening. When you open Crate, you see records. You browse. You pick one. You listen.

The product philosophy is radical simplicity. No playlists. No podcasts. No algorithmic feeds. No social features. Just albums, organized by genre, presented as cover art, played start to finish.

### 1.3 Target User

Music listeners who respect the album as a complete artistic statement. These users are frustrated by the fragmentation of modern streaming interfaces and want a focused, intentional listening experience. They may be vinyl collectors, audiophiles, or simply people who remember what it felt like to put on a record and listen to the whole thing.

### 1.4 Success Metrics

- Average session length and albums played per session
- Percentage of albums listened to completion (full album play-through rate)
- Return usage (daily/weekly active users)
- User-reported satisfaction with the browsing and discovery experience

---

## 2. Genre Taxonomy

### 2.1 Design Philosophy

The genre taxonomy is the backbone of Crate. It replaces free-text search and algorithmic recommendations with a structured, human-curated browsing hierarchy inspired by *musicmap.info*'s genealogical approach to popular music genres. The goal is to make the entire universe of popular music navigable through two taps: a top-level category and one or more sub-categories.

### 2.2 Structure

The taxonomy is a two-tier tree. Apple Music has its own hierarchical genre system with stable numeric IDs. The mapping strategy:

1. **Start with Apple Music's genre hierarchy.** Fetch the full genre list via `GET /v1/catalog/{storefront}/genres` and examine the parent-child relationships.
2. **Evaluate whether Apple's structure maps directly to our desired Tier 1 / Tier 2 layout.** If Apple's top-level genres align well, we can use them directly (or with minor relabeling) rather than building an entirely custom taxonomy. This would mean genre lists auto-update as Apple adds genres.
3. **If a custom mapping is needed,** group Apple Music genre IDs into logical sub-categories based on musical lineage, shared characteristics, and listener mental models. These become the second-tier selections (Tier 2). Roll sub-categories up into top-level super-genres inspired by musicmap's framework. These become the first-tier horizontal navigation (Tier 1).

The organizing principle is musicmap's concept of super-genres as large, intuitive family groupings, with sub-genres nested beneath as more specific entry points. The taxonomy should feel natural to a music fan browsing a well-organized record store, where sections are clearly labeled but not so granular that you need a map to find anything.

### 2.3 Proposed Top-Level Categories (Tier 1)

The following super-genre categories are proposed as the Tier 1 horizontal navigation. These are derived from musicmap's super-genre framework, consolidated to a navigable set of approximately 12-15 top-level entries. Final naming and grouping will be refined during design, but the intent is:

| Super-Genre              | Contains (Example Sub-Categories)                                     |
|--------------------------|-----------------------------------------------------------------------|
| Rock                     | Classic Rock, Indie/Alternative, Punk, Grunge, Psychedelic, Progressive, Hard Rock |
| Metal                    | Heavy Metal, Black Metal, Death Metal, Metalcore, Grindcore           |
| Pop                      | Pop, Indie Pop, Synth-Pop, Power Pop, Electropop, Dance Pop          |
| Hip-Hop / Rap            | Hip-Hop, Old School, Trap, Conscious, Boom Bap                       |
| R&B / Soul               | R&B, Soul, Funk, Neo-Soul, Gospel                                    |
| Jazz                     | Jazz, Bebop, Fusion, Smooth Jazz, Acid Jazz                          |
| Blues                    | Blues, Delta Blues, Chicago Blues, Blues Rock                           |
| Electronic / Dance       | House, Techno, Trance, EDM, Deep House, Minimal Techno, IDM         |
| Breakbeat / Bass         | Drum & Bass, Breakbeat, Dubstep, UK Garage, Trip-Hop                |
| Country                  | Country, Honky-Tonk, Bluegrass, Americana, Outlaw Country            |
| Reggae / Caribbean       | Reggae, Dancehall, Dub, Ska, Reggaeton                               |
| Latin / Brazilian        | Latin, Salsa, Bossa Nova, Samba, Tango, MPB                         |
| Folk / Acoustic          | Folk, Singer-Songwriter, Acoustic, Indie Folk                        |
| Classical / Ambient      | Classical, Opera, Ambient, New Age, Downtempo                        |
| World / Global           | World Music, Afrobeat, Indian, K-Pop, J-Pop, Cantopop, Mandopop     |

**Note:** This mapping is illustrative. Apple Music has a more conservative genre taxonomy (roughly 20-30 top-level genres) compared to the hundreds of micro-genres on some platforms. Our sub-categories may map to the same Apple Music genre ID in some cases, producing identical results. This should be validated during the taxonomy mapping task by fetching Apple Music's full genre hierarchy and testing the overlap. Apple Music's own genre structure may be close enough to use directly with minimal customization -- see [ADR-107](./DECISIONS.md#adr-107-genre-taxonomy-as-static-swift-configuration) and Open Question N1 in Section 9.

---

## 3. User Experience

### 3.1 Authentication

Crate requires an active Apple Music subscription. On first launch, the app presents the system MusicKit authorization dialog -- a single tap to grant access. There is no browser redirect, no OAuth flow, no login form. The user taps "Allow," and the system handles everything. Authorization persists until the user revokes it in Settings.

If the user does not have an Apple Music subscription, the app checks via `MusicSubscription.current` and can present Apple's built-in `MusicSubscriptionOffer` view, which provides a native subscription signup flow directly in the app.

There is no browse-only or free-tier mode. Once authorized and subscribed, the user proceeds directly to the main browse view.

### 3.2 Main Browse View

This is the core screen of the application. It consists of three elements stacked vertically:

#### Tier 1: Super-Genre Bar

- Horizontal scrolling list of top-level genre categories, pinned to the top of the viewport.
- Single-select. Tapping a category loads its sub-categories in Tier 2.
- Includes a **Favorites** option as the first item in the list, which displays the user's saved/favorited albums.
- Clean, minimal text labels. No icons. The aesthetic is restrained and typographic.

#### Tier 2: Sub-Category Bar

- Appears below Tier 1 when a super-genre is selected.
- Horizontal scrolling list of sub-categories within the selected super-genre.
- **Multi-select.** Users can tap multiple sub-categories to broaden the results. Tapping a selected sub-category deselects it.
- Selections immediately update the album grid below.

#### Album Grid

- A tiled grid of album cover art. This is the dominant visual element of the application.
- Covers fill the available width in a responsive grid (e.g., 3 columns on iPhone, 4-5 on iPad, 5-7+ on a macOS window). The grid uses adaptive `GridItem` sizing to adjust column count automatically based on available width.
- Infinite scroll. As the user scrolls down, more albums load continuously.
- **Sort order: Popularity.** Albums are ranked by Apple Music chart position within the selected genre. Future iterations may offer a toggle between popularity and randomized/shuffled order to create a more serendipitous "crate digging" feel.
- Album art only. No text overlay on the grid tiles. The visual experience should feel like looking at a wall of records.
- Scroll position is preserved when navigating to an album detail view and returning (handled automatically by SwiftUI's `NavigationStack`).

### 3.3 Album Detail View

Tapping an album cover transitions to a full-screen album detail view. Layout (mobile/narrow viewport):

- **Album art** displayed prominently at the top, as large as the viewport allows.
- **Album title and artist name** below the art.
- **Play button** that begins playback from track 1.
- **Favorite/save button** to add the album to the user's favorites collection within Crate (stored locally via SwiftData; does not modify the user's Apple Music library).
- **Track list** showing track number, track name, and duration. Tapping any individual track begins playback from that track.
- Back navigation returns to the browse grid with scroll position preserved.

### 3.4 Playback Footer

A persistent mini-player footer is visible across all views whenever audio is playing. It includes:

- Album art thumbnail, track title, and artist name for the currently playing track.
- Play/pause, previous track, next track controls.
- Progress bar / scrubber.
- The footer persists while the user continues browsing the album grid or viewing other album details.

Playback is powered by `ApplicationMusicPlayer`, which owns an independent playback queue separate from the system Music app. Background audio on iOS works automatically with the Audio background mode entitlement. Lock screen controls and Control Center / Now Playing integration are provided by the system automatically -- no manual `MPRemoteCommandCenter` or `MPNowPlayingInfoCenter` configuration is needed.

**Volume:** On iOS, volume is controlled by the system (hardware buttons or `MPVolumeView`). On macOS, users control volume via keyboard volume keys or the system volume slider. MusicKit does not provide app-level volume control -- this is a platform constraint, not a Crate limitation.

**No shuffle button.** Shuffle is deliberately excluded. Crate is an album listening experience. Tracks play in album order. This is a product decision, not an oversight. See [ADR-114](./DECISIONS.md#adr-114-album-sequential-playback-with-no-shuffle).

### 3.5 Favorites

Users can favorite albums from the album detail view. Favorited albums are accessible by selecting "Favorites" in the Tier 1 super-genre bar. Favorites are displayed in the same album grid format.

Favorites are stored locally on-device using SwiftData. They are **not** synced to the user's Apple Music library. "Favorite in Crate" and "Add to Apple Music Library" are different intents, and Crate should not modify the user's library without explicit action. This means favoriting is instant, works offline, and requires no network calls. See [ADR-106](./DECISIONS.md#adr-106-local-only-favorites-not-apple-music-library).

Cross-device sync (iPhone to Mac) is possible via CloudKit, which SwiftData supports natively. This is out of scope for MVP but architecturally cheap to add later. See Open Question N5 in Section 9.

---

## 4. Information Architecture

The application has exactly three views:

| View         | Purpose                                 | Navigation                                      |
|--------------|-----------------------------------------|-------------------------------------------------|
| Auth         | MusicKit authorization + subscription check | Automatic transition to Browse on success     |
| Browse       | Genre selection + album grid            | Tap album -> Album Detail                       |
| Album Detail | Art, metadata, tracklist, playback      | Back -> Browse (scroll preserved)               |

That's it. Three views. No settings page, no profile page, no social features, no search bar, no sidebar navigation. The entire app is: browse, pick, listen.

---

## 5. MVP Scope

### 5.1 In Scope

- MusicKit authorization with Apple Music subscription check
- Two-tier genre taxonomy (super-genres -> sub-genres)
- Album grid populated by genre selection via Apple Music Charts API, sorted by chart position (popularity)
- Infinite scroll on the album grid
- Album detail view with art, metadata, and track list
- Full playback via `ApplicationMusicPlayer`: play/pause, prev/next, scrubber
- Background audio with lock screen / Control Center integration (iOS) and Now Playing integration (macOS)
- Persistent playback footer across all views
- Favorite albums (local SwiftData persistence) and a Favorites view in the genre bar
- Scroll position preservation on back navigation
- iOS and macOS targets from a single multiplatform codebase (SwiftUI)

### 5.2 Out of Scope (Future Iterations)

- **Search.** Free-text album or artist search. Planned as a fast-follow if the browse-only experience validates well.
- **Randomized grid sort.** A toggle to switch the album grid from popularity-ranked to randomized order for a more serendipitous browsing feel.
- **iCloud sync for favorites.** Cross-device favorites sync via CloudKit. SwiftData supports this natively with minimal code changes.
- **Deep catalog browsing.** Search-based supplementary results for genres with sparse chart data, to surface older or less popular albums.
- **Social features.** Sharing albums, seeing what friends are listening to.
- **Listening history / recently played.** A view showing albums the user has recently listened to.
- **Editorial curation.** Staff picks, featured albums, new release spotlights.
- **Add to Apple Music Library.** An explicit action to add an album to the user's Apple Music library (separate from Crate favorites).

---

## 6. Technical Considerations

This section captures platform constraints and requirements identified during product planning. Detailed architectural decisions that address each of these items are documented in Section 7 and in [DECISIONS.md](./DECISIONS.md).

### 6.1 Apple Music API Considerations

- The **Apple Music Catalog Charts endpoint** (`GET /v1/catalog/{storefront}/charts?types=albums&genre={genreID}`) is the primary data source for the album grid. It returns albums directly by genre, sorted by popularity. This is dramatically simpler than the multi-step pipeline that would be required on other platforms. See Section 7.2 for the full pipeline.
- **Charts data reflects recent popularity, not all-time catalog depth.** The charts endpoint returns what people are listening to now, which biases toward newer and more popular albums. Deep catalog cuts may not appear unless they are currently popular. For MVP, current popular is the right default.
- **Apple Music rate limits** are approximately 20 requests per second per user token. Given that the genre pipeline requires only 1 API call per page of results, rate limits are nearly a non-issue. Defensive measures (debounce on rapid genre switching, retry on 429) are still implemented. See Section 7.5.
- **Genre granularity** is limited to Apple Music's taxonomy (roughly 20-30 top-level genres). Some sub-categories in our taxonomy may map to the same Apple Music genre ID, producing identical results. This needs validation during taxonomy mapping.
- **No Simulator support for MusicKit.** MusicKit playback and subscription checks do not work in the iOS Simulator. All testing that involves MusicKit must run on a physical device with an active Apple Music subscription. Unit tests that mock the MusicKit layer can still run in the Simulator. See Section 7.11.

### 6.2 Genre Taxonomy Implementation

- The two-tier taxonomy (Section 2) is a static configuration defined as a Swift source file (`Genres.swift`) containing typed struct instances. No JSON. No runtime parsing. Validated at compile time by the Swift compiler. See Section 7.8 and [ADR-107](./DECISIONS.md#adr-107-genre-taxonomy-as-static-swift-configuration).
- Each terminal node in the taxonomy maps to one or more Apple Music genre IDs (integers).
- Apple Music's own genre hierarchy may be suitable to use directly for Tier 1 / Tier 2 with minimal custom mapping. This should be validated during implementation. See Open Question N1.

### 6.3 Platform

- Native SwiftUI multiplatform application targeting iOS and macOS from a single codebase.
- Estimated 95%+ shared code between platforms. Platform-specific code is limited to: background audio entitlement (iOS), menu bar commands and keyboard shortcuts (macOS), window sizing (macOS).
- Minimum deployment targets: iOS 17.0, macOS 14.0 (Sonoma). Required for `@Observable`, SwiftData, and latest MusicKit APIs. See [ADR-109](./DECISIONS.md#adr-109-ios-17-and-macos-14-minimum-deployment-targets).

### 6.4 No Server / No Backend

MusicKit handles authentication, API access, and playback entirely on-device. There is no client secret to protect, no OAuth redirect to handle, no API proxy to build. The developer token is embedded in the app binary via the MusicKit entitlement (Apple generates it from the provisioning profile). The entire app is fully client-side. See [ADR-108](./DECISIONS.md#adr-108-no-server--no-backend-for-mvp).

---

## 7. Architecture and Technical Decisions

*Added 2026-02-09 by Architecture. Full decision rationale in [DECISIONS.md](./DECISIONS.md). This section was rewritten during the platform pivot from Spotify/Next.js to Apple Music/MusicKit/SwiftUI.*

### 7.1 Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Platform** | SwiftUI Multiplatform (iOS + macOS) | Single codebase, native performance on both targets. MusicKit is a first-party Swift framework -- no web wrappers, no bridging. |
| **Architecture Pattern** | MVVM with `@Observable` (iOS 17+ / macOS 14+) | Apple's recommended pattern for SwiftUI. The `@Observable` macro provides automatic fine-grained tracking -- views only re-render when the specific properties they read change. Critical for the playback footer updating a progress bar every second. |
| **Music Integration** | MusicKit (Swift framework) | Direct genre browsing via charts, native playback with `ApplicationMusicPlayer`, system-level auth. No API proxy layer needed. |
| **Playback** | `ApplicationMusicPlayer` | Owns its own playback queue independent of the system Music app. Automatic Now Playing / lock screen integration on both iOS and macOS. Background audio on iOS with the Audio entitlement. |
| **Networking / API** | MusicKit Swift types + Apple Music API (via `MusicDataRequest` for direct REST calls) | MusicKit provides native Swift types for most catalog operations. For charts with genre filtering, `MusicDataRequest` handles auth headers automatically. |
| **Local Persistence** | SwiftData | Favorites storage and any future user preferences. Lightweight, built into SwiftUI, works on both iOS and macOS. |
| **Image Caching** | Built-in (`AsyncImage` + URL cache) | MusicKit's `Artwork` type provides URLs at any resolution. `AsyncImage` with the system URL cache handles caching automatically. |
| **Validation** | Swift type system (compile-time) | Static genre taxonomy is a Swift file, validated by the compiler. No runtime validation framework needed. |
| **Testing** | XCTest + Swift Testing | XCTest for UI tests. Swift Testing (Xcode 16+) for unit tests -- more expressive assertions, parameterized tests. |
| **Deployment** | App Store (iOS) + Mac App Store (macOS) | Native distribution. TestFlight for beta testing. |
| **CI/CD** | Xcode Cloud | Free tier includes 25 compute hours/month. Builds, tests, and distributes to TestFlight automatically. |

**Why no server / backend?** MusicKit handles authentication, API access, and playback entirely on-device. The developer token is embedded in the app binary (via the MusicKit entitlement). There is no client secret to protect, no OAuth redirect to handle, no API proxy to build. The entire server-side layer is eliminated. See [ADR-108](./DECISIONS.md#adr-108-no-server--no-backend-for-mvp).

**Why SwiftData instead of "no database"?** Favorites need to be stored somewhere. Writing to the user's Apple Music library would pollute their personal collection. Local-only favorites via SwiftData provides clean separation -- the user's Apple Music library stays untouched. SwiftData also supports CloudKit sync with minimal additional code if we later want cross-device favorites. See [ADR-105](./DECISIONS.md#adr-105-swiftdata-for-local-persistence) and [ADR-106](./DECISIONS.md#adr-106-local-only-favorites-not-apple-music-library).

### 7.2 Genre-to-Album Pipeline (Apple Music Charts)

This is dramatically simpler than what other platforms require. Apple Music has a direct path from genre to albums via the Catalog Charts endpoint.

**The pipeline:**

```
User selects "Rock" (Tier 1)
  --> User selects "Indie / Alternative" (Tier 2)
        |
        v
Taxonomy lookup: Apple Music genre IDs = [20]  (Alternative genre ID)
        |
        v
GET /v1/catalog/{storefront}/charts?types=albums&genre=20&limit=50&offset=0
        |
        v
Returns: Array of Album objects, sorted by popularity (most-played)
        |
        v
Display in grid. On scroll, increment offset for next page.
```

**For multi-select sub-categories:** When a user selects multiple sub-categories, we use OR (union) logic. Each selected sub-category may map to a different genre ID. We fetch charts for each genre ID and merge the results, deduplicating by album ID. For a single sub-category selection (the common case), this is one API call. For multi-select, it is N calls where N is the number of distinct genre IDs.

**MusicKit implementation:** The charts endpoint is accessible via `MusicDataRequest` for direct REST access with full control over the genre parameter and pagination. `MusicDataRequest` handles auth headers automatically.

**Storefront:** Determined automatically from the user's Apple Music account region. MusicKit provides this via `MusicDataRequest.currentCountryCode`.

**Key advantages over alternative approaches:**

- One API call per page of results (not 20+)
- No server-side aggregation needed
- Albums returned are already deduplicated
- Standard pagination with limit/offset parameters
- Albums are ranked by popularity (most-played) within the genre, matching the PRD's requirement

**Supplementary strategy for sparse genres:** Some niche genres may have limited chart data. If a genre query returns fewer results than expected, we can supplement with `MusicCatalogSearchRequest` using genre-related search terms. This is a fallback, not the primary path.

**Risk:** Charts data reflects recent popularity, not all-time catalog depth. Deep catalog cuts from the 1970s may not appear unless they are currently popular. This is a trade-off between "current popular" and "deep catalog." For MVP, current popular is the right default. Deep catalog exploration could be added later via search.

### 7.3 Authentication and Authorization

MusicKit authorization is radically simpler than typical OAuth flows.

**Flow:**

```
App launch
    |
    v
Check MusicAuthorization.currentStatus
    |
    +--> .authorized --> Check subscription --> Proceed to Browse
    |
    +--> .notDetermined --> Call MusicAuthorization.request()
    |        |
    |        v
    |     System dialog: "Crate would like to access Apple Music"
    |        |
    |        +--> User grants --> Check subscription --> Proceed to Browse
    |        +--> User denies --> Show explanation, link to Settings
    |
    +--> .denied / .restricted --> Show explanation, link to Settings
```

There is no browser redirect. No callback URL. No token exchange. No cookie management. The user taps "Allow" once, and the system handles everything. Authorization persists until the user revokes it in Settings.

**Token management:** In native iOS/macOS apps using MusicKit Swift, you do **not** manually generate or manage developer tokens. The MusicKit entitlement in the provisioning profile handles this automatically. The Music User Token is also handled automatically by MusicKit at the system level. There is nothing to store, refresh, or rotate.

**Subscription check:** After authorization, check `MusicSubscription.current` to verify the user has an active Apple Music subscription:

```swift
let subscription = try await MusicSubscription.current
if subscription.canPlayCatalogContent {
    // Proceed to Browse
} else {
    // Show subscription required message
    // Optionally present MusicSubscriptionOffer view
}
```

Apple provides a built-in `MusicSubscriptionOffer` view that presents the Apple Music subscription signup flow directly in the app.

### 7.4 Playback Architecture

**Player choice:** `ApplicationMusicPlayer` (not `SystemMusicPlayer`). This gives Crate its own independent playback queue that does not interfere with whatever the user had playing in the system Music app. See [ADR-103](./DECISIONS.md#adr-103-applicationmusicplayer-for-playback).

**Album playback:**

```swift
let player = ApplicationMusicPlayer.shared

// Play album from track 1
let tracks = try await album.with(.tracks)
player.queue = ApplicationMusicPlayer.Queue(for: tracks.tracks ?? [])
player.state.shuffleMode = .off  // enforce album-sequential playback
try await player.play()

// Play from specific track
player.queue = ApplicationMusicPlayer.Queue(for: tracks.tracks ?? [], startingAt: selectedTrack)
player.state.shuffleMode = .off
try await player.play()
```

**Transport controls:** Direct method calls on the shared player instance: `play()`, `pause()`, `skipToNextEntry()`, `skipToPreviousEntry()`, and `playbackTime = newTime` for seeking.

**Background audio (iOS):** Requires `UIBackgroundModes` -> `audio` in the iOS target's Info.plist. With `ApplicationMusicPlayer`, background audio works automatically once this entitlement is set. Lock screen and Control Center controls are provided by the system automatically.

**macOS playback:** `ApplicationMusicPlayer` works identically on macOS. No platform-specific code needed. macOS handles Now Playing integration via system media controls (menu bar, keyboard media keys).

**Playback state observation:** The `PlaybackViewModel` observes `ApplicationMusicPlayer.shared` state:
- `player.state.playbackStatus` -- playing, paused, stopped
- `player.queue.currentEntry` -- current track info
- `player.playbackTime` -- current position (for the scrubber)

### 7.5 Caching and Rate Limits

**Rate limit context:** Apple Music API allows approximately 20 requests per second per user token. With 1 API call per page of results, rate limits are essentially a non-issue.

**Defensive measures:**

1. **Debounce rapid genre switching.** If a user taps through genres quickly, cancel in-flight requests and only execute the final selection. Use Swift's `Task` cancellation.
2. **Retry on 429.** If a rate limit is hit, read the `Retry-After` header and wait before retrying.
3. **In-memory cache in the view model.** Cache chart results keyed by genre ID + page. If the user switches away from a genre and comes back, serve from cache. No expiry within a session -- chart rankings do not change fast enough to warrant mid-session invalidation.

**For album artwork:** `AsyncImage` with the system URL cache handles artwork caching automatically. If artwork loading proves too slow on scroll, a dedicated image cache library (Kingfisher, Nuke) can be added. Test the system cache first. See [ADR-113](./DECISIONS.md#adr-113-in-memory-view-model-cache-no-multi-layer-caching).

No server-side caching layer is needed because there is no server.

### 7.6 Infinite Scroll and Pagination

**Apple Music API pagination:** The charts endpoint supports `limit` (max 50 per request) and `offset` parameters. Standard offset-based pagination.

**Client-side implementation:**

- SwiftUI's `LazyVGrid` for the album grid. It handles view recycling automatically (only renders visible cells).
- Detect scroll-to-bottom using a sentinel view with `.onAppear` at the end of the grid.
- When the sentinel appears, the `BrowseViewModel` fetches the next page by incrementing the offset.
- Page size: 50 albums (the API maximum per request) to minimize network calls.
- Results accumulate in the view model's `albums` array. SwiftUI diffs efficiently.

**Depth limit:** Apple does not document an explicit offset cap for the charts endpoint. This should be tested empirically. A reasonable maximum of 500 albums per genre is more than sufficient for a browsing product. See Open Question N2.

### 7.7 Favorites

**Decision:** Favorites are stored locally via SwiftData. They are not synced with the user's Apple Music library. See [ADR-106](./DECISIONS.md#adr-106-local-only-favorites-not-apple-music-library).

**Data model:**

```swift
@Model
class FavoriteAlbum {
    var albumID: String          // Apple Music catalog ID
    var title: String
    var artistName: String
    var artworkURL: String?      // URL template for artwork
    var dateAdded: Date
}
```

We store enough data to render the album in the favorites grid without an API call. The full album detail (tracklist, etc.) is fetched on demand when the user taps into it.

**Loading the Favorites view:** Query SwiftData for all `FavoriteAlbum` objects, sorted by `dateAdded` (most recent first). Display in the same album grid format as genre results.

**Checking favorite state:** On the album detail view, query SwiftData for a `FavoriteAlbum` with the matching `albumID` to determine whether to show the favorited or unfavorited state.

**Future cloud sync:** SwiftData supports CloudKit integration. If we want favorites to sync across iPhone and Mac, we enable it with minimal code changes. Out of scope for MVP.

### 7.8 Genre Taxonomy Storage

**Format:** Static Swift source file at `Crate/Config/Genres.swift` containing typed struct instances. No JSON. No runtime parsing. Validated at compile time by the Swift compiler. See [ADR-107](./DECISIONS.md#adr-107-genre-taxonomy-as-static-swift-configuration).

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
    let appleMusicGenreIDs: [String]  // Apple Music genre ID(s)
}

let genreTaxonomy: [GenreCategory] = [
    GenreCategory(
        id: "rock",
        label: "Rock",
        subCategories: [
            SubCategory(id: "alternative", label: "Alternative", appleMusicGenreIDs: ["20"]),
            SubCategory(id: "classic-rock", label: "Classic Rock", appleMusicGenreIDs: ["21"]),
            // ...
        ]
    ),
    // ...
]
```

This file is the single source of truth for what genres exist in the app and how they map to Apple Music genre IDs. Updating it requires a code change and app update, which is appropriate for something that changes infrequently.

**Open question:** Apple Music's own genre hierarchy may be close enough to use directly. If so, we could dynamically fetch the genre tree from the API and reduce or eliminate the static file. This should be validated during implementation. See Open Question N1.

### 7.9 Client-Side State (@Observable View Models)

Four view models using the `@Observable` macro (Observation framework):

| View Model | Owned By | Scope | State |
|---|---|---|---|
| `AuthViewModel` | `CrateApp` (app root) | App lifetime | Authorization status, subscription status |
| `PlaybackViewModel` | `CrateApp` (app root) | App lifetime -- playback persists across navigation | Current track, play/pause, progress, queue |
| `BrowseViewModel` | `BrowseView` via `@State` | Persists while in navigation stack | Selected super-genre, selected sub-categories, loaded album pages per genre key, scroll position |
| `AlbumDetailViewModel` | `AlbumDetailView` | Transient, created per album | Album metadata, tracks, favorite state |

`AuthViewModel` and `PlaybackViewModel` are injected via `.environment()` from the app root because they need to be accessible everywhere. `BrowseViewModel` is owned by `BrowseView` to preserve genre selection and scroll state across album detail push/pop.

**Scroll position preservation:** SwiftUI's `NavigationStack` with `NavigationLink` preserves the parent view's state when pushing a detail view and popping back. Because `BrowseViewModel` is owned via `@State`, and `LazyVGrid` inherently preserves its scroll position as long as the data source does not change, scroll preservation works automatically. No manual scroll offset tracking needed. See [ADR-102](./DECISIONS.md#adr-102-mvvm-with-observable-for-app-architecture).

### 7.10 Project Structure

```
Crate/
  Crate.xcodeproj
  Crate/                              # Shared code (both targets)
    CrateApp.swift                    # @main entry point, app lifecycle
    ContentView.swift                 # Root view with navigation

    /Models                           # Data layer
      Album.swift                     # Album model (wraps MusicKit's Album or custom)
      Genre.swift                     # Genre model
      FavoriteAlbum.swift             # SwiftData @Model for persisted favorites
      GenreTaxonomy.swift             # Static two-tier genre tree

    /ViewModels                       # Business logic layer
      BrowseViewModel.swift           # Genre selection, album fetching, pagination
      AlbumDetailViewModel.swift      # Single album data, track list, favorite state
      PlaybackViewModel.swift         # Playback state, transport controls, queue
      AuthViewModel.swift             # MusicKit authorization state

    /Views                            # UI layer
      /Browse
        BrowseView.swift              # Main view: genre bars + album grid
        GenreBarView.swift            # Tier 1 super-genre horizontal scroll
        SubCategoryBarView.swift      # Tier 2 sub-category multi-select
        AlbumGridView.swift           # Infinite scroll album cover grid
        AlbumGridItemView.swift       # Single album cover tile
      /AlbumDetail
        AlbumDetailView.swift         # Full album view: art, metadata, tracklist
        TrackListView.swift           # Track listing with tap-to-play
      /Playback
        PlaybackFooterView.swift      # Persistent mini-player bar
        NowPlayingView.swift          # Expanded now-playing (future, not MVP)
      /Auth
        AuthView.swift                # MusicKit authorization prompt
      /Shared
        AlbumArtworkView.swift        # Reusable artwork component with size variants
        LoadingView.swift             # Skeleton / loading states
        EmptyStateView.swift          # "Pick a genre" / "No results" states

    /Services                         # Data access layer
      MusicService.swift              # All MusicKit / Apple Music API calls
      FavoritesService.swift          # SwiftData CRUD for favorites
      GenreService.swift              # Genre taxonomy lookup + charts fetching

    /Config
      Genres.swift                    # Static genre taxonomy definition

    /Extensions
      MusicKit+Extensions.swift       # Convenience extensions on MusicKit types
      View+Extensions.swift           # Shared view modifiers

    /Resources
      Assets.xcassets                 # App icons, colors, any bundled images

  Crate-iOS/                          # iOS-specific code
    Info.plist                        # iOS-specific plist entries
    Entitlements.entitlements         # iOS entitlements (background audio)

  Crate-macOS/                        # macOS-specific code
    Info.plist                        # macOS-specific plist entries
    Entitlements.entitlements         # macOS entitlements
    MacCommands.swift                 # Menu bar commands, keyboard shortcuts

  CrateTests/                         # Unit tests (shared)
    MusicServiceTests.swift
    BrowseViewModelTests.swift
    GenreTaxonomyTests.swift
    FavoritesServiceTests.swift

  CrateUITests/                       # UI tests
    BrowseFlowTests.swift
    PlaybackFlowTests.swift
```

### 7.11 Testing Constraints

MusicKit does not work in the iOS Simulator. This affects development workflow:

- **Unit tests** that mock the MusicKit layer can run in the Simulator.
- **Integration tests** and **UI tests** that require actual MusicKit playback or subscription checks must run on physical devices with an active Apple Music subscription.
- **Hardware requirement:** At minimum, one iPhone and one Mac with an Apple Music subscription for development and testing.

Testing strategy: XCTest for UI tests, Swift Testing for unit tests. Both frameworks coexist in the same test target. See [ADR-111](./DECISIONS.md#adr-111-xctest--swift-testing-for-test-strategy).

### 7.12 Deployment and Distribution

- **App Store** for both iOS and macOS (universal purchase). TestFlight for beta testing during development.
- **TestFlight** supports up to 10,000 external beta testers with no developer quota restrictions.
- **Xcode Cloud** for CI/CD (25 free compute hours/month). Automates build, test, and TestFlight distribution.
- **Minimum targets:** iOS 17.0, macOS 14.0 (Sonoma).
- **Entitlements:** MusicKit (both platforms), Background Modes -> Audio (iOS only).
- See [ADR-112](./DECISIONS.md#adr-112-app-store--testflight-for-distribution).

### 7.13 macOS Considerations

- All views, view models, services, SwiftData models, and MusicKit integration are shared between iOS and macOS.
- Grid layout uses adaptive `GridItem` sizing (`GridItem(.adaptive(minimum: 150, maximum: 200))`), which automatically adjusts column count based on window width.
- macOS-specific: menu bar commands with keyboard shortcuts for playback controls, default window size and minimum size configuration.
- Background audio is a non-issue on macOS (apps run in the background by default).
- MusicKit on macOS requires the user to be signed into their Apple ID in System Settings and have the Music app installed (it ships with macOS).

### 7.14 Answers to Open Questions

These answers are captured here for reference and also reflected in the Open Questions table in Section 9.

| Question | Answer | Details |
|----------|--------|---------|
| Q1: Genre API approach | Apple Music charts endpoint with genre parameter returns albums directly. One API call per page. | Section 7.2 |
| Q2: Multi-select logic | OR (union) logic. Users selecting multiple sub-genres want to broaden results, not narrow them. | Section 7.2 |
| Q3: Favorites storage | Local-only via SwiftData. Does not write to the user's Apple Music library. | Section 7.7 |
| Q5: Multi-genre albums | Albums charting in multiple genres will naturally appear in multiple queries. Same behavior, simpler implementation. | Section 7.2 |
| Q6: Default app state | No pre-selection. Show the genre bar with nothing highlighted and a minimal prompt inviting the user to pick a genre. | -- |
| Q7: Rate limit handling | 1 API call per page makes rate limits a non-issue. Defensive debounce on rapid genre switching and 429 retry. | Section 7.5 |
| Q8: Mobile playback | Fully resolved. `ApplicationMusicPlayer` plays audio directly in the app on iOS. No external app dependency. | Section 7.4 |
| Q9: Developer user limit | Fully resolved. Apple has no developer quota restrictions. TestFlight supports 10,000 external testers. | Section 7.12 |

---

## 8. Design Principles

These principles should guide every design and engineering decision:

1. **Album art is the interface.** The cover art grid is not a feature of the app -- it is the app. Every pixel not dedicated to album art needs to justify its existence.
2. **Two taps to music.** From opening the app: one tap on a genre, one tap on an album. That is the target. Every additional interaction is friction.
3. **No decision fatigue.** The genre taxonomy does the organizing. The user's only job is to browse and choose. There are no modes, no settings, no toggles, no preferences to configure.
4. **Albums are sacred.** No shuffle. No single-track promotion. No "you might also like" interstitials. When a user picks an album, the app respects that choice and plays it in order.
5. **The record store metaphor.** Every design decision should be tested against the question: "Does this feel like browsing records, or does this feel like using a software application?" The answer should always be the former.

---

## 9. Open Questions

### Resolved Questions (from original PRD)

| #  | Question | Status | Resolution |
|----|----------|--------|------------|
| 1  | What is the best API approach to fetch albums by genre? | **Resolved** | Apple Music charts endpoint with genre parameter returns albums directly. One API call per page. The multi-step pipeline is eliminated. See Section 7.2. |
| 2  | How should multi-select sub-categories combine? AND logic (intersection) or OR logic (union)? | **Resolved** | OR (union) logic. Users selecting multiple sub-genres want to broaden results, not narrow them. AND would produce confusingly small or empty result sets. |
| 3  | Should Favorites sync with the user's music library, or be a Crate-specific collection? | **Resolved** | Local-only favorites via SwiftData. Crate does not write to the user's Apple Music library. Clean separation of intents. See Section 7.7 and [ADR-106](./DECISIONS.md#adr-106-local-only-favorites-not-apple-music-library). |
| 4  | What is the right number of top-level super-genres? | **Open** | No engineering constraint on the number. The taxonomy is a static config file (Section 7.8) and can be adjusted freely. Apple Music's own genre hierarchy may simplify this decision. See N1 below. |
| 5  | How do we handle albums that span multiple genres? | **Resolved** | Albums charting in multiple genres will naturally appear in multiple queries. Same behavior as intended, simpler implementation. |
| 6  | What is the default state when the app opens? | **Resolved** | No pre-selection. Show the genre bar with nothing highlighted and a minimal prompt inviting the user to pick a genre. Crate is about intentional choice. |
| 7  | How should the app handle API rate limits during heavy infinite scroll usage? | **Resolved** | 1 API call per page makes rate limits essentially a non-issue. Defensive debounce on rapid genre switching and 429 retry as safety measures. See Section 7.5. |
| 8  | How do we handle mobile playback? | **Resolved** | `ApplicationMusicPlayer` plays audio directly in the app on iOS. No external app dependency. Background audio and lock screen controls are automatic. This was the primary reason for the platform pivot. |
| 9  | How do we handle developer user limits for testing/launch? | **Resolved** | Apple has no developer quota restrictions. TestFlight supports 10,000 external beta testers. App Store has no user limits. |

### New Open Questions (MusicKit Architecture)

| #  | Question | Owner | Status | Notes |
|----|----------|-------|--------|-------|
| N1 | Can we use Apple Music's own genre hierarchy directly for Tier 1/Tier 2, or do we need a fully custom taxonomy? | Product + Engineering | **Open** | Apple Music has a hierarchical genre system. Fetch the full list via the genres endpoint and evaluate whether it maps well to the desired structure. If it does, we eliminate the custom taxonomy entirely and genre lists auto-update as Apple adds genres. |
| N2 | What is the practical depth limit on the charts endpoint pagination? | Engineering | **Open -- validate during implementation** | Apple does not document a maximum offset. Test empirically. Likely caps at a few hundred to a thousand albums per genre. |
| N3 | How does the charts endpoint handle niche genres with few charting albums? | Engineering | **Open -- validate during implementation** | Some sub-genres may have sparse chart results. May need to supplement with `MusicCatalogSearchRequest` for certain genres. |
| N4 | Should we support the `MusicSubscriptionOffer` view for non-subscribers? | Product | **Open** | Apple provides a native subscription offer sheet. Do we present this (and potentially earn affiliate revenue), or simply gate the app and say "Apple Music subscription required"? |
| N5 | Do we want iCloud sync for favorites in MVP, or is local-only sufficient? | Product | **Open** | SwiftData + CloudKit makes this easy, but adds a dependency on the user being signed into iCloud and requires the CloudKit entitlement. Recommend local-only for MVP, add sync as a fast-follow. |
| N6 | Physical device required for MusicKit testing -- what is the hardware testing plan? | Engineering | **Open** | MusicKit does not work in the Simulator. All testing must happen on physical devices. Need at least one iPhone and one Mac with an Apple Music subscription for development. |

---

*End of Document*
