import 'package:flutter/widgets.dart';

/// Utility for batch-precaching images into Flutter's ImageCache.
///
/// ## How precacheImage works (educational)
///
/// `precacheImage()` loads an image into the global ImageCache and returns
/// a Future that completes when decoding is done. Once cached, any widget
/// using the same ImageProvider key (e.g., same URL) will render the image
/// synchronously — zero shimmer, zero placeholder, zero delay.
///
/// We call this at startup with all artwork URLs from cached data,
/// so by the time the user sees a screen, images are already in RAM.
class ImagePrecacheService {
  /// Precache a batch of image URLs into Flutter's ImageCache.
  ///
  /// Uses [NetworkImage] with the same headers as ArtworkImage so cache
  /// keys match. Failures are silently ignored — precaching is best-effort.
  static Future<void> precacheUrls(
    BuildContext context,
    List<String> urls, {
    Map<String, String> headers = const {
      'User-Agent': 'FastestMusic/1.0 (iOS)',
    },
  }) async {
    final futures = urls.map((url) {
      return precacheImage(
        NetworkImage(url, headers: headers),
        context,
      ).catchError((_) {
        // Best-effort: ignore failures silently.
      });
    });
    await Future.wait(futures);
  }
}
