# PRODUCT REQUIREMENTS DOCUMENT

# Crate
*The Album Listening Experience*

---

| | |
|---|---|
| **Version** | 1.0 — MVP |
| **Date** | February 9, 2026 |
| **Status** | Draft |
| **Author** | Product Management |
| **Audience** | Engineering, Design, Leadership |

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

1. **Start with Spotify's genre seeds.** These are the terminal nodes — the actual query terms the system uses to fetch albums from Spotify's catalog.
2. **Group genre seeds into logical sub-categories** based on musical lineage, shared characteristics, and listener mental models. These become the second-tier selections (Tier 2).
3. **Roll sub-categories up into top-level super-genres** inspired by musicmap's framework. These become the first-tier horizontal navigation (Tier 1).

The organizing principle is musicmap's concept of super-genres as large, intuitive family groupings, with sub-genres nested beneath as more specific entry points. The taxonomy should feel natural to a music fan browsing a well-organized record store, where sections are clearly labeled but not so granular that you need a map to find anything.

### 2.3 Proposed Top-Level Categories (Tier 1)

The following super-genre categories are proposed as the Tier 1 horizontal navigation. These are derived from musicmap's super-genre framework, consolidated to a navigable set of approximately 12–15 top-level entries. Final naming and grouping will be refined during design, but the intent is:

| Super-Genre | Contains (Example Sub-Categories) |
|---|---|
| Rock | Classic Rock, Indie/Alternative, Punk, Grunge, Psychedelic, Progressive, Hard Rock |
| Metal | Heavy Metal, Black Metal, Death Metal, Metalcore, Grindcore |
| Pop | Pop, Indie Pop, Synth-Pop, Power Pop, Electropop, Dance Pop |
| Hip-Hop / Rap | Hip-Hop, Old School, Trap, Conscious, Boom Bap |
| R&B / Soul | R&B, Soul, Funk, Neo-Soul, Gospel |
| Jazz | Jazz, Bebop, Fusion, Smooth Jazz, Acid Jazz |
| Blues | Blues, Delta Blues, Chicago Blues, Blues Rock |
| Electronic / Dance | House, Techno, Trance, EDM, Deep House, Minimal Techno, IDM |
| Breakbeat / Bass | Drum & Bass, Breakbeat, Dubstep, UK Garage, Trip-Hop |
| Country | Country, Honky-Tonk, Bluegrass, Americana, Outlaw Country |
| Reggae / Caribbean | Reggae, Dancehall, Dub, Ska, Reggaeton |
| Latin / Brazilian | Latin, Salsa, Bossa Nova, Samba, Tango, MPB |
| Folk / Acoustic | Folk, Singer-Songwriter, Acoustic, Indie Folk |
| Classical / Ambient | Classical, Opera, Ambient, New Age, Downtempo |
| World / Global | World Music, Afrobeat, Indian, K-Pop, J-Pop, Cantopop, Mandopop |

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
- Covers fill the available width in a responsive grid (e.g., 3 columns on phone, 4–5 on tablet, 6+ on desktop).
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

Users can favorite albums from the album detail view. Favorited albums are accessible by selecting "Favorites" in the Tier 1 super-genre bar. Favorites are displayed in the same album grid format. Favorite state is persisted per user (backed by Spotify's saved albums library or a lightweight app-side data store — engineering to determine).

---

## 4. Information Architecture

The application has exactly three views:

| View | Purpose | Navigation |
|---|---|---|
| Login | Spotify OAuth authentication | Automatic redirect to Browse on success |
| Browse | Genre selection + album grid | Tap album → Album Detail |
| Album Detail | Art, metadata, tracklist, playback | Back → Browse (scroll preserved) |

That's it. Three views. No settings page, no profile page, no social features, no search bar, no sidebar navigation. The entire app is: browse, pick, listen.

---

## 5. MVP Scope

### 5.1 In Scope

- Spotify Premium OAuth login
- Two-tier genre taxonomy (super-genres → sub-genres)
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

## 6. Technical Considerations for Engineering

This section is not prescriptive on stack or architecture. It flags constraints and open questions the engineering team should address during technical planning.

### 6.1 Spotify API Constraints

- Spotify has **deprecated the /recommendations/available-genre-seeds endpoint.** The genre seed list still exists in cached/documented form, and the Search API supports genre: query filters, but the cleanest discovery endpoint is no longer available. Engineering needs to spike on the best current approach to populate the album grid by genre. Options include the Search API with genre filters, Browse Categories, and artist-genre associations.
- Spotify's Web Playback SDK requires Spotify Premium and runs in the browser. This is the assumed playback integration path.
- API rate limits and pagination behavior will affect infinite scroll performance. Engineering should determine appropriate prefetch and caching strategies.
- Spotify's API associates genres with artists, not albums. The mapping from genre selection to album results may require querying artists by genre, then fetching their albums. This indirection should be evaluated for performance and result quality.

### 6.2 Genre Taxonomy Implementation

- The two-tier taxonomy (Section 2) is a static configuration maintained by the product team. It should be stored as a configuration file or lightweight data structure, not hard-coded into the UI. This allows the taxonomy to be updated without code changes.
- Each terminal node in the taxonomy maps to one or more Spotify genre query terms.

### 6.3 Platform

- Responsive web application, mobile-first design targeting iPhone and iPad screen sizes.
- Must function well on desktop browsers but mobile/tablet is the primary design target for MVP.
- Engineering to determine the optimal framework and deployment approach.

---

## 7. Design Principles

These principles should guide every design and engineering decision:

1. **Album art is the interface.** The cover art grid is not a feature of the app — it is the app. Every pixel not dedicated to album art needs to justify its existence.
2. **Two taps to music.** From opening the app: one tap on a genre, one tap on an album. That's the target. Every additional interaction is friction.
3. **No decision fatigue.** The genre taxonomy does the organizing. The user's only job is to browse and choose. There are no modes, no settings, no toggles, no preferences to configure.
4. **Albums are sacred.** No shuffle. No single-track promotion. No "you might also like" interstitials. When a user picks an album, the app respects that choice and plays it in order.
5. **The record store metaphor.** Every design decision should be tested against the question: "Does this feel like browsing records, or does this feel like using a software application?" The answer should always be the former.

---

## 8. Open Questions

| # | Question | Owner |
|---|---|---|
| 1 | What is the best current Spotify API approach to fetch albums by genre given the deprecated genre seeds endpoint? | Engineering |
| 2 | How should multi-select sub-categories combine? AND logic (intersection) or OR logic (union)? | Product + Engineering |
| 3 | Should Favorites sync with the user's Spotify saved albums, or be a Crate-specific collection? | Product |
| 4 | What is the right number of top-level super-genres? 12–15 is proposed. User testing may reveal a better number. | Product + Design |
| 5 | How do we handle albums that span multiple genres? Do they appear in multiple sub-category results? | Product + Engineering |
| 6 | What is the default state when the app opens? Pre-selected genre, or empty grid prompting selection? | Product + Design |
| 7 | How should the app handle Spotify API rate limits during heavy infinite scroll usage? | Engineering |

---

*End of Document*
