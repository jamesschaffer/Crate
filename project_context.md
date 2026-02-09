# Project Context -- Crate

## Overview

Crate is a single-purpose web application built on top of Spotify that strips away playlists, podcasts, algorithmic feeds, and social features to deliver a focused album listening experience. Users browse a two-tier genre taxonomy (inspired by musicmap.info), see a grid of album cover art, pick an album, and listen to it start to finish. The interface is designed to feel like thumbing through records in a store, not using a software application.

## Current Status

**Pre-development.** Product requirements and architecture are complete. The project is ready for engineering scaffolding.

- PRD: Complete (Draft -- Architecture Complete)
- Architecture decisions: 14 ADRs documented and accepted
- Code: Not yet started
- Design: Not yet started (PRD describes UX; visual design is pending)

## Tech Stack

| Layer              | Choice                         |
|--------------------|--------------------------------|
| Framework          | Next.js 14+ (App Router)       |
| Styling            | Tailwind CSS                   |
| State Management   | Zustand                        |
| Validation         | Zod                            |
| Testing            | Vitest + React Testing Library |
| Deployment         | Vercel                         |
| Database           | None for MVP                   |
| Auth               | Spotify OAuth (Authorization Code Flow) with `iron-session` encrypted cookies |
| Playback (Desktop) | Spotify Web Playback SDK       |
| Playback (Mobile)  | Spotify Connect (fallback)     |

## Key Constraints

- **Spotify Development Mode:** Limited to 5 authorized users. Public launch requires Extended Quota Mode (registered business, 250K+ MAU). This is a business task, not an engineering blocker.
- **Mobile playback:** The Web Playback SDK does not work on mobile browsers. On mobile, Crate acts as a remote control for the user's Spotify app via Spotify Connect. The user must have the Spotify app open.
- **API rate limits:** Spotify's rate limits are undisclosed but enforced on a rolling 30-second window. The genre-to-album pipeline is API-call-intensive, making server-side caching (15-30 min TTL) mandatory.
- **Genre-to-album indirection:** Spotify associates genres with artists, not albums. Fetching albums by genre requires a two-step pipeline (search artists by genre, then fetch their albums). This runs server-side and is the most architecturally significant part of the system.
- **February 2026 API removals:** Spotify removed batch artist/album endpoints, Browse categories, and new releases endpoints. The Search API with genre filter on artists remains viable.

## Key Documents

| Document | Path | Description |
|----------|------|-------------|
| PRD | [Spotify Album UI Redesign.md](./Spotify%20Album%20UI%20Redesign.md) | Full product requirements, UX specification, and architecture |
| Decision Log | [DECISIONS.md](./DECISIONS.md) | 14 architectural decision records with rationale |
| README | [README.md](./README.md) | Project overview and getting started |

## Architecture Summary

The application has three views (Login, Browse, Album Detail) and no database. All Spotify API calls route through Next.js server-side Route Handlers, which handle OAuth token management, the genre-to-album pipeline, rate limit protection, and caching. The client manages UI state (genre selections, loaded albums, scroll position, playback state) in a single Zustand store. Favorites sync with Spotify's saved albums library rather than a separate data store.

## Open Items

- **Genre taxonomy mapping:** The two-tier taxonomy is defined conceptually (15 super-genres, ~100 sub-categories) but the final mapping of every Spotify genre seed to the taxonomy tree needs to be completed. This is a product/design task.
- **Visual design:** The PRD defines the UX and layout but not the visual design system (colors, typography, spacing). Design work is pending.
- **Super-genre count:** User testing may refine the proposed 15 top-level categories.
- **Extended Quota Mode:** Required for public launch. Needs a registered business entity.
