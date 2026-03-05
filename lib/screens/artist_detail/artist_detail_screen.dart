import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/album.dart';
import '../../providers/artist_provider.dart';
import '../../providers/music_kit_availability_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;
  final String artistName;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    this.artistName = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(musicKitAvailabilityProvider);
    final useMusicKit = availability == MusicKitAvailability.available;

    // When MusicKit is available, use the full MusicKit providers.
    // When unavailable, fall back to backend-only album search.
    final artistAsync =
        useMusicKit ? ref.watch(artistDetailProvider(artistId)) : null;
    final topSongsAsync =
        useMusicKit ? ref.watch(artistTopSongsProvider(artistId)) : null;

    // Always try to get albums — prefer MusicKit, fall back to backend by name
    final musicKitAlbumsAsync =
        useMusicKit ? ref.watch(artistAlbumsProvider(artistId)) : null;
    final backendAlbumsAsync = !useMusicKit && artistName.isNotEmpty
        ? ref.watch(backendArtistAlbumsProvider(artistName))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Artist header
          if (artistAsync != null)
            artistAsync.when(
              data: (artist) => _buildArtistHeader(context, artist.name,
                  artist.artworkUrl, artist.genreNames),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LoadingIndicator(),
              ),
              error: (e, _) => _buildArtistHeader(
                  context, artistName, null, const []),
            )
          else
            _buildArtistHeader(context, artistName, null, const []),

          const Divider(),

          // Top Songs (MusicKit only — backend doesn't have individual songs)
          if (topSongsAsync != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Top Songs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            topSongsAsync.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No top songs available'),
                  );
                }
                return Column(
                  children:
                      songs.map((song) => SongTile(song: song)).toList(),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(message: e.toString()),
            ),
            const Divider(),
          ],

          // Albums header with count badge
          _buildAlbumsHeader(context, musicKitAlbumsAsync ?? backendAlbumsAsync),
          _buildAlbumsGrid(
            context,
            musicKitAlbumsAsync ?? backendAlbumsAsync,
          ),
        ],
      ),
    );
  }

  Widget _buildArtistHeader(BuildContext context, String name, String? artworkUrl,
      List<String> genreNames) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ArtworkImage(
            url: artworkUrl,
            size: 100,
            borderRadius: 50,
            placeholderIcon: Icons.person,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (genreNames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      genreNames.join(', '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsHeader(BuildContext context, AsyncValue<List<Album>>? albumsAsync) {
    final count = albumsAsync?.valueOrNull?.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Albums',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlbumsGrid(BuildContext context, AsyncValue<List<Album>>? albumsAsync) {
    if (albumsAsync == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No albums available'),
      );
    }

    return albumsAsync.when(
      data: (albumList) {
        if (albumList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No albums available'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: albumList.length,
            itemBuilder: (context, index) {
              final album = albumList[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/album/${album.id}?name=${Uri.encodeComponent(album.title)}',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ArtworkImage(
                            url: album.artworkUrl,
                            size: double.infinity,
                            borderRadius: 10,
                          ),
                          if (album.releaseDate != null &&
                              album.releaseDate!.length >= 4)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  album.releaseDate!.substring(0, 4),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        if (album.releaseDate != null &&
                            album.releaseDate!.length >= 4)
                          Flexible(
                            child: Text(
                              album.releaseDate!.substring(0, 4),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                        if (album.trackCount > 0) ...[
                          if (album.releaseDate != null)
                            const Text(
                              ' \u00b7 ',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF999999)),
                            ),
                          Text(
                            '${album.trackCount} trks',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}
