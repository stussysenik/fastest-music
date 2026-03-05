import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/playlist.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/music_kit_availability_provider.dart';
import '../../providers/player_controls_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';

/// Displays a playlist's metadata and track listing.
///
/// ## Mirror of album_detail_screen (educational)
///
/// This screen follows the same visual hierarchy as `AlbumDetailScreen`:
/// large centered artwork → title + metadata → play button → track list.
/// Consistent layouts across content types reduce cognitive load and let
/// users build muscle memory for navigation patterns.
class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final Playlist? playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist?.name ?? 'Playlist'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Playlist header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ArtworkImage(
                  url: playlist?.artworkUrl,
                  size: MediaQuery.of(context).size.width * 0.6,
                  borderRadius: 12,
                  placeholderIcon: Icons.queue_music,
                ),
                const SizedBox(height: 20),
                Text(
                  playlist?.name ?? 'Playlist',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${playlist?.trackCount ?? 0} tracks',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF999999),
                      ),
                ),
                const SizedBox(height: 16),
                // Play button
                Builder(builder: (context) {
                  final canPlay = ref.watch(musicKitAvailabilityProvider) ==
                      MusicKitAvailability.available;
                  return SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!canPlay) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Playback requires Apple Music'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(playerControlsProvider)
                            .playPlaylist(playlistId);
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text('Play',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canPlay ? Colors.black : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(),

          // Track listing
          tracksAsync.when(
            data: (tracks) {
              if (tracks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.music_off,
                            size: 48, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 12),
                        Text(
                          'No tracks yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add songs from Browse or your library',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final totalSeconds =
                  tracks.fold<double>(0, (sum, t) => sum + t.duration);
              final totalDuration = Duration(seconds: totalSeconds.round());
              final mins = totalDuration.inMinutes;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          '${tracks.length} tracks',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                        const Text(
                          ' \u00b7 ',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF999999)),
                        ),
                        Text(
                          '$mins min',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...tracks.map((song) => SongTile(song: song)),
                ],
              );
            },
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(message: e.toString()),
          ),
        ],
      ),
    );
  }
}
