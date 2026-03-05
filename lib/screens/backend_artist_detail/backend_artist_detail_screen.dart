import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/artist_provider.dart';
import '../../providers/artist_artwork_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';

/// Artist detail screen powered by backend search (no MusicKit ID needed).
///
/// ## When to use this vs ArtistDetailScreen (educational)
///
/// - `ArtistDetailScreen` takes a MusicKit ID — used when navigating from
///   MusicKit search results where we have the Apple Music catalog ID.
/// - `BackendArtistDetailScreen` takes just an artist name — used when
///   navigating from the World Browse tab or discovery feed, where we
///   only have the artist's name from our nationalities dataset.
///
/// Both show albums, but this screen fetches via `backendArtistAlbumsProvider`
/// which searches the Elixir backend by name rather than querying MusicKit.
class BackendArtistDetailScreen extends ConsumerWidget {
  final String artistName;

  const BackendArtistDetailScreen({
    super.key,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(backendArtistAlbumsProvider(artistName));
    final artworkAsync = ref.watch(artistArtworkProvider(artistName));

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Artist header with resolved artwork
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                artworkAsync.when(
                  data: (url) => ArtworkImage(
                    url: url,
                    size: 120,
                    borderRadius: 60,
                    placeholderIcon: Icons.person,
                  ),
                  loading: () => const ArtworkImage(
                    size: 120,
                    borderRadius: 60,
                    placeholderIcon: Icons.person,
                  ),
                  error: (_, __) => const ArtworkImage(
                    size: 120,
                    borderRadius: 60,
                    placeholderIcon: Icons.person,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  artistName,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Divider(),

          // Albums section with count badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Albums',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (albumsAsync.valueOrNull != null &&
                    albumsAsync.valueOrNull!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${albumsAsync.valueOrNull!.length}',
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
          ),
          albumsAsync.when(
            data: (albums) {
              if (albums.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No albums found'),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
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
                                        color: Colors.black
                                            .withValues(alpha: 0.7),
                                        borderRadius:
                                            BorderRadius.circular(6),
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
                                        fontSize: 12,
                                        color: Color(0xFF999999)),
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
          ),
        ],
      ),
    );
  }
}
