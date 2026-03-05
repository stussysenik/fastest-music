import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

/// Extracts dominant and vibrant colors from an artwork URL.
///
/// ## How PaletteGenerator works (educational)
///
/// `PaletteGenerator.fromImageProvider` samples colors from the image,
/// clusters them using k-means, and returns named swatches:
/// - **Dominant**: the most common color in the image
/// - **Vibrant**: a saturated, eye-catching color
/// - **Muted**: a desaturated color good for backgrounds
///
/// We use this to create dynamic, artwork-derived gradients on the
/// Now Playing screen and mini player — matching Apple Music's approach.
/// Results are cached per URL by Riverpod's FutureProvider.family.
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
    final vibrant =
        paletteGenerator.vibrantColor?.color ?? dominant;
    final muted =
        paletteGenerator.mutedColor?.color ?? dominant;
    final darkVibrant =
        paletteGenerator.darkVibrantColor?.color ?? dominant;

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
