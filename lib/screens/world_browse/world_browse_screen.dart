import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/country_names.dart';
import '../../providers/artist_nationality_provider.dart';
import '../../shared_widgets/artist_country_card.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';

/// World Browse tab — artists organized by country with artwork.
///
/// ## Architecture (educational)
///
/// This screen loads the 92 artists from `artist_nationalities.json`,
/// groups them by country code, and renders each country as a section
/// with a horizontal scroll of `ArtistCountryCard` widgets.
///
/// Each `ArtistCountryCard` lazily resolves artwork via `artistArtworkProvider`,
/// which searches the backend for albums by artist name and uses the first
/// album's artwork as a proxy. This means artwork appears progressively
/// as the user scrolls — a pattern called "progressive loading".
///
/// Tapping an artist navigates to `BackendArtistDetailScreen` which uses
/// the artist's name (not a MusicKit ID) to fetch albums from the backend.
class WorldBrowseScreen extends ConsumerWidget {
  const WorldBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nationalitiesAsync = ref.watch(artistNationalitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('World'),
      ),
      body: nationalitiesAsync.when(
        data: (nationalities) {
          // Group artists by country code
          final grouped = <String, List<String>>{};
          for (final entry in nationalities.entries) {
            grouped.putIfAbsent(entry.value, () => []).add(entry.key);
          }

          // Sort countries by number of artists (most first), then alphabetically
          final sortedCountries = grouped.keys.toList()
            ..sort((a, b) {
              final countDiff = grouped[b]!.length.compareTo(grouped[a]!.length);
              if (countDiff != 0) return countDiff;
              return a.compareTo(b);
            });

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: sortedCountries.length,
            itemBuilder: (context, index) {
              final code = sortedCountries[index];
              final artists = grouped[code]!..sort();
              final flag = countryCodeToEmoji(code);
              final name = countryNames[code] ?? code;

              return _CountrySection(
                flag: flag,
                countryName: name,
                artists: artists,
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(artistNationalitiesProvider),
        ),
      ),
    );
  }
}

/// A single country section with horizontal artist scroll.
class _CountrySection extends StatelessWidget {
  final String flag;
  final String countryName;
  final List<String> artists;

  const _CountrySection({
    required this.flag,
    required this.countryName,
    required this.artists,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countryName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${artists.length} ${artists.length == 1 ? 'artist' : 'artists'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal artist scroll
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: artists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ArtistCountryCard(
                artistName: artists[index],
                onTap: () => context.push(
                  '/backend-artist/${Uri.encodeComponent(artists[index])}',
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),
      ],
    );
  }
}
