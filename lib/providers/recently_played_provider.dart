import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/music_authorization_status.dart';
import 'authorization_provider.dart';
import 'backend_provider.dart';

final recentlyPlayedProvider =
    AsyncNotifierProvider<RecentlyPlayedNotifier, List<Song>>(
        RecentlyPlayedNotifier.new);

class RecentlyPlayedNotifier extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() async {
    final authStatus = await ref.watch(authorizationProvider.future);
    if (authStatus != MusicAuthorizationStatus.authorized) {
      return [];
    }
    final service = ref.read(musicKitServiceProvider);
    final songs = await service.getRecentlyPlayed(limit: 25);

    // Batch-resolve missing artwork from backend
    return _resolveArtwork(songs);
  }

  /// Resolve missing artwork URLs via the backend's batch endpoint.
  ///
  /// ## Why batch? (educational)
  ///
  /// Recently played songs from MusicKit sometimes have null artwork
  /// (e.g. when Apple's CDN hasn't cached the asset for the requested size).
  /// Instead of N individual network calls, we send one batch request to
  /// our Elixir backend which resolves all missing artwork concurrently
  /// using Task.async_stream.
  Future<List<Song>> _resolveArtwork(List<Song> songs) async {
    final albumCoverService = ref.read(albumCoverServiceProvider);
    if (albumCoverService == null) return songs;

    // Collect songs that need artwork
    final needsArtwork = songs
        .where((s) =>
            (s.artworkUrl == null || s.artworkUrl!.isEmpty) &&
            s.artistName.isNotEmpty &&
            s.albumTitle.isNotEmpty)
        .toList();

    if (needsArtwork.isEmpty) return songs;

    // Build unique album list to avoid duplicate lookups
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

    // Apply resolved URLs back to songs
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
