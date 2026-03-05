import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../providers/music_kit_availability_provider.dart';
import '../providers/player_controls_provider.dart';
import 'song_artwork.dart';

class SongTile extends ConsumerWidget {
  final Song song;
  final bool showTrackNumber;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    this.showTrackNumber = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: showTrackNumber
          ? SizedBox(
              width: 56,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${song.trackNumber ?? ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SongArtwork(song: song, size: 40, borderRadius: 4),
                ],
              ),
            )
          : SongArtwork(song: song, size: 48),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        song.artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatDuration(song.duration),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.push('/song-detail', extra: song),
            child: const Icon(
              Icons.info_outline,
              size: 20,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
      onTap: onTap ??
          () {
            final availability = ref.read(musicKitAvailabilityProvider);
            if (availability != MusicKitAvailability.available) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Playback requires Apple Music'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            ref.read(playerControlsProvider).playSong(song.id);
          },
      onLongPress: () => context.push('/song-detail', extra: song),
    );
  }

  Widget _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return Text(
      '$minutes:${secs.toString().padLeft(2, '0')}',
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF999999),
      ),
    );
  }
}
