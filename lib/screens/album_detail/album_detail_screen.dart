import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../providers/authorization_provider.dart';
import '../../providers/music_kit_availability_provider.dart';
import '../../providers/player_controls_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';

final _albumDetailProvider =
    FutureProvider.family<Album, String>((ref, id) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getAlbum(id);
});

final _albumTracksProvider =
    FutureProvider.family<List<Song>, String>((ref, id) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getAlbumTracks(id);
});

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  final String albumName;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    this.albumName = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(_albumDetailProvider(albumId));
    final tracksAsync = ref.watch(_albumTracksProvider(albumId));

    return Scaffold(
      appBar: AppBar(
        title: Text(albumName),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Album header
          albumAsync.when(
            data: (album) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ArtworkImage(
                    url: album.artworkUrl,
                    size: MediaQuery.of(context).size.width * 0.6,
                    borderRadius: 12,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    album.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.artistName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (album.genreNames.isNotEmpty)
                          Text(
                            album.genreNames.first,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (album.releaseDate != null) ...[
                          const Text(' \u00b7 ',
                              style: TextStyle(color: Color(0xFF999999))),
                          Text(
                            album.releaseDate!.substring(0, 4),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (album.trackCount > 0) ...[
                          const Text(' \u00b7 ',
                              style: TextStyle(color: Color(0xFF999999))),
                          Text(
                            '${album.trackCount} tracks',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Play button — only functional when MusicKit is available
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
                          ref.read(playerControlsProvider).playAlbum(album.id);
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text('Play',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canPlay ? Colors.black : Colors.grey,
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
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(message: e.toString()),
          ),

          const Divider(),

          // Track listing with total duration
          tracksAsync.when(
            data: (tracks) {
              if (tracks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tracks available'),
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
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFF999999)),
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
                  ...tracks
                      .map((song) => SongTile(
                            song: song,
                            showTrackNumber: true,
                          ))
                      .toList(),
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
