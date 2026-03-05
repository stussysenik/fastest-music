import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/decade_browse_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/stacked_artwork_preview.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';

/// Browse music organized by decade — 2020s, 2010s, 2000s, 90s, 80s, etc.
///
/// ## Design (educational)
///
/// Each decade section shows a stacked artwork hero preview plus a
/// horizontal scroll of albums from that era. The backend's year_from/year_to
/// filters ensure we get era-appropriate albums, not just "all albums by
/// an artist who was popular in the 80s."
class DecadeBrowseScreen extends ConsumerWidget {
  const DecadeBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decadesAsync = ref.watch(decadeBrowseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('By Year'),
      ),
      body: decadesAsync.when(
        data: (sections) {
          if (sections.isEmpty) {
            return const Center(
              child: Text('No decade data available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              final artworkUrls = section.albums
                  .where(
                      (a) => a.artworkUrl != null && a.artworkUrl!.isNotEmpty)
                  .take(5)
                  .map((a) => a.artworkUrl!)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decade header with stacked preview
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        // Decade label with era styling
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _decadeColor(section.title),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            section.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${section.albums.length} albums',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stacked preview hero
                  if (artworkUrls.length >= 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: StackedArtworkPreview(
                          artworkUrls: artworkUrls,
                          cardSize: 100,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Horizontal album scroll
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: section.albums.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, albumIndex) {
                        final album = section.albums[albumIndex];
                        return GestureDetector(
                          onTap: () => context.push(
                            '/album/${album.id}?name=${Uri.encodeComponent(album.title)}',
                          ),
                          child: SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ArtworkImage(
                                  url: album.artworkUrl,
                                  size: 140,
                                  borderRadius: 10,
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
                                Text(
                                  album.artistName,
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
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1),
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading decades...',
                style: TextStyle(color: Color(0xFF999999), fontSize: 13),
              ),
            ],
          ),
        ),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(decadeBrowseProvider),
        ),
      ),
    );
  }

  Color _decadeColor(String decade) {
    switch (decade) {
      case '2020s':
        return const Color(0xFF6C5CE7);
      case '2010s':
        return const Color(0xFF00B894);
      case '2000s':
        return const Color(0xFFE17055);
      case '90s':
        return const Color(0xFF0984E3);
      case '80s':
        return const Color(0xFFE84393);
      default:
        return const Color(0xFFFDAA5E);
    }
  }
}
