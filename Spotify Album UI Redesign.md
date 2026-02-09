# PRODUCT REQUIREMENTS DOCUMENT

# Crate
*The Album Listening Experience*

---

| | |
|---|---|
| **Version** | 1.0 -- MVP |
| **Date** | February 9, 2026 |
| **Status** | Draft -- Architecture Complete |
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

**Crate** recreates the experience of thumbing through a vinyl collection at home or discovering albums in a record store bin. It is a single-purpose interface built on top of Spotify that strips away everything except album discovery and album listening. When you open Crate, you see records. You browse. You pick one. You listen.

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

The taxonomy is a two-tier tree built bottom-up from Spotify's available genre vocabulary. The process:

1. **Start with Spotify's genre seeds.** These are the terminal nodes -- the actual query terms the system uses to fetch albums from Spotify's catalog.
2. **Group genre seeds into logical sub-categories** based on musical lineage, shared characteristics, and listener mental models. These become the second-tier selections (Tier 2).
3. **Roll sub-categories up into top-level super-genres** inspired by musicmap's framework. These become the first-tier horizontal navigation (Tier 1).

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

**Note:** This mapping is illustrative. The final taxonomy requires a dedicated effort to map every Spotify genre seed to the appropriate position in the tree, validate groupings against musicmap's genealogy, and user-test the top-level labels for intuitive navigation. This is a design and product task, not an engineering task.

---

## 3. User Experience

### 3.1 Authentication

Crate requires Spotify Premium. The app opens to a Spotify OAuth login screen. There is no browse-only or free-tier mode. Once authenticated, the user proceeds directly to the main browse view. Session tokens should persist so users are not re-prompted on every visit.

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
- Covers fill the available width in a responsive grid (e.g., 3 columns on phone, 4-5 on tablet, 6+ on desktop).
- Infinite scroll. As the user scrolls down, more albums load continuously.
- **Sort order: Popularity.** Albums are ranked by Spotify's popularity metrics. Future iterations may offer a toggle between popularity and randomized/shuffled order to create a more serendipitous "crate digging" feel.
- Album art only. No text overlay on the grid tiles. The visual experience should feel like looking at a wall of records.
- Scroll position is preserved when navigating to an album detail view and returning.

### 3.3 Album Detail View

Tapping an album cover transitions to a full-screen album detail view. Layout (mobile/narrow viewport):

- **Album art** displayed prominently at the top, as large as the viewport allows.
- **Album title and artist name** below the art.
- **Play button** that begins playback from track 1.
- **Favorite/save button** to add the album to the user's favorites collection within Crate.
- **Track list** showing track number, track name, and duration. Tapping any individual track begins playback from that track.
- Back navigation returns to the browse grid with scroll position preserved.

### 3.4 Playback Footer

A persistent mini-player footer is visible across all views whenever audio is playing. It includes:

- Album art thumbnail, track title, and artist name for the currently playing track.
- Play/pause, previous track, next track controls.
- Progress bar / scrubber.
- Volume control.
- The footer persists while the user continues browsing the album grid or viewing other album details.

**No shuffle button.** Shuffle is deliberately excluded. Crate is an album listening experience. Tracks play in album order. This is a product decision, not an oversight.

### 3.5 Favorites

Users can favorite albums from the album detail view. Favorited albums are accessible by selecting "Favorites" in the Tier 1 super-genre bar. Favorites are displayed in the same album grid format. Favorite state is synced with Spotify's saved albums library (see Section 7.7).

---

## 4. Information Architecture

The application has exactly three views:

| View         | Purpose                           | Navigation                                      |
|--------------|-----------------------------------|-------------------------------------------------|
| Login        | Spotify OAuth authentication      | Automatic redirect to Browse on success         |
| Browse       | Genre selection + album grid      | Tap album -> Album Detail                       |
| Album Detail | Art, metadata, tracklist, playback| Back -> Browse (scroll preserved)               |

That's it. Three views. No settings page, no profile page, no social features, no search bar, no sidebar navigation. The entire app is: browse, pick, listen.

---

## 5. MVP Scope

### 5.1 In Scope

- Spotify Premium OAuth login
- Two-tier genre taxonomy (super-genres -> sub-genres)
- Album grid populated by genre selection, sorted by popularity
- Infinite scroll on the album grid
- Album detail view with art, metadata, and track list
- Full playback: play/pause, prev/next, scrubber, volume
- Persistent playback footer across all views
- Favorite albums and a Favorites view in the genre bar
- Scroll position preservation on back navigation
- Responsive design: mobile-first (iPhone, iPad), functional on desktop

### 5.2 Out of Scope (Future Iterations)

- **Search.** Free-text album or artist search. Planned as a fast-follow if the browse-only experience validates well.
- **Randomized grid sort.** A toggle to switch the album grid from popularity-ranked to randomized order for a more serendipitous browsing feel.
- **Native iOS app (App Store).** A wrapped version of the web app for App Store distribution, using a tool like Capacitor.
- **Desktop-optimized layout.** A refined desktop experience beyond basic responsive scaling.
- **Social features.** Sharing albums, seeing what friends are listening to.
- **Listening history / recently played.** A view showing albums the user has recently listened to.
- **Editorial curation.** Staff picks, featured albums, new release spotlights.

---

## 6. Technical Considerations

This section captures platform constraints and requirements identified during product planning. Detailed architectural decisions that address each of these items are documented in Section 7 and in [DECISIONS.md](./DECISIONS.md).

### 6.1 Spotify API Constraints

- Spotify has **deprecated the /recommendations/available-genre-seeds endpoint** and **removed several Browse endpoints** (categories, new releases) in February 2026. The Search API with genre filters on artists remains viable. See Section 7.2 for the resolved pipeline approach.
- Spotify's Web Playback SDK requires Spotify Premium and runs in the browser. Mobile browsers do not support the SDK. See Section 7.4 for the playback architecture including the mobile fallback.
- API rate limits and pagination behavior affect infinite scroll performance. See Sections 7.5 and 7.6 for the caching and pagination strategies.
- Spotify's API associates genres with artists, not albums. The mapping from genre selection to album results requires querying artists by genre, then fetching their albums. See Section 7.2 for details.

### 6.2 Genre Taxonomy Implementation

- The two-tier taxonomy (Section 2) is a static configuration maintained by the product team. It is stored as a JSON configuration file validated at build time with Zod. See Section 7.8 for the schema and storage approach.
- Each terminal node in the taxonomy maps to one or more Spotify genre query terms.

### 6.3 Platform

- Responsive web application, mobile-first design targeting iPhone and iPad screen sizes.
- Must function well on desktop browsers but mobile/tablet is the primary design target for MVP.
- Next.js (App Router) with React and Tailwind CSS. See Section 7.1 for the full tech stack.

### 6.4 Development Mode Constraint

Spotify limits Development Mode apps to 5 authorized users and requires the developer to have a Spotify Premium account. See Section 7.11 for implications and the path to Extended Quota Mode.

---

## 7. Architecture and Technical Decisions

*Added 2026-02-09 by Architecture. Full decision rationale in [DECISIONS.md](./DECISIONS.md).*

### 7.1 Tech Stack

| Layer              | Choice                            | Rationale                                                                                  |
|--------------------|-----------------------------------|--------------------------------------------------------------------------------------------|
| **Framework**      | Next.js 14+ (App Router)          | Server-side Route Handlers for OAuth and API proxy; client-side React for the interactive UI. Standard stack. |
| **Styling**        | Tailwind CSS                      | Standard stack. Well-suited to the minimal, typographic aesthetic.                         |
| **State Management** | Zustand                         | Lightweight (~1KB), selector-based subscriptions avoid re-render issues with the always-updating playback progress bar. No boilerplate. |
| **Validation**     | Zod                               | Standard stack. Used to validate the genre taxonomy JSON at build time and API responses at runtime. |
| **Testing**        | Vitest + React Testing Library    | Standard stack. Unit tests for the API proxy pipeline; component tests for genre selection and playback controls. |
| **Deployment**     | Vercel                            | Zero-config Next.js deployment. Free tier sufficient for MVP (5 users). Built-in CDN, serverless functions, preview deploys. |
| **Database**       | None for MVP                      | No persistent app-specific data needed. Auth via cookies, favorites via Spotify's library API, taxonomy via static JSON. |

**Why no Supabase?** There is nothing to store. Auth tokens live in encrypted cookies. Favorites sync with Spotify's saved albums. The genre taxonomy is a static config file. Introducing a database would add complexity with zero benefit at MVP. If we later need Crate-specific persistent data (listening history, Crate-only favorites, user preferences), Supabase is the natural addition. See [ADR-013](./DECISIONS.md#adr-013-no-supabase-or-external-database-for-mvp).

### 7.2 Spotify API Strategy: Genre-to-Album Pipeline

This is the most architecturally significant decision in the project. Spotify's API has no direct "give me albums in genre X" endpoint. Here is what we are working with after the February 2026 API changes:

**What still works:**

- `GET /search` with `q=genre:"rock"&type=artist` -- genre filter works on artist searches
- `GET /artists/{id}/albums` -- fetch an individual artist's album catalog
- `GET /albums/{id}` -- fetch a single album's details
- All Player API endpoints (play, pause, skip, seek, volume, devices)
- Library endpoints (`GET /me/albums`, `PUT /me/library`, `DELETE /me/library`)

**What was removed or deprecated:**

- `GET /recommendations/available-genre-seeds` -- deprecated (2024)
- `GET /browse/new-releases` -- removed (Feb 2026)
- `GET /browse/categories` -- removed (Feb 2026)
- `GET /artists` (batch) -- removed (Feb 2026); single-artist fetch still works
- `GET /albums` (batch) -- removed (Feb 2026); single-album fetch still works

**The pipeline (runs server-side in Next.js Route Handlers):**

```
User selects "Indie / Alternative"
        |
        v
Taxonomy lookup: spotifyGenres = ["indie", "alternative", "indie rock"]
        |
        v
For each genre term:
  GET /search?q=genre:"indie"&type=artist&limit=50
  GET /search?q=genre:"alternative"&type=artist&limit=50
  GET /search?q=genre:"indie rock"&type=artist&limit=50
        |
        v
Collect unique artists, sorted by Spotify popularity
        |
        v
For top N artists:
  GET /artists/{id}/albums?include_groups=album&limit=50
        |
        v
Aggregate all albums, deduplicate by album ID,
sort by album popularity, paginate
        |
        v
Return page of 30 albums to client
```

**Key constraints:**

- This pipeline requires multiple API calls per genre query. Server-side caching (15-30 minute TTL) is mandatory to stay within rate limits. See Section 7.5.
- Spotify's Search offset caps at 1000, limiting discovery depth. This is acceptable for a browsing-oriented product.
- The genre-to-artist-to-album indirection means result quality depends on Spotify's artist genre tagging. Some niche genres may return sparse results. This should be validated during taxonomy mapping.

**Risk:** If Spotify removes the genre filter from the Search endpoint, this entire pipeline breaks. There is no fallback within Spotify's API. A contingency plan would involve building a genre-to-artist mapping table using data from MusicBrainz or Last.fm, but this is not needed for MVP. See [ADR-002](./DECISIONS.md#adr-002-genre-to-album-pipeline-via-artist-search).

### 7.3 Authentication and Session Management

**Flow:** Spotify Authorization Code Flow (not PKCE, not Implicit).

```
Browser                    Crate Server              Spotify
  |                            |                        |
  |-- GET /login ------------->|                        |
  |                            |-- redirect to -------->|
  |                            |   authorize URL        |
  |<-------- Spotify consent screen --------------------|
  |-- callback with code ----->|                        |
  |                            |-- POST /api/token ---->|
  |                            |<-- access + refresh ---|
  |                            |                        |
  |<-- Set encrypted cookies --|                        |
  |    (access_token,          |                        |
  |     refresh_token)         |                        |
  |                            |                        |
  |-- GET /api/auth/token ---->|                        |
  |                            |-- refresh if needed -->|
  |<-- { access_token } -------|<-- new tokens ---------|
  |                            |                        |
  | (client uses token for     |                        |
  |  Web Playback SDK init)    |                        |
```

**Token storage:**

- Refresh token: HTTP-only, Secure, encrypted cookie. Never exposed to client JavaScript.
- Access token: HTTP-only, Secure cookie with ~55 minute max-age (slightly under Spotify's 1-hour TTL to refresh proactively).
- Session library: `iron-session` for encrypted cookie management. No external session store.

**Why not localStorage?** XSS vulnerability. A malicious script could steal the refresh token and gain indefinite access to the user's Spotify account. Cookies with HTTP-only flag are immune to this. See [ADR-004](./DECISIONS.md#adr-004-spotify-oauth-with-server-side-token-management).

**Premium check:** After OAuth, call `GET /me` to verify `product === "premium"`. If not Premium, display a clear message and do not proceed to the browse view. The Web Playback SDK will not work without Premium.

**Required OAuth scopes:** `streaming`, `user-read-email`, `user-read-private`, `user-library-read`, `user-library-modify`, `user-modify-playback-state`, `user-read-playback-state`, `user-read-currently-playing`. See [ADR-014](./DECISIONS.md#adr-014-scoped-spotify-permissions) for scope rationale.

### 7.4 Playback Architecture

**Desktop browsers:** Spotify Web Playback SDK. This creates a virtual playback device in the browser. When the user first plays an album, we transfer playback to this device via `PUT /me/player`. The SDK emits `player_state_changed` events that we use to keep the Zustand playback store in sync. See [ADR-009](./DECISIONS.md#adr-009-spotify-web-playback-sdk-for-in-browser-playback).

**Mobile browsers:** The Web Playback SDK does not work on mobile browsers (iOS Safari, Android Chrome) due to platform autoplay restrictions and background audio limitations. This is a known, hard limitation of the web platform -- not something we can engineer around.

**Mobile fallback -- Spotify Connect:** On mobile, Crate acts as a remote control for the user's Spotify app:

1. Detect that the Web Playback SDK fails to initialize (or detect mobile via User-Agent as a fast path).
2. Call `GET /me/player/devices` to find the user's active Spotify device.
3. Use `PUT /me/player/play` with the external `device_id` to control playback on that device.
4. If no active device is found, display a message: "Open Spotify on your device to start listening."

See [ADR-010](./DECISIONS.md#adr-010-mobile-playback-via-spotify-connect-fallback).

**This is a significant UX gap for a "mobile-first" product.** On mobile, the user needs the Spotify app running in the background to hear anything. The browsing and discovery experience in Crate still works beautifully on mobile -- but playback requires the Spotify app. This should be clearly communicated in the UI, not buried. It is worth considering whether to show a one-time tooltip or onboarding message on first mobile visit.

**Playback initiation:**

- Play album from track 1: `PUT /me/player/play` with `context_uri: "spotify:album:{id}"` and `offset: { position: 0 }`
- Play from specific track: same call with `offset: { position: trackIndex }`
- Transport controls (pause, skip, seek, volume): corresponding Player API endpoints

### 7.5 Caching Strategy

Three layers, from server to client:

| Layer                    | What                                  | TTL          | Purpose                                                                |
|--------------------------|---------------------------------------|--------------|------------------------------------------------------------------------|
| **Server in-memory**     | Genre-to-album pipeline results       | 15-30 min    | Avoid redundant Spotify API calls across users and requests            |
| **HTTP cache headers**   | API proxy responses                   | 5-10 min     | Vercel CDN edge caching + browser cache                                |
| **Client Zustand store** | Loaded albums per genre selection     | Session lifetime | Avoid re-fetching when navigating back from album detail            |

**Cache key structure:** `genre:{sortedGenreTerms}:page:{pageNumber}`

The in-memory cache uses a simple Map with TTL eviction (via `node-cache` or a hand-rolled solution). At MVP scale (5 users), this is more than sufficient. If we scale beyond MVP, Vercel KV or Redis would replace the in-memory layer. See [ADR-005](./DECISIONS.md#adr-005-multi-layer-caching-strategy).

### 7.6 Infinite Scroll and Pagination

**Client-side:** Intersection Observer watches a sentinel element at the bottom of the album grid. When it enters the viewport, request the next page.

**Server-side:** Each page request triggers the genre-to-album pipeline (or serves from cache). The API proxy returns:

```json
{
  "albums": [ ... ],
  "page": 2,
  "hasMore": true
}
```

**Page size:** 30 albums (10 rows of 3 on mobile, 5 rows of 6 on desktop).

**Prefetching:** When the client requests page N, the server can optimistically compute page N+1 and cache it. The client may also prefetch one page ahead once the user has scrolled past 70% of the current page.

**Hard limit:** Spotify's search offset caps at 1000. With deduplication, we can realistically serve 300-500 unique albums per genre combination. This is more than sufficient -- no one browses 500 album covers in a single session. See [ADR-012](./DECISIONS.md#adr-012-infinite-scroll-via-cursor-based-pagination).

### 7.7 Favorites

**Decision:** Favorites sync with Spotify's saved albums library. No separate Crate-specific favorites store.

**Why:** Using Spotify's library (`PUT /me/library`, `GET /me/albums`, `DELETE /me/library`) means:

- Albums saved in Crate also appear as saved in the Spotify app, and vice versa.
- No database needed. No sync conflicts. No user management.
- The endpoints survived the February 2026 changes (save/remove moved from `/me/albums` to `/me/library`).

**Loading the Favorites view:** `GET /me/albums` with pagination, same grid format as genre results. We check whether an album is saved via `GET /me/albums/contains?ids={albumIds}` to display the favorite state on the album detail view (note: verify this endpoint is still available; if not, we check against the loaded favorites list client-side). See [ADR-007](./DECISIONS.md#adr-007-favorites-stored-in-spotifys-library-not-supabase).

### 7.8 Genre Taxonomy Storage

**Format:** Static JSON file at `/src/config/genres.json`, validated at build time with Zod.

**Schema:**

```json
[
  {
    "id": "rock",
    "label": "Rock",
    "subCategories": [
      {
        "id": "indie-alternative",
        "label": "Indie / Alternative",
        "spotifyGenres": ["indie", "alternative", "indie rock"]
      },
      {
        "id": "classic-rock",
        "label": "Classic Rock",
        "spotifyGenres": ["classic rock", "rock"]
      }
    ]
  }
]
```

This file is the single source of truth for what genres exist in the app and how they map to Spotify query terms. Updating it requires a commit and deploy, which is appropriate for something that changes at most quarterly. See [ADR-008](./DECISIONS.md#adr-008-genre-taxonomy-as-static-json-configuration).

### 7.9 Client-Side State (Zustand Store)

Single Zustand store with logical slices:

| Slice          | State                                                                        | Persistence                               |
|----------------|------------------------------------------------------------------------------|-------------------------------------------|
| **genres**     | Selected super-genre, selected sub-categories                                | Session only                              |
| **albums**     | Loaded album pages per genre key, scroll position                            | Session only                              |
| **playback**   | Current track, play/pause, progress, volume, device type (SDK vs Connect)    | Session only                              |
| **favorites**  | Set of favorited album IDs (for quick UI checks)                             | Session only; source of truth is Spotify  |

**Scroll position preservation:** When the user taps an album, the current scroll offset is stored in the `albums` slice. When they navigate back, the grid restores to that offset. Because Zustand state persists across React route transitions (unlike component-local state), this works without any special tricks. See [ADR-006](./DECISIONS.md#adr-006-zustand-for-client-side-state-management).

### 7.10 Project Structure

```
/src
  /app
    /page.tsx                    # Login view (or redirect to browse if authenticated)
    /browse
      /page.tsx                  # Main browse view (genre bars + album grid)
    /album
      /[id]/page.tsx             # Album detail view
    /api
      /auth
        /login/route.ts          # Initiates Spotify OAuth
        /callback/route.ts       # Handles OAuth callback, sets cookies
        /token/route.ts          # Returns fresh access token to client
        /logout/route.ts         # Clears session cookies
      /genres
        /[genreKey]/route.ts     # Genre-to-album pipeline (paginated)
      /favorites
        /route.ts                # Read/write Spotify saved albums
  /components
    /GenreBar.tsx                # Tier 1 super-genre horizontal scroll
    /SubCategoryBar.tsx          # Tier 2 sub-category multi-select
    /AlbumGrid.tsx               # Infinite scroll album cover grid
    /AlbumDetail.tsx             # Full album view with tracklist
    /PlaybackFooter.tsx          # Persistent mini-player
    /PlaybackProvider.tsx        # Initializes Web Playback SDK or Connect
  /config
    /genres.json                 # Static genre taxonomy
    /genres.schema.ts            # Zod validation for taxonomy
  /lib
    /spotify.ts                  # Spotify API client (server-side)
    /auth.ts                     # Session/cookie helpers
    /cache.ts                    # In-memory cache with TTL
  /store
    /index.ts                    # Zustand store definition
  /types
    /spotify.ts                  # TypeScript types for Spotify API responses
    /genres.ts                   # TypeScript types for taxonomy
```

### 7.11 Development Mode Constraint

**Critical context:** As of February 2026, Spotify limits Development Mode apps to 5 authorized users and requires the developer to have a Spotify Premium account. Extending beyond 5 users requires applying for Extended Quota Mode, which demands a registered business, 250K+ MAU, and availability in key Spotify markets.

**What this means for Crate:**

- MVP is inherently limited to 5 test users. This is fine for validating the concept.
- To launch publicly, we would need to apply for Extended Quota Mode. This is a business/legal task, not an engineering task, but it should be on the roadmap.
- The 5-user limit does not affect architecture. The app is built the same way regardless of user count.

### 7.12 Answers to Open Questions

These answers are captured here for reference and also reflected in the Open Questions table in Section 9.

| Question | Answer | Details |
|----------|--------|---------|
| Q1: Genre API approach | Search API with genre filter on artists, then fetch each artist's albums. Two-step server-side pipeline. | Section 7.2 |
| Q2: Multi-select logic | OR (union) logic. Users selecting multiple sub-genres want to broaden results, not narrow them. | Section 7.2 |
| Q3: Favorites storage | Sync with Spotify's saved albums. Eliminates the need for a database. | Section 7.7 |
| Q5: Multi-genre albums | Albums appear in every genre bucket where their artist is tagged. This is natural and desirable. | Section 7.2 |
| Q6: Default app state | No pre-selection. Show the genre bar with nothing highlighted and a minimal prompt inviting the user to pick a genre. | -- |
| Q7: Rate limit handling | Three-layer caching, server-side request queuing, debounced pagination, automatic retry on 429 responses. | Section 7.5 |
| Q8: Mobile playback | Spotify Connect fallback. Crate becomes a remote control for the user's Spotify app on mobile. | Section 7.4 |

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

| #  | Question | Owner | Status | Resolution |
|----|----------|-------|--------|------------|
| 1  | What is the best current Spotify API approach to fetch albums by genre given the deprecated genre seeds endpoint? | Engineering | **Resolved** | Search API with genre filter on artists, then fetch each artist's albums. Two-step pipeline running server-side. See Section 7.2. |
| 2  | How should multi-select sub-categories combine? AND logic (intersection) or OR logic (union)? | Product + Engineering | **Resolved** | OR (union) logic. Users selecting multiple sub-genres want to broaden results, not narrow them. AND would produce confusingly small or empty result sets. |
| 3  | Should Favorites sync with the user's Spotify saved albums, or be a Crate-specific collection? | Product | **Resolved** | Sync with Spotify's saved albums. Eliminates the need for a database, avoids sync conflicts, and creates a consistent experience across Spotify and Crate. See Section 7.7. |
| 4  | What is the right number of top-level super-genres? 12-15 is proposed. User testing may reveal a better number. | Product + Design | **Open** | No engineering constraint on the number. The taxonomy is a static config file (Section 7.8) and can be adjusted freely. Recommend starting with the proposed 15 and testing. |
| 5  | How do we handle albums that span multiple genres? Do they appear in multiple sub-category results? | Product + Engineering | **Resolved** | Yes, albums appear in every matching genre bucket. This is inherent to the pipeline design -- we search by artist genre, and an artist tagged with multiple genres will surface their albums in each. This is the correct behavior. |
| 6  | What is the default state when the app opens? Pre-selected genre, or empty grid prompting selection? | Product + Design | **Resolved** | No pre-selection. Show the genre bar with nothing highlighted and a minimal prompt inviting the user to pick a genre. Crate is about intentional choice. |
| 7  | How should the app handle Spotify API rate limits during heavy infinite scroll usage? | Engineering | **Resolved** | Three-layer caching (server in-memory, HTTP/CDN, client-side), server-side request queuing, debounced client pagination, and automatic retry with Retry-After on 429 responses. See Section 7.5. |
| 8  | How do we handle the mobile playback limitation (Web Playback SDK does not work on mobile browsers)? | Engineering + Product | **Resolved** | Use Spotify Connect as a fallback on mobile. Crate becomes a remote control for the user's Spotify app. Requires the Spotify app to be running on the user's device. Must be clearly communicated in the UI. See Section 7.4. |
| 9  | How do we handle the 5-user Development Mode limit for public launch? | Product + Business | **Open** | MVP is fine within the 5-user limit. Public launch requires applying for Spotify's Extended Quota Mode (registered business, 250K MAU requirement). This is a business/legal task that should be on the roadmap. See Section 7.11. |

---

*End of Document*
