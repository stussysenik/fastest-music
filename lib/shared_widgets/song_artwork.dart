import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/backend_provider.dart';
import 'artwork_image.dart';

/// Song-specific artwork provider that resolves missing artwork from the backend.
///
/// ## How it works (educational)
///
/// Keyed by "artist|album", so each unique combination is resolved once per
/// session. Uses `AlbumCoverService.getArtworkUrl` which checks ETS cache →
/// Postgres → iTunes API → MusicBrainz on the backend side.
final _songArtworkProvider =
    FutureProvider.family<String?, String>((ref, key) async {
  final parts = key.split('|');
  if (parts.length != 2) return null;

  final albumCoverService = ref.read(albumCoverServiceProvider);
  if (albumCoverService == null) return null;

  return albumCoverService.getArtworkUrl(parts[0], parts[1]);
});

/// Drop-in replacement for `ArtworkImage` that auto-resolves missing artwork.
///
/// ## When to use (educational)
///
/// Use `SongArtwork` instead of raw `ArtworkImage` whenever displaying a
/// song's artwork. If `song.artworkUrl` is null, it automatically tries
/// the backend's multi-source artwork resolver. This eliminates grey
/// placeholders in song lists without any manual intervention.
class SongArtwork extends ConsumerWidget {
  final Song song;
  final double size;
  final double borderRadius;

  const SongArtwork({
    super.key,
    required this.song,
    this.size = 48,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If song already has artwork, use it directly
    if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
      return ArtworkImage(
        url: song.artworkUrl,
        size: size,
        borderRadius: borderRadius,
      );
    }

    // Try backend resolution
    if (song.artistName.isNotEmpty && song.albumTitle.isNotEmpty) {
      final key = '${song.artistName}|${song.albumTitle}';
      final resolved = ref.watch(_songArtworkProvider(key));

      return resolved.when(
        data: (url) => ArtworkImage(
          url: url,
          size: size,
          borderRadius: borderRadius,
        ),
        loading: () => ArtworkImage(
          size: size,
          borderRadius: borderRadius,
        ),
        error: (_, __) => ArtworkImage(
          size: size,
          borderRadius: borderRadius,
        ),
      );
    }

    // No metadata to resolve — show placeholder
    return ArtworkImage(
      size: size,
      borderRadius: borderRadius,
    );
  }
}
