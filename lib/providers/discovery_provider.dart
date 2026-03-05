import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../models/discovery_section.dart';
import 'backend_provider.dart';

/// Discovery feed provider — curated themed sections from the nationalities dataset.
///
/// ## How it works (educational)
///
/// 1. Loads the 297 artists from artist_nationalities.json
/// 2. Groups them into themed sections (K-Pop, Afrobeats, Latin, etc.)
/// 3. For each section, picks a few representative artists and searches
///    the backend for their albums
/// 4. Returns a list of DiscoverySections ready for the UI
///
/// This runs lazily — sections are only fetched when the home screen renders.
/// Results are cached by Riverpod's FutureProvider for the session.
final discoveryFeedProvider =
    FutureProvider<List<DiscoverySection>>((ref) async {
  final backendService = ref.read(backendSearchServiceProvider);
  if (backendService == null) return [];

  // Load artist nationalities
  final jsonStr =
      await rootBundle.loadString('assets/data/artist_nationalities.json');
  final Map<String, dynamic> data = json.decode(jsonStr);
  final artists = data.map((key, value) => MapEntry(key, value as String));

  // Define themed sections with representative artists
  final sections = <_SectionDef>[
    _SectionDef('K-Pop Hits', 'KR', ['BTS', 'BLACKPINK', 'NewJeans', 'Stray Kids', 'aespa']),
    _SectionDef('Afrobeats', 'NG', ['Burna Boy', 'Wizkid', 'Rema', 'Tems', 'Asake']),
    _SectionDef('Latin Music', null, ['Bad Bunny', 'Karol G', 'Peso Pluma', 'Rosalía', 'Rauw Alejandro']),
    _SectionDef('British Icons', 'GB', ['Ed Sheeran', 'Adele', 'Dua Lipa', 'Coldplay', 'Arctic Monkeys']),
    _SectionDef('US Trending', 'US', ['SZA', 'Tyler, The Creator', 'Doja Cat', 'Olivia Rodrigo', 'Billie Eilish']),
    _SectionDef('Canadian Stars', 'CA', ['Drake', 'The Weeknd', 'Justin Bieber', 'Daniel Caesar']),
    _SectionDef('J-Pop & J-Rock', 'JP', ['Ado', 'YOASOBI', 'Kenshi Yonezu', 'Fujii Kaze', 'ONE OK ROCK']),
    _SectionDef('Australian Wave', 'AU', ['Tame Impala', 'Troye Sivan', 'The Kid LAROI', 'Sia']),
    _SectionDef('French Touch', 'FR', ['Daft Punk', 'Aya Nakamura', 'Christine and the Queens', 'Justice']),
    _SectionDef('Scandinavian Pop', null, ['ABBA', 'Robyn', 'Aurora', 'Sigrid', 'Avicii']),
    _SectionDef('Indian Vibes', 'IN', ['Arijit Singh', 'A.R. Rahman', 'Diljit Dosanjh']),
    _SectionDef('Brazilian Heat', 'BR', ['Anitta', 'Luísa Sonza']),
    _SectionDef('Hip-Hop Legends', 'US', ['Kendrick Lamar', 'Kanye West', 'Eminem', 'Jay-Z']),
    _SectionDef('Electronic & Dance', null, ['Calvin Harris', 'Martin Garrix', 'Tiësto', 'Kygo', 'Deadmau5']),
    _SectionDef('Rock Essentials', null, ['Imagine Dragons', 'Foo Fighters', 'Linkin Park', 'Red Hot Chili Peppers']),
    _SectionDef('South African Sounds', 'ZA', ['Tyla', 'Nasty C', 'Black Coffee']),
  ];

  // Fetch albums for each section (limit concurrent requests)
  final result = <DiscoverySection>[];
  for (final section in sections) {
    // Filter to artists that actually exist in the dataset
    final validArtists = section.artists
        .where((name) => artists.containsKey(name))
        .take(3)
        .toList();

    if (validArtists.isEmpty) continue;

    final sectionAlbums = <Album>[];
    for (final artistName in validArtists) {
      try {
        final searchResult = await backendService.searchAlbums(artistName);
        // Take up to 3 albums per artist
        sectionAlbums.addAll(searchResult.albums.take(3));
      } catch (_) {
        // Skip failed artist lookups
      }
    }

    if (sectionAlbums.isNotEmpty) {
      result.add(DiscoverySection(
        title: section.title,
        albums: sectionAlbums,
        countryCode: section.countryCode,
      ));
    }
  }

  return result;
});

class _SectionDef {
  final String title;
  final String? countryCode;
  final List<String> artists;

  const _SectionDef(this.title, this.countryCode, this.artists);
}
