import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend_provider.dart';

/// Resolves an artist's artwork by searching the backend for their albums.
///
/// ## How it works (educational)
///
/// We don't have a dedicated "artist image" API, but we can search the
/// backend for albums by the artist's name and use the first album's
/// artwork as a proxy for the artist's image. This is a common pattern
/// in music apps — artist photos are often harder to source than album art.
///
/// The FutureProvider.family caches results per artist name, so we only
/// hit the backend once per artist per session.
final artistArtworkProvider =
    FutureProvider.family<String?, String>((ref, artistName) async {
  final backendService = ref.read(backendSearchServiceProvider);
  if (backendService == null) return null;

  try {
    final result = await backendService.searchAlbums(artistName);
    if (result.albums.isNotEmpty) {
      // Return the first album's artwork as the artist's image
      for (final album in result.albums) {
        if (album.artworkUrl != null && album.artworkUrl!.isNotEmpty) {
          return album.artworkUrl;
        }
      }
    }
    return null;
  } catch (_) {
    return null;
  }
});
