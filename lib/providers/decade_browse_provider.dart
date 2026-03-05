import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../models/discovery_section.dart';
import 'backend_provider.dart';

/// Decade browse provider — fetches albums organized by decade/era.
///
/// ## How it works (educational)
///
/// Unlike the discovery feed (which groups by genre/region), this provider
/// groups by time period. It picks representative artists for each decade
/// and searches the backend with year filters to get era-appropriate albums.
///
/// The backend's `/api/search` endpoint supports `year_from` and `year_to`
/// query params, so we can filter to specific decades server-side.
final decadeBrowseProvider =
    FutureProvider<List<DiscoverySection>>((ref) async {
  final backendService = ref.read(backendSearchServiceProvider);
  if (backendService == null) return [];

  // Load artist nationalities for artist pool
  final jsonStr =
      await rootBundle.loadString('assets/data/artist_nationalities.json');
  final Map<String, dynamic> data = json.decode(jsonStr);
  final allArtists = data.keys.toList();

  // Define decades with representative search queries
  final decades = <_DecadeDef>[
    _DecadeDef('2020s', 2020, 2026, [
      'Olivia Rodrigo', 'Bad Bunny', 'SZA', 'NewJeans', 'Peso Pluma',
      'Tyla', 'Ice Spice', 'Asake',
    ]),
    _DecadeDef('2010s', 2010, 2019, [
      'Drake', 'Taylor Swift', 'Billie Eilish', 'BTS', 'Kendrick Lamar',
      'Post Malone', 'Adele', 'Ed Sheeran',
    ]),
    _DecadeDef('2000s', 2000, 2009, [
      'Beyoncé', 'Eminem', 'Kanye West', 'Rihanna', 'Lady Gaga',
      'Amy Winehouse', 'Nelly Furtado',
    ]),
    _DecadeDef('90s', 1990, 1999, [
      'Whitney Houston', 'Michael Jackson', 'Radiohead', 'Björk',
      'Daft Punk',
    ]),
    _DecadeDef('80s', 1980, 1989, [
      'Michael Jackson', 'Prince', 'Queen', 'David Bowie',
      'AC/DC',
    ]),
    _DecadeDef('70s & Earlier', 1950, 1979, [
      'The Beatles', 'Elvis Presley', 'Stevie Wonder', 'Bob Marley',
      'ABBA', 'Elton John',
    ]),
  ];

  final result = <DiscoverySection>[];
  for (final decade in decades) {
    // Filter to artists that exist in our dataset
    final validArtists = decade.artists
        .where((name) => allArtists.contains(name))
        .take(3)
        .toList();

    if (validArtists.isEmpty) continue;

    final decadeAlbums = <Album>[];
    for (final artistName in validArtists) {
      try {
        final searchResult = await backendService.searchAlbums(
          artistName,
          yearFrom: decade.yearFrom,
          yearTo: decade.yearTo,
        );
        decadeAlbums.addAll(searchResult.albums.take(3));
      } catch (_) {
        // Skip failed lookups
      }
    }

    if (decadeAlbums.isNotEmpty) {
      result.add(DiscoverySection(
        title: decade.label,
        albums: decadeAlbums,
      ));
    }
  }

  return result;
});

class _DecadeDef {
  final String label;
  final int yearFrom;
  final int yearTo;
  final List<String> artists;

  const _DecadeDef(this.label, this.yearFrom, this.yearTo, this.artists);
}
