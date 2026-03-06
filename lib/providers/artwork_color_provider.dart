import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'local_cache_provider.dart';

/// Extracts dominant and vibrant colors from an artwork URL,
/// then persists them to Hive for instant access on next launch.
///
/// ## Two-tier color access (educational)
///
/// 1. **Synchronous** (`cachedArtworkColorProvider`): Reads from Hive in ~0.1ms.
///    Used by ArtworkImage for instant color placeholders — no async, no loading state.
///
/// 2. **Async** (`artworkColorsProvider`): Extracts full palette from the image.
///    After extraction, persists dominant color to Hive so future reads are instant.
///    Used by Now Playing gradient and other dynamic-color UIs.
final artworkColorsProvider =
    FutureProvider.family<ArtworkColors, String>((ref, artworkUrl) async {
  if (artworkUrl.isEmpty) {
    return ArtworkColors.fallback;
  }

  try {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      NetworkImage(artworkUrl),
      size: const Size(100, 100),
      maximumColorCount: 16,
    );

    final dominant =
        paletteGenerator.dominantColor?.color ?? const Color(0xFF1A1A1A);
    final vibrant = paletteGenerator.vibrantColor?.color ?? dominant;
    final muted = paletteGenerator.mutedColor?.color ?? dominant;
    final darkVibrant = paletteGenerator.darkVibrantColor?.color ?? dominant;

    // Persist dominant color to Hive for instant placeholder colors.
    try {
      final cache = ref.read(localCacheProvider);
      await cache.putArtworkColor(artworkUrl, dominant.toARGB32());
    } catch (_) {
      // Cache not available — non-critical.
    }

    return ArtworkColors(
      dominant: dominant,
      vibrant: vibrant,
      muted: muted,
      darkVibrant: darkVibrant,
    );
  } catch (_) {
    return ArtworkColors.fallback;
  }
});

/// Synchronous provider for cached artwork dominant color.
///
/// Returns the cached dominant color for an artwork URL from Hive.
/// If no color is cached, returns a default grey. This is used by
/// ArtworkImage to show a meaningful placeholder color without any
/// async operations — the color appears on the very first frame.
final cachedArtworkColorProvider =
    Provider.family<Color, String>((ref, artworkUrl) {
  if (artworkUrl.isEmpty) return const Color(0xFFE0E0E0);
  try {
    final cache = ref.read(localCacheProvider);
    final colorValue = cache.getArtworkColor(artworkUrl);
    if (colorValue != null) {
      return Color(colorValue);
    }
  } catch (_) {}
  return const Color(0xFFE0E0E0);
});

/// Extracted color palette from artwork.
class ArtworkColors {
  final Color dominant;
  final Color vibrant;
  final Color muted;
  final Color darkVibrant;

  const ArtworkColors({
    required this.dominant,
    required this.vibrant,
    required this.muted,
    required this.darkVibrant,
  });

  static const fallback = ArtworkColors(
    dominant: Color(0xFF1A1A1A),
    vibrant: Color(0xFF333333),
    muted: Color(0xFF2A2A2A),
    darkVibrant: Color(0xFF111111),
  );
}
