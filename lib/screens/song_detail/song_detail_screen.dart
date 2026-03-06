import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/song.dart';
import '../../providers/music_kit_availability_provider.dart';
import '../../providers/player_controls_provider.dart';
import '../../shared_widgets/song_artwork.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/add_to_playlist_sheet.dart';

/// Rich song detail screen with artwork, metadata, and action buttons.
///
/// ## Design philosophy (educational)
///
/// Music apps live and die by their detail screens. This screen uses:
/// - A **hero artwork** section with a blurred gradient backdrop derived
///   from the artwork, creating depth without external dependencies.
/// - **Meaningful numbers** (duration, track #, release year, genres)
///   displayed as chips for scanability.
/// - **Action buttons** for play and add-to-playlist, gated on MusicKit
///   availability so the screen still works in browse-only mode.
class SongDetailScreen extends ConsumerWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final artworkSize = screenWidth * 0.65;
    final normalizedArtworkUrl = ArtworkImage.normalizeUrl(song.artworkUrl, ArtworkImageSize.full);
    final canPlay = ref.watch(musicKitAvailabilityProvider) ==
        MusicKitAvailability.available;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing app bar with artwork
          SliverAppBar(
            expandedHeight: artworkSize + 120,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred artwork background
                  if (normalizedArtworkUrl != null)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                      child: Image.network(
                        normalizedArtworkUrl,
                        fit: BoxFit.cover,
                        headers: const {'User-Agent': 'FastestMusic/1.0 (iOS)'},
                        color: Colors.black.withValues(alpha: 0.4),
                        colorBlendMode: BlendMode.darken,
                      ),
                    )
                  else
                    Container(color: const Color(0xFF1A1A1A)),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  // Centered artwork
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: SongArtwork(
                            song: song,
                            size: artworkSize,
                            borderRadius: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Song details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Artist name (tappable)
                  if (song.artistName.isNotEmpty)
                    GestureDetector(
                      onTap: () => context.push(
                        '/backend-artist/${Uri.encodeComponent(song.artistName)}',
                      ),
                      child: Text(
                        song.artistName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue,
                                ),
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Album name (tappable)
                  if (song.albumTitle.isNotEmpty)
                    Text(
                      song.albumTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF666666),
                          ),
                    ),

                  const SizedBox(height: 24),

                  // Numbers section — duration, track #, release year
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (song.duration > 0)
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: _formatDuration(song.duration),
                        ),
                      if (song.trackNumber != null)
                        _InfoChip(
                          icon: Icons.format_list_numbered,
                          label: 'Track ${song.trackNumber}',
                        ),
                      if (song.releaseDate != null &&
                          song.releaseDate!.length >= 4)
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: song.releaseDate!.substring(0, 4),
                        ),
                      ...song.genreNames.map(
                        (genre) => _InfoChip(
                          icon: Icons.music_note_outlined,
                          label: genre,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (!canPlay) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Playback requires Apple Music'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            ref.read(playerControlsProvider).playSong(song.id);
                            context.go('/now-playing');
                          },
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.white),
                          label: const Text('Play',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                canPlay ? Colors.black : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canPlay
                              ? () => _showAddToPlaylist(context, ref)
                              : null,
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Add to Playlist'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // "From Album" section
                  if (song.albumTitle.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'From Album',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        // Navigate to backend artist → shows albums
                        context.push(
                          '/backend-artist/${Uri.encodeComponent(song.artistName)}',
                        );
                      },
                      child: Row(
                        children: [
                          ArtworkImage(
                            url: song.artworkUrl,
                            size: 64,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.albumTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  song.artistName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Color(0xFF999999)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // URL normalization now handled by ArtworkImage.normalizeUrl()

  void _showAddToPlaylist(BuildContext context, WidgetRef ref) {
    showAddToPlaylistSheet(context, song.id, song.title);
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

/// Small chip displaying an icon + label for song metadata.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF666666)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
