import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/music_authorization_status.dart';
import '../core/cache/local_cache_service.dart';
import 'authorization_provider.dart';
import 'backend_provider.dart';
import 'local_cache_provider.dart';

final recentlyPlayedProvider =
    AsyncNotifierProvider<RecentlyPlayedNotifier, List<Song>>(
        RecentlyPlayedNotifier.new);

class RecentlyPlayedNotifier extends AsyncNotifier<List<Song>> {
  /// SWR TTL — revalidate from network if cache is older than this.
  static const _staleDuration = Duration(minutes: 5);

  @override
  Future<List<Song>> build() async {
    final cache = ref.read(localCacheProvider);

    // Phase 1: Serve cached data instantly (~0.1ms Hive read).
    // This lets the UI render real data on frame 1 with no spinner.
    final cached = _readCache(cache);
    if (cached != null && cached.isNotEmpty) {
      state = AsyncData(cached);
      // Background revalidate — update silently if data changed.
      _revalidateInBackground(cache);
      return cached;
    }

    // No cache — fall through to network fetch.
    return _fetchFromNetwork(cache);
  }

  /// Read songs from Hive cache. Returns null if nothing cached.
  List<Song>? _readCache(LocalCacheService cache) {
    final jsonList = cache.getJsonList(LocalCacheService.recentlyPlayedKey);
    if (jsonList == null) return null;
    try {
      return jsonList.map((j) => Song.fromJson(j)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Fetch from MusicKit + resolve artwork, then update cache.
  Future<List<Song>> _fetchFromNetwork(LocalCacheService cache) async {
    final authStatus = await ref.read(authorizationProvider.future);
    if (authStatus != MusicAuthorizationStatus.authorized) {
      return [];
    }
    final service = ref.read(musicKitServiceProvider);
    final songs = await service.getRecentlyPlayed(limit: 25);
    final resolved = await _resolveArtwork(songs);

    // Persist to Hive for next cold start.
    await cache.putJsonList(
      LocalCacheService.recentlyPlayedKey,
      resolved.map((s) => s.toJson()).toList(),
    );

    return resolved;
  }

  /// Background revalidate: fetch fresh data without blocking UI.
  Future<void> _revalidateInBackground(LocalCacheService cache) async {
    if (!cache.isStale(LocalCacheService.recentlyPlayedKey, _staleDuration)) {
      return; // Cache is fresh enough, skip network call.
    }
    try {
      final fresh = await _fetchFromNetwork(cache);
      // Only update state if data actually changed.
      if (state.valueOrNull?.length != fresh.length ||
          (fresh.isNotEmpty &&
              state.valueOrNull?.first.id != fresh.first.id)) {
        state = AsyncData(fresh);
      }
    } catch (_) {
      // Network failed — stale data is still better than an error.
    }
  }

  /// Resolve missing artwork URLs via the backend's batch endpoint.
  Future<List<Song>> _resolveArtwork(List<Song> songs) async {
    final albumCoverService = ref.read(albumCoverServiceProvider);
    if (albumCoverService == null) return songs;

    final needsArtwork = songs
        .where((s) =>
            (s.artworkUrl == null || s.artworkUrl!.isEmpty) &&
            s.artistName.isNotEmpty &&
            s.albumTitle.isNotEmpty)
        .toList();

    if (needsArtwork.isEmpty) return songs;

    final seen = <String>{};
    final albums = <({String artist, String title})>[];
    for (final song in needsArtwork) {
      final key = '${song.artistName}|${song.albumTitle}';
      if (seen.add(key)) {
        albums.add((artist: song.artistName, title: song.albumTitle));
      }
    }

    final urlMap = await albumCoverService.batchGetArtworkUrls(albums);
    if (urlMap.isEmpty) return songs;

    return songs.map((song) {
      if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) return song;
      final key = '${song.artistName}|${song.albumTitle}';
      final resolvedUrl = urlMap[key];
      if (resolvedUrl != null) {
        return song.copyWith(artworkUrl: resolvedUrl);
      }
      return song;
    }).toList();
  }
}
