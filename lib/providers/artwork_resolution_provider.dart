import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import 'backend_provider.dart';

/// Batch-resolves missing artwork URLs via the backend.
///
/// ## Why batch resolution? (educational)
///
/// When search results come back from MusicKit or the backend, some albums
/// may be missing artwork URLs. Rather than making N individual HTTP requests,
/// we send all missing albums in a single POST to `/api/artwork/batch`.
/// The backend fans out to iTunes + MusicBrainz concurrently using
/// Task.async_stream, resolving all artwork in one round-trip.
final artworkBatchResolverProvider =
    FutureProvider.family<List<Album>, List<Album>>((ref, albums) async {
  final coverService = ref.read(albumCoverServiceProvider);
  if (coverService == null) return albums;

  // Find albums missing artwork
  final missing = albums
      .where((a) => a.artworkUrl == null || a.artworkUrl!.isEmpty)
      .toList();

  if (missing.isEmpty) return albums;

  // Batch resolve
  final resolved = await coverService.batchGetArtworkUrls(
    missing.map((a) => (artist: a.artistName, title: a.title)).toList(),
  );

  if (resolved.isEmpty) return albums;

  // Merge resolved artwork back into albums
  return albums.map((album) {
    if (album.artworkUrl != null && album.artworkUrl!.isNotEmpty) return album;
    final key = '${album.artistName}|${album.title}';
    final url = resolved[key];
    if (url != null) {
      return album.copyWith(artworkUrl: url);
    }
    return album;
  }).toList();
});
