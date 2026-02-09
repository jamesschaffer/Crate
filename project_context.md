# Project Context -- Crate

## Overview

Crate is a single-purpose native app built on Apple Music that strips away playlists, podcasts, algorithmic feeds, and social features to deliver a focused album listening experience. Users browse a two-tier genre taxonomy (inspired by musicmap.info), see a grid of album cover art, pick an album, and listen to it start to finish. The interface is designed to feel like thumbing through records in a store, not using a software application.

Crate is a SwiftUI multiplatform app targeting iOS and macOS, powered by MusicKit for Apple Music integration. There is no server or backend -- the app is fully client-side.

## Current Status

**Pre-development.** Product requirements and architecture are complete. The project is ready for engineering scaffolding.

- PRD: Complete (Draft -- Architecture Complete, MusicKit Pivot)
- Architecture decisions: 15 ADRs documented and accepted (ADR-100 through ADR-114)
- Code: Not yet started
- Design: Not yet started (PRD describes UX; visual design is pending)

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
- **Charts endpoint popularity bias.** The Apple Music Charts API returns albums ranked by current streaming popularity, not all-time catalog depth. Deep catalog albums from older decades may not appear unless they are currently popular. This is acceptable for MVP; deep catalog browsing can be supplemented with search later.
- **Apple Music genre granularity.** Apple Music has roughly 20-30 top-level genres, which is more conservative than some platforms with hundreds of micro-genres. Some sub-categories in the taxonomy may map to the same genre ID. This needs validation during taxonomy mapping.
- **Rate limits.** Apple Music API allows approximately 20 requests per second per user token. With 1 API call per page of album results, this is nearly a non-issue. Defensive debounce and 429 retry are implemented as safety measures.
- **Token management is automatic.** MusicKit handles developer tokens and user tokens at the system level. There are no tokens to store, refresh, or rotate. The ~6-month token expiry concern applies only to the REST API used from servers, not to native MusicKit apps.
- **Apple ecosystem only.** No Android, no web, no Windows. The app requires an Apple device with iOS 17+ or macOS 14+. Cross-platform would require a separate effort (MusicKit.js for web, or a full rebuild for Android).
- **No server needed.** MusicKit handles auth, API access, and playback on-device. No client secret, no OAuth flow, no API proxy. The entire app is client-side.

## Key Documents

| Document | Path | Description |
|----------|------|-------------|
| PRD | [PRD.md](./PRD.md) | Full product requirements, UX specification, and architecture |
| Decision Log | [DECISIONS.md](./DECISIONS.md) | 15 architectural decision records (ADR-100 through ADR-114) |
| README | [README.md](./README.md) | Project overview and getting started |

## Architecture Summary

The application has three views (Auth, Browse, Album Detail) and no backend. All Apple Music API calls are made directly from the app via MusicKit. Auth is handled by the system via a single MusicKit authorization dialog. The genre-to-album pipeline uses the Apple Music Catalog Charts endpoint, which returns albums by genre in a single API call per page. Playback uses `ApplicationMusicPlayer` with an independent queue, providing native background audio, lock screen controls, and Now Playing integration automatically. Favorites are stored locally via SwiftData and are not synced to the user's Apple Music library. The UI is built with SwiftUI using MVVM with `@Observable` view models. A single multiplatform codebase targets both iOS and macOS with 95%+ shared code.

## Open Items

- **Genre taxonomy mapping.** The two-tier taxonomy is defined conceptually (15 super-genres, ~100 sub-categories) but the mapping to Apple Music genre IDs needs to be completed. Apple Music's own genre hierarchy may be close enough to use directly (Open Question N1 in the PRD).
- **Visual design.** The PRD defines the UX and layout but not the visual design system (colors, typography, spacing). Design work is pending.
- **Super-genre count.** User testing may refine the proposed 15 top-level categories. Apple Music's genre structure may influence the final count.
- **Charts depth testing.** Apple does not document a maximum offset for the charts endpoint. Empirical testing is needed to determine how many albums per genre we can paginate through.
- **Hardware testing plan.** MusicKit requires physical devices. Need at least one iPhone and one Mac with Apple Music subscriptions for development.
