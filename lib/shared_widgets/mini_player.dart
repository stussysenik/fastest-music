import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/playback_state.dart';
import '../providers/music_kit_availability_provider.dart';
import '../providers/enriched_playback_provider.dart';
import '../providers/player_controls_provider.dart';
import '../providers/artwork_color_provider.dart';
import 'artwork_image.dart';

/// Mini player with artwork-derived background tint.
///
/// ## Animated tint (educational)
///
/// The mini player uses `AnimatedContainer` so that when the song changes,
/// the background color transitions smoothly from the old artwork's dominant
/// color to the new one. The tint is applied at 10% opacity — enough to
/// create a visual connection to the now-playing artwork without being
/// distracting or affecting text readability.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide mini player entirely when MusicKit is unavailable
    final availability = ref.watch(musicKitAvailabilityProvider);
    if (availability != MusicKitAvailability.available) {
      return const SizedBox.shrink();
    }

    final playbackAsync = ref.watch(enrichedPlaybackProvider);

    return playbackAsync.when(
      data: (state) {
        if (state.status == PlaybackStatus.stopped && state.title == null) {
          return const SizedBox.shrink();
        }
        return _buildPlayer(context, ref, state);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPlayer(
      BuildContext context, WidgetRef ref, PlaybackState state) {
    final controls = ref.read(playerControlsProvider);
    final isPlaying = state.status == PlaybackStatus.playing;
    final artworkUrl = state.artworkUrl ?? '';

    // Extract dominant color for subtle tint
    final colorsAsync = artworkUrl.isNotEmpty
        ? ref.watch(artworkColorsProvider(artworkUrl))
        : null;
    final tintColor =
        colorsAsync?.valueOrNull?.dominant ?? const Color(0xFFFAFAFA);

    return GestureDetector(
      onTap: () => context.go('/now-playing'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFFAFAFA), tintColor, 0.10),
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ArtworkImage(
              url: state.artworkUrl,
              size: 40,
              borderRadius: 6,
              imageSize: ArtworkImageSize.thumbnail,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (state.artistName != null)
                    Text(
                      state.artistName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 28,
              ),
              onPressed: () {
                if (isPlaying) {
                  controls.pause();
                } else {
                  controls.resume();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
