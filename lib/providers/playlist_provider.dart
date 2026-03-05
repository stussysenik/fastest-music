import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'authorization_provider.dart';

/// User's library playlists from MusicKit.
///
/// ## Caching strategy (educational)
///
/// FutureProvider caches the result for the widget's lifetime. Since
/// playlists change rarely during a session, this avoids repeated
/// MusicKit calls. Call `ref.invalidate(userPlaylistsProvider)` after
/// creating a new playlist to refresh the list.
final userPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final service = ref.read(musicKitServiceProvider);
  return service.getUserPlaylists();
});

/// Tracks for a specific playlist, fetched on demand.
///
/// ## Family provider pattern (educational)
///
/// `FutureProvider.family` creates a unique provider instance per
/// `playlistId`. Each playlist's tracks are cached independently,
/// so navigating between playlists doesn't re-fetch previously loaded
/// data. Invalidate with `ref.invalidate(playlistTracksProvider(id))`
/// after modifying a playlist's contents.
final playlistTracksProvider =
    FutureProvider.family<List<Song>, String>((ref, playlistId) async {
  final service = ref.read(musicKitServiceProvider);
  return service.getPlaylistTracks(playlistId);
});
