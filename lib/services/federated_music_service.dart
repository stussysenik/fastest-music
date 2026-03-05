import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import 'music_kit_service.dart';
import 'backend_search_service.dart';

/// Federated search service that tries the backend first, then falls back to MusicKit.
///
/// ## Federation strategy (educational)
///
/// 1. Fire both backend and MusicKit searches in parallel
/// 2. Use whichever responds first (usually backend if cached)
/// 3. If backend fails entirely, fall back to MusicKit
/// 4. Playback stays 100% through MusicKit (backend doesn't handle audio)
///
/// Playback and library access (playlists, recently-played) require MusicKit
/// authorization, but catalog search works without it.
class FederatedMusicService {
  final MusicKitService _musicKitService;
  final BackendSearchService? _backendService;

  FederatedMusicService(this._musicKitService, this._backendService);

  /// Search catalog with backend-first, MusicKit-fallback strategy.
  ///
  /// ## Catalog vs Library access (educational)
  ///
  /// MusicKit catalog search (MusicCatalogSearchRequest) works WITHOUT user
  /// authorization — it searches Apple Music's public catalog. Only library
  /// access (playlists, recently played) requires the user to grant permission.
  /// So we always race both sources regardless of auth status.
  Future<({List<Song> songs, List<Album> albums, List<Artist> artists})>
      searchCatalog(
    String term, {
    String? genre,
    int? yearFrom,
    int? yearTo,
  }) async {
    final hasFilters = genre != null || yearFrom != null || yearTo != null;

    // If we have filters and a backend, use backend (MusicKit can't filter)
    if (hasFilters && _backendService != null) {
      try {
        final result = await _backendService.searchAlbums(
          term,
          genre: genre,
          yearFrom: yearFrom,
          yearTo: yearTo,
        );
        return (songs: <Song>[], albums: result.albums, artists: <Artist>[]);
      } catch (_) {
        // Fall through to unfiltered search
      }
    }

    // Race both sources — catalog search works even without user auth
    if (_backendService != null) {
      // Fire both in parallel, catch errors individually so one failure
      // doesn't lose the other source's results
      ({List<Album> albums, bool cached})? backendResult;
      ({List<Song> songs, List<Album> albums, List<Artist> artists})?
          musicKitResult;

      try {
        await Future.wait<void>([
          _backendService
              .searchAlbums(term)
              .then((r) => backendResult = r)
              .catchError((_) {}),
          _musicKitService
              .searchCatalog(term)
              .then((r) => musicKitResult = r)
              .catchError((_) {}),
        ]).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Timeout — use whatever completed
      }

      if (backendResult != null || musicKitResult != null) {
        return (
          songs: musicKitResult?.songs ?? <Song>[],
          albums: (backendResult?.albums.isNotEmpty ?? false)
              ? backendResult!.albums
              : musicKitResult?.albums ?? <Album>[],
          artists: musicKitResult?.artists ?? <Artist>[],
        );
      }
    }

    // Pure MusicKit fallback (no backend configured or both timed out)
    return _musicKitService.searchCatalog(term);
  }

  // --- Pass-through methods (playback stays on MusicKit) ---

  Future<List<Song>> getRecentlyPlayed({int limit = 10}) =>
      _musicKitService.getRecentlyPlayed(limit: limit);

  Future<Artist> getArtist(String id) =>
      _musicKitService.getArtist(id);

  Future<List<Song>> getArtistTopSongs(String id, {int limit = 10}) =>
      _musicKitService.getArtistTopSongs(id, limit: limit);

  Future<List<Album>> getArtistAlbums(String id) =>
      _musicKitService.getArtistAlbums(id);

  Future<Album> getAlbum(String id) =>
      _musicKitService.getAlbum(id);

  Future<List<Song>> getAlbumTracks(String id) =>
      _musicKitService.getAlbumTracks(id);
}
