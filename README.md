# Fastest Music Vol. 2

A full-featured Apple Music client built with Flutter and native MusicKit, backed by an Elixir/Phoenix API for multi-source search and artwork caching.

<!-- Screenshots — replace placeholders after capturing from device -->
<p align="center">
  <img src="screenshots/home.png" width="200" alt="Home Screen" />
  <img src="screenshots/now-playing.png" width="200" alt="Now Playing" />
  <img src="screenshots/browse.png" width="200" alt="Browse" />
  <img src="screenshots/library.png" width="200" alt="Library" />
</p>

## Features

### Playback
- Full Apple Music playback via native MusicKit
- Now Playing screen with artwork-derived gradient backgrounds
- Glassmorphism transport controls with shuffle and repeat toggles
- Mini player bar persistent across all tabs
- Swipe-to-dismiss and tap-to-toggle elapsed/remaining time

### Discovery
- Home feed with recently played songs and curated discovery sections
- Browse tab with full-text search across songs, albums, and artists
- Genre chip filters (Rock, Pop, Hip-Hop, Electronic, Jazz, etc.)
- Year range filtering for targeted discovery
- World tab with country-based music exploration
- Decade browser for era-based discovery

### Library
- "My Music" tab with segmented control: Albums | Artists | Songs | Playlists
- A-Z alphabetical scroll index (iOS Contacts-style) on all tabs
- Section headers grouping items by first letter
- Album grid with artwork, title, and artist
- Artist list with circular artwork and genre labels
- Song list using consistent SongTile pattern
- Playlist management: create, view, and add songs

### Visual Polish
- Shimmer loading placeholders on all artwork
- Stacked artwork preview hero in search results and discovery
- Year badge overlays on album artwork
- Artist nationality flags on world browse
- Dominant color extraction for immersive Now Playing UI
- Bounce animation on play/pause

## Architecture

```
lib/
  app/             # App shell, router, theme
  core/
    config/        # API config, constants
    platform/      # MusicKit platform interface + MethodChannel impl
  models/          # Freezed data models (Song, Album, Artist, Playlist, etc.)
  providers/       # Riverpod providers (state management layer)
  screens/         # Feature screens (each in its own directory)
  services/        # MusicKit service, MusicPlayer service, federated service
  shared_widgets/  # Reusable widgets (ArtworkImage, SongTile, AlphabetIndex, etc.)

ios/Runner/MusicKit/
  MusicKitService.swift        # Native MusicKit API calls
  MusicKitPlugin.swift         # MethodChannel handler
  MusicPlayerController.swift  # Playback control (play, pause, shuffle, repeat)
  PlaylistController.swift     # Playlist CRUD
  PlaybackStateStreamHandler.swift  # EventChannel for playback state
  Mappers/                     # Swift -> Dict mappers (Song, Album, Artist, etc.)

backend/fastest_music_api/     # Elixir/Phoenix backend
  lib/fastest_music_api/
    cache/         # ETS cache + cache warmer
    sources/       # iTunes Search, MusicBrainz, circuit breaker
    artwork/       # Multi-level artwork resolver (L1/L2/L3)
    search/        # Search engine + filters
    health/        # Health checker
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Riverpod** over BLoC | Compile-safe providers, less boilerplate, better testability |
| **Freezed** models | Immutable data classes with JSON serialization for free |
| **MethodChannel** to MusicKit | Apple Music requires native MusicKit — no pure Dart option |
| **Backend-first search** | Elixir backend aggregates iTunes + MusicBrainz, caches artwork |
| **MusicKit fallback** | Direct MusicKit queries when backend is unavailable |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x, Dart |
| **State** | Riverpod (AsyncNotifier pattern) |
| **Routing** | GoRouter with StatefulShellRoute |
| **Native** | Swift, Apple MusicKit |
| **Backend** | Elixir, Phoenix, Ecto, PostgreSQL |
| **Hosting** | Fly.io (sjc region) |
| **Data Sources** | Apple MusicKit, iTunes Search API, MusicBrainz |

## Getting Started

### Prerequisites

- Flutter SDK (3.5+)
- Xcode 15+ with MusicKit entitlement
- Apple Developer account (for device deployment)
- Elixir 1.15+ and PostgreSQL 17 (for backend)

### Run the Flutter app

```bash
# Install dependencies
flutter pub get

# Generate Freezed models
dart run build_runner build --delete-conflicting-outputs

# Run on iOS simulator
flutter run

# Run on physical device
flutter run -d <device-id>
```

### Run the backend

```bash
cd backend/fastest_music_api

# Start PostgreSQL
brew services start postgresql@17

# Setup database
mix setup

# Start the server
mix phx.server
```

The backend runs at `http://localhost:4000` locally and `https://fastest-music-api.fly.dev` in production.

## Deployment

### Backend (Fly.io)

```bash
cd backend/fastest_music_api
fly deploy
```

### iOS

Build and deploy via Xcode or:

```bash
flutter build ios
```

## License

Private project. All rights reserved.
