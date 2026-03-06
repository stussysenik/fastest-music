import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Zero-latency local data persistence using Hive.
///
/// ## Why Hive? (educational)
///
/// Hive is a lightweight, memory-mapped key-value store. Unlike SQLite,
/// reads don't cross a native bridge — they're direct Dart memory access.
/// This makes reads complete in ~0.1ms, fast enough to populate UI on
/// the very first frame before any network call returns.
///
/// ## Stale-While-Revalidate (SWR) pattern
///
/// Each cached entry stores a timestamp. Providers read from cache first
/// (instant), then fetch fresh data from the network in the background.
/// If the network data differs, the UI updates silently. This gives
/// the user instant perceived performance while keeping data fresh.
class LocalCacheService {
  static const String _recentlyPlayedBox = 'recently_played';
  static const String _discoveryFeedBox = 'discovery_feed';
  static const String _userLibraryAlbumsBox = 'user_library_albums';
  static const String _userLibrarySongsBox = 'user_library_songs';
  static const String _userLibraryArtistsBox = 'user_library_artists';
  static const String _artworkColorsBox = 'artwork_colors';
  static const String _metadataBox = 'cache_metadata';

  static const String _dataKey = 'data';
  static const String _timestampKey = 'timestamp';

  late Box _recentlyPlayed;
  late Box _discoveryFeed;
  late Box _libraryAlbums;
  late Box _librarySongs;
  late Box _libraryArtists;
  late Box _artworkColors;
  late Box _metadata;

  /// Initialize all Hive boxes. Call once before runApp().
  Future<void> init() async {
    await Hive.initFlutter();
    _recentlyPlayed = await Hive.openBox(_recentlyPlayedBox);
    _discoveryFeed = await Hive.openBox(_discoveryFeedBox);
    _libraryAlbums = await Hive.openBox(_userLibraryAlbumsBox);
    _librarySongs = await Hive.openBox(_userLibrarySongsBox);
    _libraryArtists = await Hive.openBox(_userLibraryArtistsBox);
    _artworkColors = await Hive.openBox(_artworkColorsBox);
    _metadata = await Hive.openBox(_metadataBox);
  }

  // ── Generic typed cache operations ──

  /// Read cached JSON list from a box. Returns null if no cached data.
  List<Map<String, dynamic>>? getJsonList(String boxName) {
    final box = _boxFor(boxName);
    final raw = box.get(_dataKey);
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw as String);
      return (decoded as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  /// Write a list of JSON-serializable items to a box.
  Future<void> putJsonList(
      String boxName, List<Map<String, dynamic>> items) async {
    final box = _boxFor(boxName);
    await box.put(_dataKey, json.encode(items));
    await _metadata.put('${boxName}_$_timestampKey',
        DateTime.now().millisecondsSinceEpoch);
  }

  /// Get the timestamp of the last cache write for a box.
  DateTime? getLastUpdated(String boxName) {
    final ms = _metadata.get('${boxName}_$_timestampKey');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms as int);
  }

  /// Check if cached data is older than [maxAge].
  bool isStale(String boxName, Duration maxAge) {
    final lastUpdated = getLastUpdated(boxName);
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated) > maxAge;
  }

  // ── Artwork color cache ──

  /// Get a cached color value for an artwork URL. Returns null if not cached.
  int? getArtworkColor(String url) {
    final value = _artworkColors.get(url);
    return value is int ? value : null;
  }

  /// Cache a color value for an artwork URL.
  Future<void> putArtworkColor(String url, int colorValue) async {
    await _artworkColors.put(url, colorValue);
  }

  /// Get all cached artwork colors as a map (URL -> color int).
  Map<String, int> getAllArtworkColors() {
    final result = <String, int>{};
    for (final key in _artworkColors.keys) {
      final value = _artworkColors.get(key);
      if (value is int) {
        result[key as String] = value;
      }
    }
    return result;
  }

  // ── Box name constants for providers ──

  static const String recentlyPlayedKey = _recentlyPlayedBox;
  static const String discoveryFeedKey = _discoveryFeedBox;
  static const String libraryAlbumsKey = _userLibraryAlbumsBox;
  static const String librarySongsKey = _userLibrarySongsBox;
  static const String libraryArtistsKey = _userLibraryArtistsBox;

  // ── Private helpers ──

  Box _boxFor(String name) {
    return switch (name) {
      _recentlyPlayedBox => _recentlyPlayed,
      _discoveryFeedBox => _discoveryFeed,
      _userLibraryAlbumsBox => _libraryAlbums,
      _userLibrarySongsBox => _librarySongs,
      _userLibraryArtistsBox => _libraryArtists,
      _ => throw ArgumentError('Unknown box: $name'),
    };
  }
}
