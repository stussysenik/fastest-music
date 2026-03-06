import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/music_kit_availability_provider.dart';
import '../../providers/recently_played_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/artist_nationality_provider.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/stacked_artwork_preview.dart';
import '../../models/discovery_section.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';
import '../../shared_widgets/empty_state.dart';

/// Home screen — the app's landing page.
///
/// ## Visual hierarchy (educational)
///
/// The home screen now visually distinguishes "My Data" (recently played)
/// from "Discovery" (curated sections). Recently Played uses a history icon,
/// song count badge, and subtle dark left-border accent. Discovery sections
/// use a sparkle icon, colored backgrounds, and "Trending" labels.
/// This distinction helps users instantly know whether they're looking
/// at their personal listening history vs curated recommendations.
class LastListenedScreen extends ConsumerWidget {
  const LastListenedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(musicKitAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Browse by Year',
            onPressed: () => context.go('/last-listened/decades'),
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Artist Nationalities',
            onPressed: () => context.go('/last-listened/nationalities'),
          ),
        ],
      ),
      body: switch (availability) {
        // Still checking — show discovery while we wait
        MusicKitAvailability.checking => const _DiscoveryOnlyHome(),

        // MusicKit available — show recently played + discovery
        MusicKitAvailability.available => _HomeWithRecentlyPlayed(ref: ref),

        // MusicKit unavailable — show discovery-only mode
        MusicKitAvailability.unavailable => const _DiscoveryOnlyHome(),
      },
    );
  }
}

/// Home body when MusicKit is available — recently played songs + discovery.
class _HomeWithRecentlyPlayed extends StatelessWidget {
  const _HomeWithRecentlyPlayed({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () async {
        ref.invalidate(recentlyPlayedProvider);
        ref.invalidate(discoveryFeedProvider);
        await ref.read(recentlyPlayedProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Recently played section — "My Data" visual language
          recentlyPlayed.when(
            data: (songs) {
              if (songs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyState(
                    message:
                        'No recently played songs.\nListen to some music first!',
                    icon: Icons.history,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header with icon and count badge
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.history,
                            size: 22, color: Color(0xFF333333)),
                        const SizedBox(width: 8),
                        const Text(
                          'Recently Played',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${songs.length} songs',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Songs with subtle left-border accent
                  ...songs.map((song) => Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Color(0xFF333333),
                              width: 3,
                            ),
                          ),
                        ),
                        child: SongTile(song: song),
                      )),
                  const Divider(height: 24),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingIndicator(),
            ),
            error: (_, __) => ErrorView(
              message: 'Could not load recently played songs',
              onRetry: () => ref.invalidate(recentlyPlayedProvider),
            ),
          ),

          // Discovery sections below recently played
          const _DiscoverySections(),
        ],
      ),
    );
  }
}

/// Home body when MusicKit is unavailable — browse-only discovery feed.
class _DiscoveryOnlyHome extends StatelessWidget {
  const _DiscoveryOnlyHome();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome banner for standalone mode
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.explore, size: 48, color: Color(0xFF666666)),
              SizedBox(height: 12),
              Text(
                'Music Browser',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Browse and discover music from around the world.\nUse the Browse tab to search, or explore the World tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Discovery sections
        const _DiscoverySections(),
      ],
    );
  }
}

/// Reusable discovery sections widget — used in both MusicKit and standalone modes.
class _DiscoverySections extends ConsumerWidget {
  const _DiscoverySections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(discoveryFeedProvider);

    return discoveryAsync.when(
      data: (sections) {
        if (sections.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Discovery header with sparkle icon
            if (sections.isNotEmpty && sections.first.albums.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 24, color: Color(0xFF7C3AED)),
                        SizedBox(width: 8),
                        Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Trending',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: StackedArtworkPreview(
                        artworkUrls: sections
                            .expand((s) => s.albums)
                            .where((a) =>
                                a.artworkUrl != null &&
                                a.artworkUrl!.isNotEmpty)
                            .take(5)
                            .map((a) => a.artworkUrl!)
                            .toList(),
                        cardSize: 140,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

            // Individual sections
            ...sections
                .map((section) => _DiscoverySectionRow(section: section)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(height: 12),
              Text(
                'Loading discoveries...',
                style: TextStyle(color: Color(0xFF999999), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// A single discovery section — title + horizontal album scroll with numbers.
class _DiscoverySectionRow extends StatelessWidget {
  final DiscoverySection section;

  const _DiscoverySectionRow({required this.section});

  @override
  Widget build(BuildContext context) {
    final countryCode = section.countryCode;
    final title = section.title;
    final albums = section.albums;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with icon, flag, title, and album count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (countryCode != null) ...[
                Text(
                  countryCodeToEmoji(countryCode),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.public, size: 20, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${albums.length} albums',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final album = albums[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/album/${album.id}?name=${Uri.encodeComponent(album.title)}',
                ),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artwork with year badge overlay
                      Stack(
                        children: [
                          ArtworkImage(
                            url: album.artworkUrl,
                            size: 140,
                            borderRadius: 10,
                            imageSize: ArtworkImageSize.medium,
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
                      const SizedBox(height: 8),
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
                          Flexible(
                            child: Text(
                              album.artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                          if (album.trackCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '${album.trackCount} trks',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFBBBBBB),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
