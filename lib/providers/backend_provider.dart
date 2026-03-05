import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_config.dart';
import '../services/album_cover_service.dart';
import '../services/backend_search_service.dart';
import '../services/federated_music_service.dart';
import 'authorization_provider.dart';

/// Dio HTTP client configured for the Elixir backend.
///
/// ## Dio vs http package (educational)
///
/// Dio provides automatic retries, request/response interceptors,
/// timeout configuration, and connection pooling out of the box.
/// This is important for the federated search strategy where we need
/// tight timeout control to fall back to MusicKit quickly.
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
///
/// Catalog search works without MusicKit user authorization, so we always
/// try both sources. Library access (playlists, recently-played) is handled
/// separately through [MusicKitService] which requires auth.
final federatedMusicServiceProvider = Provider<FederatedMusicService>((ref) {
  final musicKitService = ref.watch(musicKitServiceProvider);
  final backendService = ref.watch(backendSearchServiceProvider);
  return FederatedMusicService(musicKitService, backendService);
});
