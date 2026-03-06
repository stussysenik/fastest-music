import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/cache/local_cache_service.dart';
import 'providers/local_cache_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for zero-latency local data persistence.
  // This must complete before runApp() so cached data is available
  // on the very first frame — enabling the SWR pattern in providers.
  final cacheService = LocalCacheService();
  await cacheService.init();

  // Increase Flutter's in-memory image cache limits.
  //
  // ## Why larger limits? (educational)
  //
  // Default ImageCache holds 100 images / 100MB. For a music app with
  // artwork-heavy screens (discovery feed, library, playlists), this
  // evicts images too aggressively. By raising to 500/500MB, precached
  // artwork stays in RAM across tab switches — eliminating re-decode
  // delays that would otherwise show shimmer/placeholders.
  PaintingBinding.instance.imageCache.maximumSize = 500;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;

  runApp(
    ProviderScope(
      overrides: [
        localCacheProvider.overrideWithValue(cacheService),
      ],
      child: const FastestMusicApp(),
    ),
  );
}
