import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Displays album/artist artwork with shimmer loading and graceful fallback.
///
/// ## Shimmer effect (educational)
///
/// Instead of a static grey placeholder, shimmer creates a sweeping
/// highlight animation that signals "content is loading" — a pattern
/// popularized by Facebook/Meta. The `shimmer` package wraps this in
/// a simple widget that we compose with our placeholder.
///
/// ## HTTP headers (educational)
///
/// Apple Music CDN (mzstatic.com) may reject image requests on physical
/// iOS devices if no User-Agent header is present. CachedNetworkImage
/// supports `httpHeaders` to fix this — a common gotcha when moving
/// from simulator to real hardware.
class ArtworkImage extends StatelessWidget {
  final String? url;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;

  const ArtworkImage({
    super.key,
    this.url,
    this.size = 56,
    this.borderRadius = 8,
    this.placeholderIcon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                httpHeaders: const {
                  'User-Agent': 'FastestMusic/1.0 (iOS)',
                },
                placeholder: (context, url) => _shimmerPlaceholder(),
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

  Widget _shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(color: const Color(0xFFE0E0E0)),
    );
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
