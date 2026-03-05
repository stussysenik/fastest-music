import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playback_state.dart';
import 'playback_provider.dart';
import 'backend_provider.dart';

/// In-memory cache for resolved artwork URLs.
///
/// ## Why a separate StateProvider? (educational)
///
/// The playback stream fires rapidly (every ~0.5s for time updates).
/// We don't want to re-resolve artwork on every tick — only when the
/// song changes and artworkUrl is null. This cache persists for the
/// session so artwork is resolved at most once per artist|album pair.
final _artworkCacheProvider =
    StateProvider<Map<String, String>>((ref) => {});

/// Enriched playback state that guarantees artwork when possible.
///
/// ## How it works (educational)
///
/// Watches the raw `playbackStateProvider` AsyncValue. When a new track
/// starts playing with a null `artworkUrl`, it fires a backend lookup
/// using `AlbumCoverService.getArtworkUrl(artist, album)`. The resolved
/// URL is cached in `_artworkCacheProvider` so subsequent events for the
/// same track get the cached URL instantly.
///
/// All UI consumers (NowPlaying, MiniPlayer) should use this provider
/// instead of the raw `playbackStateProvider`.
final enrichedPlaybackProvider = StreamProvider<PlaybackState>((ref) {
  final controller = StreamController<PlaybackState>();
  final albumCoverService = ref.read(albumCoverServiceProvider);

  ref.listen<AsyncValue<PlaybackState>>(playbackStateProvider, (prev, next) {
    next.whenData((state) async {
      // If artwork already present, pass through unchanged
      if (state.artworkUrl != null && state.artworkUrl!.isNotEmpty) {
        controller.add(state);
        return;
      }

      // Need both artist and album to resolve
      final artist = state.artistName;
      final album = state.albumTitle;
      if (artist == null ||
          artist.isEmpty ||
          album == null ||
          album.isEmpty) {
        controller.add(state);
        return;
      }

      // Check cache first
      final cacheKey = '$artist|$album';
      final cache = ref.read(_artworkCacheProvider);
      if (cache.containsKey(cacheKey)) {
        controller.add(state.copyWith(artworkUrl: cache[cacheKey]));
        return;
      }

      // Resolve from backend
      if (albumCoverService == null) {
        controller.add(state);
        return;
      }

      final url = await albumCoverService.getArtworkUrl(artist, album);
      if (url != null) {
        // Cache for future stream events
        ref.read(_artworkCacheProvider.notifier).update((prev) {
          return {...prev, cacheKey: url};
        });
        controller.add(state.copyWith(artworkUrl: url));
      } else {
        controller.add(state);
      }
    });
  });

  ref.onDispose(() => controller.close());
  return controller.stream;
});
