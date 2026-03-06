import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/local_cache_provider.dart';
import '../../providers/recently_played_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/artwork_color_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../cache/image_precache_service.dart';

/// Orchestrates startup prefetching for instant rendering.
///
/// ## Pipeline stages (educational)
///
/// 1. **Collect URLs**: Gather all artwork URLs from cached data (Hive).
///    This is synchronous and completes in microseconds.
///
/// 2. **Batch precache**: Call `precacheImage()` for all collected URLs.
///    This loads images from disk cache (CachedNetworkImage) into Flutter's
///    in-memory ImageCache. After this, any widget using the same URL
///    renders the image synchronously — no placeholder visible.
///
/// 3. **Color extraction**: For URLs without cached colors, trigger
///    `artworkColorsProvider` to extract and persist dominant colors.
///    This runs in the background — colors will be ready for next launch.
///
/// The pipeline runs in a post-frame callback so it doesn't block the
/// first frame. On warm starts, most images are already in ImageCache
/// from the previous session, so this completes very quickly.
class PrefetchPipeline {
  /// Run the full prefetch pipeline after the first frame.
  ///
  /// Call this from AppShell's initState via
  /// `WidgetsBinding.instance.addPostFrameCallback`.
  static Future<void> runPostFrame(BuildContext context, WidgetRef ref) async {
    try {
      final urls = _collectArtworkUrls(ref);
      if (urls.isEmpty) return;

      // Stage 2: Batch precache images into Flutter's ImageCache.
      await ImagePrecacheService.precacheUrls(context, urls);

      // Stage 3: Extract colors for URLs that don't have cached colors.
      _triggerColorExtraction(ref, urls);
    } catch (_) {
      // Prefetching is best-effort — never crash the app.
    }
  }

  /// Collect all artwork URLs from cached provider data.
  static List<String> _collectArtworkUrls(WidgetRef ref) {
    final urls = <String>{};

    // Recently played songs
    final recentlyPlayed = ref.read(recentlyPlayedProvider).valueOrNull;
    if (recentlyPlayed != null) {
      for (final song in recentlyPlayed) {
        final url = ArtworkImage.normalizeUrl(song.artworkUrl, ArtworkImageSize.medium);
        if (url != null) urls.add(url);
      }
    }

    // Discovery feed albums — medium size for cards
    final discovery = ref.read(discoveryFeedProvider).valueOrNull;
    if (discovery != null) {
      for (final section in discovery) {
        for (final album in section.albums) {
          final url =
              ArtworkImage.normalizeUrl(album.artworkUrl, ArtworkImageSize.medium);
          if (url != null) urls.add(url);
        }
      }
    }

    return urls.toList();
  }

  /// Trigger color extraction for URLs without cached colors.
  static void _triggerColorExtraction(WidgetRef ref, List<String> urls) {
    final cacheService = ref.read(localCacheProvider);
    for (final url in urls) {
      if (cacheService.getArtworkColor(url) == null) {
        // Reading the provider triggers the async color extraction,
        // which will persist the result to Hive when done.
        ref.read(artworkColorsProvider(url));
      }
    }
  }
}
