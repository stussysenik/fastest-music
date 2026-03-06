import 'package:flutter/material.dart';
import 'artwork_image.dart';

/// Fan-stacked album artwork cards with staggered entrance animation.
///
/// ## Composable preview design (educational)
///
/// This widget creates a "deck of cards" effect where album covers
/// are stacked with slight rotation and offset. It uses:
///
/// - `AnimationController` with `StaggeredAnimation` — each card
///   animates in sequence using `Interval` curves
/// - `Transform.rotate` + `Transform.translate` — creates the fan spread
/// - `BoxShadow` — adds depth between stacked cards
///
/// The front card is full-size with no rotation; back cards get
/// progressively smaller, more rotated, and offset to create depth.
class StackedArtworkPreview extends StatefulWidget {
  final List<String> artworkUrls;
  final double cardSize;
  final VoidCallback? onTap;

  const StackedArtworkPreview({
    super.key,
    required this.artworkUrls,
    this.cardSize = 120,
    this.onTap,
  });

  @override
  State<StackedArtworkPreview> createState() => _StackedArtworkPreviewState();
}

class _StackedArtworkPreviewState extends State<StackedArtworkPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.artworkUrls.take(5).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    final totalWidth = widget.cardSize + (urls.length - 1) * 28;
    final totalHeight = widget.cardSize + 20;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = urls.length - 1; i >= 0; i--)
                  _buildCard(urls[i], i, urls.length),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(String url, int index, int total) {
    // Staggered entrance: each card slides in with a slight delay
    final intervalStart = (index / total) * 0.5;
    final intervalEnd = intervalStart + 0.5;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(intervalStart, intervalEnd.clamp(0.0, 1.0),
          curve: Curves.easeOutBack),
    );

    // Layout: front card (index 0) is centered, back cards fan outward
    final rotationAngle = index * 0.06; // ~3.4 degrees per card
    final xOffset = index * 28.0;
    final yOffset = index * 4.0;
    final scale = 1.0 - (index * 0.04);

    return Positioned(
      left: xOffset * animation.value,
      top: yOffset * animation.value,
      child: Transform.rotate(
        angle: rotationAngle * animation.value,
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15 - index * 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ArtworkImage(
                url: url,
                size: widget.cardSize,
                borderRadius: 12,
                imageSize: ArtworkImageSize.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
