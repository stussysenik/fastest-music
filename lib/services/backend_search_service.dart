import 'package:dio/dio.dart';
import '../core/config/api_config.dart';
import '../models/album.dart';

/// Service that hits the Elixir backend's /api/search endpoint.
///
/// ## Architecture (educational)
///
/// This service talks to our Elixir/Phoenix backend, which provides:
/// - L1 ETS cache (~1μs reads) for repeat queries
/// - L2 Postgres cache (~5ms) that survives server restarts
/// - L3 fan-out to iTunes + MusicBrainz APIs with circuit breakers
///
/// The backend returns JSON that matches our Freezed Album model exactly,
/// so Album.fromJson() works without any mapping.
class BackendSearchService {
  final Dio _dio;

  BackendSearchService(this._dio);

  /// Search for albums via the backend.
  /// Returns a list of Album objects and whether the result was cached.
  Future<({List<Album> albums, bool cached})> searchAlbums(
    String query, {
    String? genre,
    int? yearFrom,
    int? yearTo,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'type': 'album',
    };
    if (genre != null) queryParams['genre'] = genre;
    if (yearFrom != null) queryParams['year_from'] = yearFrom.toString();
    if (yearTo != null) queryParams['year_to'] = yearTo.toString();

    final response = await _dio.get(
      '/api/search',
      queryParameters: queryParams,
      options: Options(
        sendTimeout: ApiConfig.searchTimeout,
        receiveTimeout: ApiConfig.searchTimeout,
      ),
    );

    final data = response.data as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>?) ?? [];
    final cached = data['cached'] as bool? ?? false;

    final albums = results
        .map((e) => Album.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return (albums: albums, cached: cached);
  }
}
