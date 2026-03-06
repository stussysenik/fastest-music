import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../core/cache/local_cache_service.dart';
import '../models/music_authorization_status.dart';
import 'authorization_provider.dart';
import 'local_cache_provider.dart';

/// Providers for the user's personal Apple Music library with SWR caching.
///
/// ## SWR for library data (educational)
///
/// The user's library changes infrequently (when they add/remove items),
/// so cached data is almost always still valid. By serving from Hive first,
/// the Library tab renders instantly on warm starts instead of showing
/// a spinner while MusicKit fetches from Apple's servers.

// ── Albums ──

final userLibraryAlbumsProvider =
    AsyncNotifierProvider<UserLibraryAlbumsNotifier, List<Album>>(
        UserLibraryAlbumsNotifier.new);

class UserLibraryAlbumsNotifier extends AsyncNotifier<List<Album>> {
  static const _staleDuration = Duration(minutes: 10);

  @override
  Future<List<Album>> build() async {
    final cache = ref.read(localCacheProvider);
    final cached = _readCache(cache);
    if (cached != null && cached.isNotEmpty) {
      state = AsyncData(cached);
      _revalidateInBackground(cache);
      return cached;
    }
    return _fetchFromNetwork(cache);
  }

  List<Album>? _readCache(LocalCacheService cache) {
    final jsonList = cache.getJsonList(LocalCacheService.libraryAlbumsKey);
    if (jsonList == null) return null;
    try {
      return jsonList.map((j) => Album.fromJson(j)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Album>> _fetchFromNetwork(LocalCacheService cache) async {
    // Gate: only call MusicKit if the user has granted library access.
    final authStatus = await ref.read(authorizationProvider.future);
    if (authStatus != MusicAuthorizationStatus.authorized) return [];

    final service = ref.read(musicKitServiceProvider);
    final albums = await service.getUserLibraryAlbums();
    await cache.putJsonList(
      LocalCacheService.libraryAlbumsKey,
      albums.map((a) => a.toJson()).toList(),
    );
    return albums;
  }

  Future<void> _revalidateInBackground(LocalCacheService cache) async {
    if (!cache.isStale(LocalCacheService.libraryAlbumsKey, _staleDuration)) {
      return;
    }
    try {
      final fresh = await _fetchFromNetwork(cache);
      state = AsyncData(fresh);
    } catch (_) {}
  }
}

// ── Songs ──

final userLibrarySongsProvider =
    AsyncNotifierProvider<UserLibrarySongsNotifier, List<Song>>(
        UserLibrarySongsNotifier.new);

class UserLibrarySongsNotifier extends AsyncNotifier<List<Song>> {
  static const _staleDuration = Duration(minutes: 10);

  @override
  Future<List<Song>> build() async {
    final cache = ref.read(localCacheProvider);
    final cached = _readCache(cache);
    if (cached != null && cached.isNotEmpty) {
      state = AsyncData(cached);
      _revalidateInBackground(cache);
      return cached;
    }
    return _fetchFromNetwork(cache);
  }

  List<Song>? _readCache(LocalCacheService cache) {
    final jsonList = cache.getJsonList(LocalCacheService.librarySongsKey);
    if (jsonList == null) return null;
    try {
      return jsonList.map((j) => Song.fromJson(j)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Song>> _fetchFromNetwork(LocalCacheService cache) async {
    final authStatus = await ref.read(authorizationProvider.future);
    if (authStatus != MusicAuthorizationStatus.authorized) return [];

    final service = ref.read(musicKitServiceProvider);
    final songs = await service.getUserLibrarySongs();
    await cache.putJsonList(
      LocalCacheService.librarySongsKey,
      songs.map((s) => s.toJson()).toList(),
    );
    return songs;
  }

  Future<void> _revalidateInBackground(LocalCacheService cache) async {
    if (!cache.isStale(LocalCacheService.librarySongsKey, _staleDuration)) {
      return;
    }
    try {
      final fresh = await _fetchFromNetwork(cache);
      state = AsyncData(fresh);
    } catch (_) {}
  }
}

// ── Artists ──

final userLibraryArtistsProvider =
    AsyncNotifierProvider<UserLibraryArtistsNotifier, List<Artist>>(
        UserLibraryArtistsNotifier.new);

class UserLibraryArtistsNotifier extends AsyncNotifier<List<Artist>> {
  static const _staleDuration = Duration(minutes: 10);

  @override
  Future<List<Artist>> build() async {
    final cache = ref.read(localCacheProvider);
    final cached = _readCache(cache);
    if (cached != null && cached.isNotEmpty) {
      state = AsyncData(cached);
      _revalidateInBackground(cache);
      return cached;
    }
    return _fetchFromNetwork(cache);
  }

  List<Artist>? _readCache(LocalCacheService cache) {
    final jsonList = cache.getJsonList(LocalCacheService.libraryArtistsKey);
    if (jsonList == null) return null;
    try {
      return jsonList.map((j) => Artist.fromJson(j)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Artist>> _fetchFromNetwork(LocalCacheService cache) async {
    final authStatus = await ref.read(authorizationProvider.future);
    if (authStatus != MusicAuthorizationStatus.authorized) return [];

    final service = ref.read(musicKitServiceProvider);
    final artists = await service.getUserLibraryArtists();
    await cache.putJsonList(
      LocalCacheService.libraryArtistsKey,
      artists.map((a) => a.toJson()).toList(),
    );
    return artists;
  }

  Future<void> _revalidateInBackground(LocalCacheService cache) async {
    if (!cache.isStale(LocalCacheService.libraryArtistsKey, _staleDuration)) {
      return;
    }
    try {
      final fresh = await _fetchFromNetwork(cache);
      state = AsyncData(fresh);
    } catch (_) {}
  }
}
