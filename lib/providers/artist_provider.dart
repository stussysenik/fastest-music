import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../models/album.dart';
import 'authorization_provider.dart';
import 'backend_provider.dart';

final artistDetailProvider =
    FutureProvider.family<Artist, String>((ref, id) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getArtist(id);
});

final artistTopSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, id) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getArtistTopSongs(id, limit: 15);
});

final artistAlbumsProvider =
    FutureProvider.family<List<Album>, String>((ref, id) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getArtistAlbums(id);
});

/// Backend-powered artist albums provider.
///
/// ## When to use this vs artistAlbumsProvider (educational)
///
/// Use this when navigating from the World Browse tab or discovery feed,
/// where we have the artist's name but not their MusicKit ID.
/// Searches the backend for albums by artist name.
final backendArtistAlbumsProvider =
    FutureProvider.family<List<Album>, String>((ref, artistName) async {
  final backendService = ref.read(backendSearchServiceProvider);
  if (backendService == null) return [];

  try {
    final result = await backendService.searchAlbums(artistName);
    return result.albums;
  } catch (_) {
    return [];
  }
});
