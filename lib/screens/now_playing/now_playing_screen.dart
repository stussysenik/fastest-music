import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playback_state.dart';
import '../../providers/enriched_playback_provider.dart';
import '../../providers/player_controls_provider.dart';
import '../../providers/artwork_color_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/add_to_playlist_sheet.dart';

/// Now Playing screen with artwork-derived gradient background.
///
/// ## Visual design (educational)
///
/// The screen uses three layers of visual depth:
/// 1. **Background**: Blurred artwork image with dominant color gradient overlay
/// 2. **Artwork**: Large with deep drop shadow and bounce animation on play/pause
/// 3. **Controls**: Semi-transparent glassmorphism container with shuffle/repeat
///
/// Colors are extracted from the artwork via PaletteGenerator, creating
/// a dynamic, immersive experience that changes with each song — matching
/// the premium feel of Apple Music and Spotify's now-playing screens.
///
/// ## Swipe-to-dismiss (educational)
///
/// The entire screen responds to vertical drag gestures. A downward swipe
/// dismisses the screen, matching the iOS modal sheet pattern. This works
/// alongside the top-bar chevron button for accessibility.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _showRemaining = false;
  String _shuffleMode = 'off';
  String _repeatMode = 'none';

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.93), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.93, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    _loadModes();
  }

  Future<void> _loadModes() async {
    final controls = ref.read(playerControlsProvider);
    try {
      final shuffle = await controls.getShuffleMode();
      final repeat = await controls.getRepeatMode();
      if (mounted) {
        setState(() {
          _shuffleMode = shuffle;
          _repeatMode = repeat;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackAsync = ref.watch(enrichedPlaybackProvider);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe down to dismiss
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: playbackAsync.when(
          data: (state) => _buildPlayer(context, ref, state),
          loading: () => _buildEmpty(context),
          error: (_, __) => _buildEmpty(context),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A2A), Color(0xFF0A0A0A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const Spacer(),
            const Icon(Icons.music_note, size: 64, color: Color(0xFF555555)),
            const SizedBox(height: 16),
            const Text(
              'Nothing playing',
              style: TextStyle(fontSize: 16, color: Color(0xFF777777)),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white70, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          const Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPlayer(
      BuildContext context, WidgetRef ref, PlaybackState state) {
    if (state.status == PlaybackStatus.stopped && state.title == null) {
      return _buildEmpty(context);
    }

    final controls = ref.read(playerControlsProvider);
    final isPlaying = state.status == PlaybackStatus.playing;
    final progress =
        state.duration > 0 ? state.playbackTime / state.duration : 0.0;
    final artworkUrl = ArtworkImage.normalizeUrl(state.artworkUrl, ArtworkImageSize.full) ?? '';

    // Extract colors from artwork
    final colorsAsync = artworkUrl.isNotEmpty
        ? ref.watch(artworkColorsProvider(artworkUrl))
        : null;
    final colors = colorsAsync?.valueOrNull ?? ArtworkColors.fallback;

    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = screenWidth - 80;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Blurred artwork background
        if (artworkUrl.isNotEmpty)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Image.network(
              artworkUrl,
              fit: BoxFit.cover,
              headers: const {'User-Agent': 'FastestMusic/1.0 (iOS)'},
              color: Colors.black.withValues(alpha: 0.3),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Container(color: colors.dominant),
            ),
          )
        else
          Container(color: colors.dominant),

        // Layer 2: Gradient overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
              colors: [
                colors.darkVibrant.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),

        // Layer 3: Content
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              const Spacer(flex: 1),

              // Artwork with deep shadow and bounce animation
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.dominant.withValues(alpha: 0.6),
                        blurRadius: 60,
                        spreadRadius: 5,
                        offset: const Offset(0, 25),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ArtworkImage(
                    url: state.artworkUrl,
                    size: artworkSize,
                    borderRadius: 16,
                    imageSize: ArtworkImageSize.full,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      state.title ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.artistName ?? state.subtitle ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    if (state.albumTitle != null &&
                        state.albumTitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        state.albumTitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Progress bar with tap-to-toggle elapsed/remaining
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: colors.vibrant,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          controls.seekTo(value * state.duration);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(state.playbackTime),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white54),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _showRemaining = !_showRemaining);
                            },
                            child: Text(
                              _showRemaining
                                  ? '-${_formatTime(state.duration - state.playbackTime)}'
                                  : _formatTime(state.duration),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Shuffle + Controls + Repeat row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle toggle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: _shuffleMode == 'songs'
                            ? colors.vibrant
                            : Colors.white38,
                        size: 22,
                      ),
                      onPressed: () async {
                        final mode = await controls.toggleShuffle();
                        setState(() => _shuffleMode = mode);
                      },
                    ),

                    // Main controls
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous),
                                iconSize: 36,
                                color: Colors.white,
                                onPressed: () => controls.skipToPrevious(),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  iconSize: 40,
                                  onPressed: () {
                                    _bounceController.forward(from: 0);
                                    if (isPlaying) {
                                      controls.pause();
                                    } else {
                                      controls.resume();
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next),
                                iconSize: 36,
                                color: Colors.white,
                                onPressed: () => controls.skipToNext(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Repeat toggle
                    IconButton(
                      icon: Icon(
                        _repeatMode == 'one' ? Icons.repeat_one : Icons.repeat,
                        color: _repeatMode != 'none'
                            ? colors.vibrant
                            : Colors.white38,
                        size: 22,
                      ),
                      onPressed: () async {
                        final mode = await controls.toggleRepeat();
                        setState(() => _repeatMode = mode);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Add to Playlist button
              if (state.songId != null)
                TextButton.icon(
                  onPressed: () => showAddToPlaylistSheet(
                    context,
                    state.songId!,
                    state.title ?? '',
                  ),
                  icon: const Icon(Icons.playlist_add,
                      size: 18, color: Colors.white54),
                  label: const Text(
                    'Add to Playlist',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ],
    );
  }

  // URL normalization now handled by ArtworkImage.normalizeUrl()

  String _formatTime(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
