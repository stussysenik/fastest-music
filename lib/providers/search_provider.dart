import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import 'backend_provider.dart';

class SearchResult {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;

  const SearchResult({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
  });
}

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active search filters — genre and year range.
final searchGenreFilterProvider = StateProvider<String?>((ref) => null);
final searchYearFromFilterProvider = StateProvider<int?>((ref) => null);
final searchYearToFilterProvider = StateProvider<int?>((ref) => null);

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, SearchResult>(
        SearchResultsNotifier.new);

class SearchResultsNotifier extends AsyncNotifier<SearchResult> {
  @override
  Future<SearchResult> build() async {
    return const SearchResult();
  }

  /// Search using the federated service (backend first, MusicKit fallback).
  /// After results arrive, batch-resolves any missing album artwork via backend.
  Future<void> search(String query, {
    String? genre,
    int? yearFrom,
    int? yearTo,
  }) async {
    if (query.trim().isEmpty) {
      state = const AsyncData(SearchResult());
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(federatedMusicServiceProvider);
      final result = await service.searchCatalog(
        query,
        genre: genre,
        yearFrom: yearFrom,
        yearTo: yearTo,
      );

      // Batch-resolve missing artwork URLs
      var albums = result.albums;
      final coverService = ref.read(albumCoverServiceProvider);
      if (coverService != null) {
        final missing = albums
            .where((a) => a.artworkUrl == null || a.artworkUrl!.isEmpty)
            .toList();
        if (missing.isNotEmpty) {
          try {
            final resolved = await coverService.batchGetArtworkUrls(
              missing.map((a) => (artist: a.artistName, title: a.title)).toList(),
            );
            if (resolved.isNotEmpty) {
              albums = albums.map((album) {
                if (album.artworkUrl != null && album.artworkUrl!.isNotEmpty) {
                  return album;
                }
                final key = '${album.artistName}|${album.title}';
                final url = resolved[key];
                if (url != null) return album.copyWith(artworkUrl: url);
                return album;
              }).toList();
            }
          } catch (_) {
            // Artwork resolution is best-effort
          }
        }
      }

      return SearchResult(
        songs: result.songs,
        albums: albums,
        artists: result.artists,
      );
    });
  }
}
