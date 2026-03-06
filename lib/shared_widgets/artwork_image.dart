import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/local_cache_provider.dart';

/// Artwork resolution tiers — request only the pixels you need.
///
/// ## Why adaptive sizing matters (educational)
///
/// Apple Music CDN serves images at any requested size via URL templates
/// like `{w}x{h}`. A 56px song tile doesn't need a 600x600 image —
/// that's 9x the pixels to decode. By requesting size-appropriate images:
/// - Smaller network payload → faster download
/// - Fewer pixels to decode → faster ImageCache insertion
/// - More images fit in the same ImageCache memory budget
enum ArtworkImageSize {
  /// 200x200 — song tiles, list items, mini player.
  thumbnail(200),

  /// 400x400 — discovery cards, medium artwork displays.
  medium(400),

  /// 600x600 — now playing, album detail hero images.
  full(600);

  final int pixels;
  const ArtworkImageSize(this.pixels);
}

/// Displays album/artist artwork with instant color placeholders.
///
/// ## Instant loading strategy (educational)
///
/// Instead of an animated shimmer placeholder, we show a solid color
/// that matches the album artwork (cached from previous palette extraction).
/// When the image loads from ImageCache (pre-warmed at startup), the
/// transition from color → image is nearly invisible. This eliminates
/// the "flicker" effect that shimmer creates, making the app feel instant.
///
/// The color comes from Hive (synchronous read, ~0.1ms), and the image
/// comes from Flutter's ImageCache (synchronous if precached).
class ArtworkImage extends ConsumerWidget {
  final String? url;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;
  final ArtworkImageSize imageSize;

  const ArtworkImage({
    super.key,
    this.url,
    this.size = 56,
    this.borderRadius = 8,
    this.placeholderIcon = Icons.music_note,
    this.imageSize = ArtworkImageSize.medium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedUrl = normalizeUrl(url, imageSize);

    // Read cached color from Hive (sync, ~0.1ms).
    Color? cachedColor;
    if (normalizedUrl != null) {
      try {
        final cache = ref.read(localCacheProvider);
        final colorValue = cache.getArtworkColor(normalizedUrl);
        if (colorValue != null) {
          cachedColor = Color(colorValue);
        }
      } catch (_) {
        // Provider not yet initialized — fall back to default.
      }
    }

    final placeholderColor = cachedColor ?? const Color(0xFFE0E0E0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: normalizedUrl != null
            ? CachedNetworkImage(
                imageUrl: normalizedUrl,
                fit: BoxFit.cover,
                httpHeaders: const {
                  'User-Agent': 'FastestMusic/1.0 (iOS)',
                },
                // Solid color placeholder — no animation, no shimmer.
                // If the image is in ImageCache, this never even shows.
                placeholder: (context, url) =>
                    Container(color: placeholderColor),
                errorWidget: (context, url, error) {
                  if (kDebugMode) {
                    print('[ArtworkImage] Failed to load: $url — $error');
                  }
                  return _placeholder();
                },
              )
            : _placeholder(),
      ),
    );
  }

  /// Normalize an artwork URL template to a concrete URL.
  ///
  /// Static so it can be reused by ImagePrecacheService and PrefetchPipeline
  /// to ensure cache key consistency — the same URL string must be used
  /// everywhere for ImageCache hits.
  static String? normalizeUrl(String? rawUrl,
      [ArtworkImageSize imageSize = ArtworkImageSize.medium]) {
    if (rawUrl == null) return null;

    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final sizeStr = imageSize.pixels.toString();
    var normalized = trimmed
        .replaceAll('{w}', sizeStr)
        .replaceAll('{h}', sizeStr)
        .replaceAll('{f}', 'jpg');

    if (normalized.startsWith('//')) {
      normalized = 'https:$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }

    return normalized;
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Icon(
        placeholderIcon,
        color: const Color(0xFFCCCCCC),
        size: size * 0.4,
      ),
    );
  }
}
