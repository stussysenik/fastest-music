import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../models/discovery_section.dart';
import '../core/cache/local_cache_service.dart';
import 'backend_provider.dart';
import 'local_cache_provider.dart';

/// Discovery feed provider — curated themed sections from the nationalities dataset.
///
/// ## SWR pattern (educational)
///
/// The discovery feed is the most expensive data to load (~48 sequential HTTP
/// requests on cold start, 2-10 seconds). But the data changes rarely — album
/// catalogs don't update hourly. This makes it a perfect SWR candidate:
/// serve from Hive cache instantly, then refresh in the background.
final discoveryFeedProvider =
    AsyncNotifierProvider<DiscoveryFeedNotifier, List<DiscoverySection>>(
        DiscoveryFeedNotifier.new);

class DiscoveryFeedNotifier extends AsyncNotifier<List<DiscoverySection>> {
  /// SWR TTL — discovery data changes rarely, so a longer TTL is appropriate.
  static const _staleDuration = Duration(hours: 1);

  @override
  Future<List<DiscoverySection>> build() async {
    final cache = ref.read(localCacheProvider);

    // Phase 1: Serve cached data instantly.
    final cached = _readCache(cache);
    if (cached != null && cached.isNotEmpty) {
      state = AsyncData(cached);
      _revalidateInBackground(cache);
      return cached;
    }

    // No cache — fetch from network (slow but unavoidable on first launch).
    return _fetchFromNetwork(cache);
  }

  /// Deserialize discovery sections from Hive cache.
  ///
  /// We store sections as JSON with a custom shape since DiscoverySection
  /// isn't a Freezed class. Each section stores title, countryCode, and
  /// a list of Album JSON objects.
  List<DiscoverySection>? _readCache(LocalCacheService cache) {
    final jsonList = cache.getJsonList(LocalCacheService.discoveryFeedKey);
    if (jsonList == null) return null;
    try {
      return jsonList.map((j) {
        final albums = (j['albums'] as List)
            .map((a) => Album.fromJson(a as Map<String, dynamic>))
            .toList();
        return DiscoverySection(
          title: j['title'] as String,
          albums: albums,
          countryCode: j['countryCode'] as String?,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// Serialize and persist sections to Hive.
  Future<void> _writeCache(
      LocalCacheService cache, List<DiscoverySection> sections) async {
    final jsonList = sections.map((s) => <String, dynamic>{
      'title': s.title,
      'countryCode': s.countryCode,
      'albums': s.albums.map((a) => a.toJson()).toList(),
    }).toList();
    await cache.putJsonList(LocalCacheService.discoveryFeedKey, jsonList);
  }

  Future<List<DiscoverySection>> _fetchFromNetwork(
      LocalCacheService cache) async {
    final backendService = ref.read(backendSearchServiceProvider);
    if (backendService == null) return [];

    final jsonStr =
        await rootBundle.loadString('assets/data/artist_nationalities.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    final artists = data.map((key, value) => MapEntry(key, value as String));

    final sections = <_SectionDef>[
      _SectionDef('K-Pop Hits', 'KR',
          ['BTS', 'BLACKPINK', 'NewJeans', 'Stray Kids', 'aespa']),
      _SectionDef('Afrobeats', 'NG',
          ['Burna Boy', 'Wizkid', 'Rema', 'Tems', 'Asake']),
      _SectionDef('Latin Music', null,
          ['Bad Bunny', 'Karol G', 'Peso Pluma', 'Rosalía', 'Rauw Alejandro']),
      _SectionDef('British Icons', 'GB',
          ['Ed Sheeran', 'Adele', 'Dua Lipa', 'Coldplay', 'Arctic Monkeys']),
      _SectionDef('US Trending', 'US', [
        'SZA',
        'Tyler, The Creator',
        'Doja Cat',
        'Olivia Rodrigo',
        'Billie Eilish'
      ]),
      _SectionDef('Canadian Stars', 'CA',
          ['Drake', 'The Weeknd', 'Justin Bieber', 'Daniel Caesar']),
      _SectionDef('J-Pop & J-Rock', 'JP',
          ['Ado', 'YOASOBI', 'Kenshi Yonezu', 'Fujii Kaze', 'ONE OK ROCK']),
      _SectionDef('Australian Wave', 'AU',
          ['Tame Impala', 'Troye Sivan', 'The Kid LAROI', 'Sia']),
      _SectionDef('French Touch', 'FR', [
        'Daft Punk',
        'Aya Nakamura',
        'Christine and the Queens',
        'Justice'
      ]),
      _SectionDef('Scandinavian Pop', null,
          ['ABBA', 'Robyn', 'Aurora', 'Sigrid', 'Avicii']),
      _SectionDef('Indian Vibes', 'IN',
          ['Arijit Singh', 'A.R. Rahman', 'Diljit Dosanjh']),
      _SectionDef('Brazilian Heat', 'BR', ['Anitta', 'Luísa Sonza']),
      _SectionDef('Hip-Hop Legends', 'US',
          ['Kendrick Lamar', 'Kanye West', 'Eminem', 'Jay-Z']),
      _SectionDef('Electronic & Dance', null,
          ['Calvin Harris', 'Martin Garrix', 'Tiësto', 'Kygo', 'Deadmau5']),
      _SectionDef('Rock Essentials', null, [
        'Imagine Dragons',
        'Foo Fighters',
        'Linkin Park',
        'Red Hot Chili Peppers'
      ]),
      _SectionDef(
          'South African Sounds', 'ZA', ['Tyla', 'Nasty C', 'Black Coffee']),
    ];

    final result = <DiscoverySection>[];
    for (final section in sections) {
      final validArtists = section.artists
          .where((name) => artists.containsKey(name))
          .take(3)
          .toList();

      if (validArtists.isEmpty) continue;

      final sectionAlbums = <Album>[];
      for (final artistName in validArtists) {
        try {
          final searchResult = await backendService.searchAlbums(artistName);
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

    // Persist to Hive for instant loading on next launch.
    await _writeCache(cache, result);
    return result;
  }

  /// Background revalidate: fetch fresh data without blocking UI.
  Future<void> _revalidateInBackground(LocalCacheService cache) async {
    if (!cache.isStale(LocalCacheService.discoveryFeedKey, _staleDuration)) {
      return;
    }
    try {
      final fresh = await _fetchFromNetwork(cache);
      if (fresh.isNotEmpty) {
        state = AsyncData(fresh);
      }
    } catch (_) {
      // Stale data is better than no data.
    }
  }
}

class _SectionDef {
  final String title;
  final String? countryCode;
  final List<String> artists;

  const _SectionDef(this.title, this.countryCode, this.artists);
}
