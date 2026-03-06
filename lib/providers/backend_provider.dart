import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../core/config/api_config.dart';
import '../services/album_cover_service.dart';
import '../services/backend_search_service.dart';
import '../services/federated_music_service.dart';
import 'authorization_provider.dart';

/// Dio HTTP cache options — persists responses to Hive for offline support.
///
/// ## Why HTTP-level caching? (educational)
///
/// This is a separate layer from the Hive SWR cache in providers.
/// SWR caches the *parsed* domain objects (songs, albums).
/// HTTP caching caches the *raw HTTP responses* from the backend.
/// Together they provide two tiers:
/// 1. SWR: instant UI from parsed data (Layer 1)
/// 2. HTTP cache: fast responses even when "revalidating" (Layer 4)
///
/// With cache-control headers from the backend, repeat requests can be
/// served from disk without hitting the network at all.
final _cacheOptionsProvider = FutureProvider<CacheOptions>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final store = HiveCacheStore('${dir.path}/dio_http_cache');
  return CacheOptions(
    store: store,
    policy: CachePolicy.forceCache,
    maxStale: const Duration(hours: 1),
  );
});

/// Dio HTTP client configured for the Elixir backend with caching.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.backendUrl,
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: ApiConfig.searchTimeout,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  // Add cache interceptor asynchronously — it will be ready before
  // any real network requests fire (Hive SWR serves the first frame).
  ref.listen(_cacheOptionsProvider, (_, next) {
    next.whenData((options) {
      dio.interceptors.add(DioCacheInterceptor(options: options));
    });
  });

  return dio;
});

/// Backend search service provider.
final backendSearchServiceProvider = Provider<BackendSearchService?>((ref) {
  try {
    final dio = ref.watch(dioProvider);
    return BackendSearchService(dio);
  } catch (_) {
    return null;
  }
});

/// Album cover service provider.
final albumCoverServiceProvider = Provider<AlbumCoverService?>((ref) {
  try {
    final dio = ref.watch(dioProvider);
    return AlbumCoverService(dio);
  } catch (_) {
    return null;
  }
});

/// Federated music service — races backend + MusicKit for catalog search.
final federatedMusicServiceProvider = Provider<FederatedMusicService>((ref) {
  final musicKitService = ref.watch(musicKitServiceProvider);
  final backendService = ref.watch(backendSearchServiceProvider);
  return FederatedMusicService(musicKitService, backendService);
});
