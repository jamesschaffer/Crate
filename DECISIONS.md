# Architectural Decision Records -- Crate

This document captures key architectural decisions for Crate, with context and rationale. Decisions are numbered and dated. If a decision is revisited, the original is preserved and the revision is appended.

For the full product specification, see [Crate PRD](./Spotify%20Album%20UI%20Redesign.md).

---

## Index

| ADR | Title | Status |
|-----|-------|--------|
| 001 | [Next.js + React + Tailwind CSS for Frontend](#adr-001-nextjs--react--tailwind-css-for-frontend) | Accepted |
| 002 | [Genre-to-Album Pipeline via Artist Search](#adr-002-genre-to-album-pipeline-via-artist-search) | Accepted |
| 003 | [Server-Side API Proxy Layer](#adr-003-server-side-api-proxy-layer) | Accepted |
| 004 | [Spotify OAuth with Server-Side Token Management](#adr-004-spotify-oauth-with-server-side-token-management) | Accepted |
| 005 | [Multi-Layer Caching Strategy](#adr-005-multi-layer-caching-strategy) | Accepted |
| 006 | [Zustand for Client-Side State Management](#adr-006-zustand-for-client-side-state-management) | Accepted |
| 007 | [Favorites Stored in Spotify's Library (Not Supabase)](#adr-007-favorites-stored-in-spotifys-library-not-supabase) | Accepted |
| 008 | [Genre Taxonomy as Static JSON Configuration](#adr-008-genre-taxonomy-as-static-json-configuration) | Accepted |
| 009 | [Spotify Web Playback SDK for In-Browser Playback](#adr-009-spotify-web-playback-sdk-for-in-browser-playback) | Accepted |
| 010 | [Mobile Playback via Spotify Connect Fallback](#adr-010-mobile-playback-via-spotify-connect-fallback) | Accepted |
| 011 | [Vercel for Deployment](#adr-011-vercel-for-deployment) | Accepted |
| 012 | [Infinite Scroll via Cursor-Based Pagination](#adr-012-infinite-scroll-via-cursor-based-pagination) | Accepted |
| 013 | [No Supabase or External Database for MVP](#adr-013-no-supabase-or-external-database-for-mvp) | Accepted |
| 014 | [Scoped Spotify Permissions](#adr-014-scoped-spotify-permissions) | Accepted |

---

## ADR-001: Next.js + React + Tailwind CSS for Frontend

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.1 -- Tech Stack](./Spotify%20Album%20UI%20Redesign.md#71-tech-stack)

**Context:** Crate is a responsive web application with three views, heavy client-side interactivity (infinite scroll, playback controls, multi-select filters), and a requirement for session-persisted auth tokens. We need server-side capabilities for the Spotify OAuth flow and to proxy API calls (to protect client secrets and manage rate limits). Our team standard stack is Next.js + React + Tailwind.

**Decision:** Use Next.js (App Router) with React and Tailwind CSS.

**Rationale:**
- Next.js gives us both the server-side rendering we need for the OAuth callback and API route handlers (to proxy Spotify calls) alongside a rich client-side experience.
- App Router with server components lets us handle auth token refresh and API proxying in Route Handlers without exposing secrets to the client.
- Tailwind CSS is our standard and is well-suited to the minimal, typographic aesthetic described in the PRD.
- No reason to deviate from the team standard. The requirements are a textbook fit.

**Trade-offs:**
- Next.js App Router is more complex than Pages Router, but the server component model is the right fit for keeping Spotify secrets server-side.
- SSR is mostly irrelevant for this app (no SEO need), but the server-side Route Handlers justify Next.js over a pure SPA.

**What would change this:** If we decided to ship a native iOS app first instead of web, we would use Swift/SwiftUI. But the PRD specifies responsive web for MVP.

---

## ADR-002: Genre-to-Album Pipeline via Artist Search

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.2 -- Genre-to-Album Pipeline](./Spotify%20Album%20UI%20Redesign.md#72-spotify-api-strategy-genre-to-album-pipeline)

**Context:** Spotify's `genre` field filter only works on `type=artist` and `type=track` searches -- NOT on `type=album`. The `/recommendations/available-genre-seeds` endpoint is deprecated. The `/browse/categories` and `/browse/new-releases` endpoints were removed in February 2026. Genres in Spotify's data model live on artists, not albums. There is no direct "give me albums in genre X" API call.

**Decision:** Implement a two-step pipeline:
1. Search for artists by genre using `GET /search?q=genre:"rock"&type=artist` with pagination.
2. For each artist returned, fetch their albums using `GET /artists/{id}/albums`.
3. Deduplicate, sort by popularity, and serve to the client.

This pipeline runs server-side in Next.js Route Handlers.

**Rationale:**
- This is the only reliable path given current API constraints. The Search endpoint with genre filter on artists is the sole surviving mechanism for genre-based discovery.
- Running this server-side lets us aggregate, deduplicate, cache, and sort before sending a clean album list to the client.
- The indirection (genre -> artists -> albums) means we need to fetch more data than we display, but caching (see ADR-005) makes this viable.

**Trade-offs:**
- More API calls per genre query than a direct album search would require. A single page of 20 albums might require 1 artist search call + up to 20 album-list calls. This is why server-side caching is non-negotiable.
- Result quality depends on Spotify's artist-genre tagging. Some genres may return sparse or unexpected results.
- Albums by multi-genre artists will appear in multiple genre buckets. This is actually desirable per the PRD (Open Question #5).

**Risks:**
- If Spotify further restricts the Search endpoint or removes the genre filter, this approach breaks entirely. There is no fallback within Spotify's API. We would need to consider a third-party genre database (MusicBrainz, Last.fm) as a contingency.
- The February 2026 removal of `GET /artists` (batch endpoint) means we cannot batch-fetch artist details. We can only fetch one artist at a time. This reinforces the need to cache aggressively.

**What would change this:** A Spotify API update that re-introduces genre-based album search, or a decision to use a third-party genre/album database instead of relying solely on Spotify.

---

## ADR-003: Server-Side API Proxy Layer

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.2](./Spotify%20Album%20UI%20Redesign.md#72-spotify-api-strategy-genre-to-album-pipeline), [Section 7.10 -- Project Structure](./Spotify%20Album%20UI%20Redesign.md#710-project-structure)

**Context:** The Spotify client secret must never be exposed to the browser. Rate limits are per-app, not per-user, so uncontrolled client-side API calls from multiple users could exhaust our rate budget. The genre-to-album pipeline (ADR-002) requires aggregation logic that does not belong in the client.

**Decision:** All Spotify API calls go through Next.js Route Handlers (`/app/api/...`). The client never calls Spotify directly (except the Web Playback SDK, which requires a client-side access token by design).

**Rationale:**
- Centralizes rate limit management. We can implement request queuing and throttling in one place.
- Keeps the client secret server-side.
- Allows server-side caching of genre/artist/album data (see ADR-005).
- Enables the aggregation pipeline (search artists -> fetch albums -> deduplicate -> sort) without round-tripping to the client between steps.

**Trade-offs:**
- Adds latency: client -> our server -> Spotify -> our server -> client. Caching mitigates this for repeat queries.
- Our server becomes a single point of failure for API calls. Vercel's edge infrastructure mitigates this operationally.

**What would change this:** If Spotify introduced a client-safe API key model (no secret required), we could move some read-only calls to the client. Unlikely.

---

## ADR-004: Spotify OAuth with Server-Side Token Management

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.3 -- Authentication and Session Management](./Spotify%20Album%20UI%20Redesign.md#73-authentication-and-session-management)

**Context:** Crate requires Spotify Premium. The OAuth flow produces an access token (1 hour TTL) and a refresh token. The access token is needed both server-side (for API proxy calls) and client-side (for the Web Playback SDK). The PRD requires persistent sessions so users are not re-prompted on every visit.

**Decision:**
- Implement Authorization Code Flow (not PKCE, not Implicit) because we have a server and need refresh tokens.
- Store refresh tokens in an HTTP-only secure cookie. Do NOT store them in localStorage or expose them to client JavaScript.
- Store access tokens in an HTTP-only secure cookie as well, with a short max-age matching Spotify's 1-hour TTL.
- Implement a `/api/auth/token` Route Handler that returns a fresh access token to the client for Web Playback SDK initialization. This endpoint reads the refresh token from the cookie, refreshes if needed, and returns the access token in the response body.
- Use `iron-session` or a similar encrypted cookie library for session management. No external session store needed for MVP.

**Rationale:**
- Authorization Code Flow is the correct OAuth flow when you have a server-side component and need long-lived sessions via refresh tokens.
- HTTP-only cookies prevent XSS attacks from stealing tokens.
- The Web Playback SDK needs an access token in JavaScript, so we must expose it via an API call, but the refresh token (which grants indefinite access) stays server-side only.
- Encrypted cookies avoid the need for a session database (Supabase, Redis, etc.) at MVP scale.

**Trade-offs:**
- The client must call `/api/auth/token` before initializing the Playback SDK and periodically to refresh. This adds a network call but is standard practice.
- Cookie-based sessions are limited to the same domain. This is fine for a single web app.

**What would change this:** If we added a native iOS app, we would need a different token storage mechanism for that client (Keychain). The server-side refresh flow would remain the same.

---

## ADR-005: Multi-Layer Caching Strategy

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.5 -- Caching Strategy](./Spotify%20Album%20UI%20Redesign.md#75-caching-strategy)

**Context:** The genre-to-album pipeline (ADR-002) is API-call-intensive. Spotify's rate limits are calculated on a rolling 30-second window and are not published as exact numbers. With the February 2026 removal of batch endpoints, individual fetches are more expensive. Genre taxonomy results are relatively stable -- the top albums in "rock" do not change minute to minute. With the development mode limit of 5 users, rate limits are less of a concern at MVP, but the architecture should be ready for growth.

**Decision:** Implement three caching layers:
1. **Server-side in-memory cache (primary):** Cache genre-to-album results in a lightweight in-memory store (e.g., `node-cache` or a simple Map with TTL) in the Next.js server process. TTL of 15-30 minutes. Cache key = genre combination + page number.
2. **HTTP cache headers:** Set `Cache-Control` headers on API proxy responses so Vercel's CDN edge and the browser cache repeated requests.
3. **Client-side state cache:** Once albums are fetched for a genre selection, keep them in client-side state (Zustand store). Only re-fetch if the user changes genre selections or the data is stale.

**Rationale:**
- In-memory cache is the simplest thing that works at MVP scale. No external dependency (Redis, Supabase) needed.
- 15-30 minute TTL balances freshness (new albums do get indexed) with API budget conservation.
- Client-side caching ensures that navigating to an album detail and back does not trigger a re-fetch.
- Edge caching via Vercel CDN adds a free layer for frequently requested genres.

**Trade-offs:**
- In-memory cache does not survive server restarts or scale across multiple serverless instances. At MVP scale (5 users), this is irrelevant. If we scale beyond MVP, we would add Redis or Vercel KV.
- Stale data for up to 30 minutes. Acceptable for album discovery -- users will not notice if a newly released album takes 30 minutes to appear in a genre listing.

**What would change this:** Scaling beyond ~100 concurrent users, or needing sub-minute data freshness (no foreseeable reason for this).

---

## ADR-006: Zustand for Client-Side State Management

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.9 -- Client-Side State](./Spotify%20Album%20UI%20Redesign.md#79-client-side-state-zustand-store)

**Context:** The client needs to manage: (a) current genre/sub-genre selections, (b) loaded album data per genre selection, (c) scroll position, (d) playback state (current track, play/pause, progress), (e) favorites list. These are all client-side concerns that need to persist across view transitions (browse <-> album detail) but not across sessions.

**Decision:** Use Zustand for client-side state management. Single store with slices for genres, albums, playback, and favorites.

**Rationale:**
- Zustand is lightweight (~1KB), has no boilerplate, and works well with React 18+ and Next.js App Router.
- It avoids the overhead of Redux or the complexity of React Context for cross-component state.
- Zustand stores persist across React re-renders and route transitions without any special configuration, which solves the scroll-position-preservation requirement naturally.
- The playback state needs to be globally accessible (the footer is always visible), and Zustand makes this trivial.

**Trade-offs:**
- Another dependency. But at 1KB and zero config, the cost is negligible.
- React Context could technically work for this, but Context triggers re-renders of all consumers on any state change. For a playback progress bar updating every second, this would cause performance issues. Zustand's selector-based subscriptions avoid this.

**What would change this:** If state needs became significantly more complex (unlikely given the app's intentional simplicity), we might consider a more structured solution. But the PRD's "three views, no settings, no modes" philosophy means state will stay simple.

---

## ADR-007: Favorites Stored in Spotify's Library (Not Supabase)

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.7 -- Favorites](./Spotify%20Album%20UI%20Redesign.md#77-favorites)

**Context:** The PRD asks whether favorites should sync with Spotify's saved albums or be Crate-specific. Storing favorites requires a decision about persistence: Spotify's library API, or our own database (Supabase).

**Decision:** Use Spotify's library endpoints (`PUT /me/library`, `GET /me/albums`, `DELETE /me/library`) for favorites. Do not introduce Supabase or any external database for MVP.

**Rationale:**
- Spotify's library endpoints survived the February 2026 changes (they moved from `/me/albums` to `/me/library` for writes, but the functionality is preserved).
- Using Spotify's library means favorites are automatically synced -- if a user saves an album in Spotify's native app, it appears in Crate's favorites, and vice versa. This is a better user experience than a siloed collection.
- Eliminates the need for a database, user management, and data synchronization logic. Massive reduction in MVP complexity.
- No Supabase setup, no schema design, no row-level security, no sync conflicts.

**Trade-offs:**
- We are dependent on Spotify's library API continuing to exist. Given they just reorganized it (not removed it) in February 2026, this seems stable.
- Users cannot have a "Crate-only" favorites list separate from their Spotify library. This is a product decision -- the sync behavior is a feature, not a bug. If the product team disagrees, we would need Supabase.
- If Spotify's library has a large number of saved albums, loading the Favorites view could be slow. We would paginate this the same way we paginate genre results.

**What would change this:** A product decision that Crate favorites must be independent of Spotify's library. Or if Spotify removes the library endpoints entirely.

---

## ADR-008: Genre Taxonomy as Static JSON Configuration

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.8 -- Genre Taxonomy Storage](./Spotify%20Album%20UI%20Redesign.md#78-genre-taxonomy-storage)

**Context:** The PRD specifies the genre taxonomy as a product-managed configuration. It is a two-tier tree mapping super-genres to sub-categories, where each sub-category maps to one or more Spotify genre query terms.

**Decision:** Store the taxonomy as a static JSON file (`/src/config/genres.json`) checked into the repository. No database, no CMS, no admin UI.

**Rationale:**
- The taxonomy is small (15 top-level categories, ~100 sub-categories) and changes infrequently.
- JSON is human-readable and editable by the product team (or anyone who can edit a file).
- Validated at build time with Zod to catch structural errors before deployment.
- No runtime dependency on an external data source for something this stable.

**Trade-offs:**
- Updating the taxonomy requires a code commit and deployment. At the frequency this will change (quarterly at most), this is fine.
- No admin UI for non-technical taxonomy editors. If the product team needs to update it frequently without engineering help, we could move it to a CMS or Supabase table later.

**Schema (TypeScript/Zod):**

```typescript
const GenreTaxonomy = z.array(z.object({
  id: z.string(),           // e.g., "rock"
  label: z.string(),        // e.g., "Rock"
  subCategories: z.array(z.object({
    id: z.string(),         // e.g., "indie-alternative"
    label: z.string(),      // e.g., "Indie / Alternative"
    spotifyGenres: z.array(z.string()), // e.g., ["indie", "alternative", "indie rock"]
  })),
}));
```

**What would change this:** If the product team needs to update the taxonomy more than once a month without engineering involvement, we would add a simple admin capability or move it to a database.

---

## ADR-009: Spotify Web Playback SDK for In-Browser Playback

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.4 -- Playback Architecture](./Spotify%20Album%20UI%20Redesign.md#74-playback-architecture)

**Context:** The PRD requires full playback (play, pause, prev, next, scrubber, volume) of complete albums. Spotify's Web Playback SDK creates a playback device in the browser that can be controlled via the Player API.

**Decision:** Use the Web Playback SDK for all desktop browser playback. Load it via the official script tag. Transfer playback to the Crate device on connection. Expose playback controls through the Player API endpoints, called from our API proxy.

**Rationale:**
- The Web Playback SDK is the only supported way to play Spotify content in a browser.
- It handles DRM, audio decoding, and streaming -- we just need to control it.
- The Player API (start/resume, pause, skip, seek, volume) endpoints are all still available after the February 2026 changes.

**Key implementation notes:**
- The SDK needs a fresh access token. Our `/api/auth/token` endpoint provides this (see ADR-004).
- The SDK creates a "device" that appears in the user's Spotify Connect device list. We must call `PUT /me/player` to transfer playback to this device when the user first plays something.
- We must handle the `player_state_changed` event to keep our Zustand playback state in sync with actual playback (see ADR-006).
- Album playback is initiated via `PUT /me/player/play` with a `context_uri` (the album's Spotify URI) and optionally an `offset` (to start from a specific track).

**Trade-offs:**
- The SDK only works in desktop/laptop browsers. Mobile browsers (Safari on iOS, Chrome on Android) do NOT support the Web Playback SDK due to autoplay restrictions and background audio limitations.
- On mobile, we fall back to Spotify Connect (see ADR-010). This is a significant UX gap for a "mobile-first" product.

**What would change this:** If Spotify released mobile browser support for the Web Playback SDK (unlikely). Or if we shipped a native iOS app, which would use the Spotify iOS SDK instead.

---

## ADR-010: Mobile Playback via Spotify Connect Fallback

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.4 -- Playback Architecture](./Spotify%20Album%20UI%20Redesign.md#74-playback-architecture)

**Context:** ADR-009 notes that the Web Playback SDK does not work on mobile browsers. The PRD says the app is "mobile-first." This is a direct conflict that must be addressed.

**Decision:** On mobile browsers, use the Spotify Connect API to control playback on the user's active Spotify device (their phone's Spotify app, a speaker, etc.) rather than playing audio in the browser.

**Flow:**
1. Detect mobile browser (User-Agent or feature detection -- check if `window.Spotify` SDK loads successfully).
2. If Web Playback SDK is not available, use `GET /me/player/devices` to find the user's active device.
3. Use `PUT /me/player/play` with the target `device_id` to start playback on that device.
4. All transport controls (pause, skip, seek) work via the same Player API endpoints, just targeting the external device instead of the in-browser player.

**Rationale:**
- This is how Spotify's own web player works on mobile -- it becomes a remote control for another device.
- The Player API endpoints are identical whether targeting an in-browser SDK device or an external device. The only difference is the `device_id` parameter.
- Users on mobile will likely have the Spotify app installed (since they need Premium anyway).

**Trade-offs:**
- The user must have Spotify open on another device for this to work. If they have no active device, we need to show a clear message: "Open Spotify on your phone or another device to start listening."
- Playback state sync may be slightly delayed compared to the in-browser SDK (polling vs. events).
- The experience is not as seamless as in-browser playback. This is a known limitation of the web platform, not something we can engineer around.

**What would change this:** A native iOS app (which would use the Spotify iOS SDK for direct playback) or mobile browser support for the Web Playback SDK.

---

## ADR-011: Vercel for Deployment

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.1 -- Tech Stack](./Spotify%20Album%20UI%20Redesign.md#71-tech-stack)

**Context:** We need to deploy a Next.js application with server-side Route Handlers (for the API proxy and OAuth flow). The app has no database and no heavy compute requirements.

**Decision:** Deploy on Vercel.

**Rationale:**
- Vercel is the maker of Next.js. Zero-config deployment, automatic preview deployments on PRs, built-in CDN.
- Route Handlers run as serverless functions, which is perfect for our bursty API proxy pattern (idle most of the time, active during user sessions).
- Free tier is sufficient for MVP with 5 users.
- Built-in analytics, logging, and edge caching.

**Trade-offs:**
- Vendor lock-in to Vercel's platform. Mitigated by the fact that Next.js can be self-hosted or deployed to other platforms (Netlify, AWS) if needed.
- Serverless cold starts could add latency to the first API proxy call in a session. In practice, Vercel keeps functions warm for active apps.
- In-memory caching (ADR-005) does not persist across serverless invocations. At MVP scale this is acceptable -- cache misses just mean an extra Spotify API call.

**What would change this:** Cost concerns at scale (Vercel's pricing can spike with high traffic), or a need for persistent server processes (e.g., WebSocket connections). Neither applies to MVP.

---

## ADR-012: Infinite Scroll via Cursor-Based Pagination

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.6 -- Infinite Scroll and Pagination](./Spotify%20Album%20UI%20Redesign.md#76-infinite-scroll-and-pagination)

**Context:** The album grid uses infinite scroll. The Spotify Search API supports `offset` and `limit` parameters, with offset capped at 1000. Our genre-to-album pipeline (ADR-002) aggregates results from multiple artist searches and album fetches.

**Decision:** Implement cursor-based pagination in our API proxy layer. The client requests pages by page number. The server translates this into the appropriate Spotify API offset/limit calls, aggregates and deduplicates, and returns a page of albums along with a `hasMore` boolean.

**Implementation:**
- Page size: 30 albums.
- The server maintains a virtual cursor across the aggregated, deduplicated result set.
- Prefetch: when the client requests page N, the server begins fetching page N+1 in the background (or returns it from cache).
- Intersection Observer on the client to trigger the next page load when the user scrolls to the bottom of the current set.

**Rationale:**
- Client-side pagination logic would be complex because our data comes from multiple Spotify API calls that need aggregation. Keeping this server-side is cleaner.
- 30 albums per page (5 rows of 6 on desktop, 10 rows of 3 on mobile) gives enough content for smooth scrolling without overfetching.
- Spotify's offset cap of 1000 means we can serve at most ~1000 unique albums per genre query. This is plenty for browsing -- no one scrolls through 1000 albums.

**Trade-offs:**
- Server-side pagination adds complexity. But the alternative (sending all results at once) is not feasible given the multi-step pipeline.
- The 1000-offset cap is a hard limit from Spotify. If a genre has more than 1000 relevant artists, we will not surface all possible albums. This is acceptable for a discovery-oriented product.

**What would change this:** If we needed truly deep catalog exploration (unlikely for a "crate digging" product focused on discovery).

---

## ADR-013: No Supabase or External Database for MVP

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.1 -- Tech Stack](./Spotify%20Album%20UI%20Redesign.md#71-tech-stack)

**Context:** Our standard stack includes Supabase. We evaluated whether Crate needs it.

**Decision:** Do not use Supabase (or any external database) for MVP.

**Rationale:**
- Auth is handled by Spotify OAuth + encrypted cookies (ADR-004). No user table needed.
- Favorites are stored in Spotify's library (ADR-007). No favorites table needed.
- Genre taxonomy is a static JSON file (ADR-008). No taxonomy table needed.
- Caching is in-memory (ADR-005). No cache table needed.
- There is literally nothing to store in a database for MVP.

**Trade-offs:**
- If we later need Crate-specific data (listening history, Crate-only favorites, user preferences), we will need to introduce a database. Supabase would be the natural choice.
- No analytics data store. We rely on Vercel Analytics and Spotify's own usage metrics for MVP.

**What would change this:** Any feature that requires persistent, user-specific data beyond what Spotify's API provides. Examples: Crate-only favorites, listening history, user preferences, social features.

---

## ADR-014: Scoped Spotify Permissions

**Date:** 2026-02-09
**Status:** Accepted
**PRD Reference:** [Section 7.3 -- Authentication and Session Management](./Spotify%20Album%20UI%20Redesign.md#73-authentication-and-session-management)

**Context:** Spotify OAuth scopes determine what the app can access. We should request the minimum scopes necessary.

**Decision:** Request the following scopes:

| Scope | Purpose |
|-------|---------|
| `streaming` | Required for Web Playback SDK |
| `user-read-email` | Required to identify the user and verify Premium status |
| `user-read-private` | Required to check the user's subscription level (Premium check) |
| `user-library-read` | Required to read saved albums (Favorites) |
| `user-library-modify` | Required to save/unsave albums (Favorites) |
| `user-modify-playback-state` | Required to control playback (play, pause, skip, seek, volume, transfer device) |
| `user-read-playback-state` | Required to read current playback state and available devices |
| `user-read-currently-playing` | Required to display current track in the playback footer |

**Rationale:**
- These are the minimum scopes for the feature set described in the PRD.
- No scope for playlist access, social features, or user profile data beyond email/subscription level.
- Requesting minimal scopes builds user trust at the OAuth consent screen.

**What would change this:** Adding features that require additional Spotify access (e.g., playlist creation, social features).
