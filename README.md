# Crate

A focused album listening experience built on Spotify. Browse by genre, pick an album, listen start to finish.

**Status: Pre-development** -- Product requirements and architecture are complete. Engineering scaffolding has not yet started.

---

## What is Crate?

Crate is a single-purpose web interface for Spotify that removes playlists, podcasts, algorithms, and social features. It presents albums as a grid of cover art organized by a two-tier genre taxonomy. The experience is designed to feel like browsing a record store, not using a streaming app.

For the full product specification, see the [PRD](./Spotify%20Album%20UI%20Redesign.md).

## Documentation

| Document | Description |
|----------|-------------|
| [PRD](./Spotify%20Album%20UI%20Redesign.md) | Product requirements, UX specification, and architecture |
| [DECISIONS.md](./DECISIONS.md) | Architectural decision records (14 ADRs) |
| [project_context.md](./project_context.md) | Quick-reference project context for new contributors |

## Tech Stack

- **Framework:** Next.js 14+ (App Router)
- **Styling:** Tailwind CSS
- **State Management:** Zustand
- **Validation:** Zod
- **Testing:** Vitest + React Testing Library
- **Deployment:** Vercel
- **Auth:** Spotify OAuth (Authorization Code Flow)
- **Playback:** Spotify Web Playback SDK (desktop), Spotify Connect (mobile fallback)

## Prerequisites

- Node.js 18+
- Spotify Developer account with a registered application
- Spotify Premium account (required for Web Playback SDK)
- Vercel account (for deployment)

## Getting Started

> This section will be filled in once the project is scaffolded. The following is a placeholder for the expected setup flow.

```bash
# Clone the repository
git clone <repo-url>
cd crate

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Fill in SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, and NEXTAUTH_SECRET

# Run the development server
npm run dev
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `SPOTIFY_CLIENT_ID` | From Spotify Developer Dashboard |
| `SPOTIFY_CLIENT_SECRET` | From Spotify Developer Dashboard |
| `SPOTIFY_REDIRECT_URI` | OAuth callback URL (e.g., `http://localhost:3000/api/auth/callback`) |
| `SESSION_SECRET` | Encryption key for iron-session cookies (32+ characters) |

## Key Constraints

- **5-user limit:** Spotify Development Mode restricts the app to 5 authorized users. Public launch requires Extended Quota Mode.
- **Mobile playback:** The Web Playback SDK does not work on mobile browsers. On mobile, the Spotify app must be running for playback via Spotify Connect.
- **No database:** MVP has no persistent storage. Auth uses encrypted cookies, favorites sync with Spotify's library, and the genre taxonomy is a static JSON file.

## License

Private project. Not open source.
