import 'package:dio/dio.dart';
import '../core/config/api_config.dart';

/// Service for fetching album artwork from the Elixir backend.
///
/// ## Multi-source artwork resolution (educational)
///
/// The backend's ArtworkResolver checks three tiers:
/// 1. ETS cache (microseconds — in-memory)
/// 2. Postgres cache (milliseconds — persistent)
/// 3. External APIs: iTunes Search, then MusicBrainz Cover Art Archive
///
/// This means artwork URLs are resolved once and then served instantly
/// for all future requests across all users.
class AlbumCoverService {
  final Dio _dio;

  AlbumCoverService(this._dio);

  /// Get artwork URL for a specific artist + album combination.
  Future<String?> getArtworkUrl(String artist, String album) async {
    try {
      final response = await _dio.get(
        '/api/albums/by-name/artwork',
        queryParameters: {'artist': artist, 'album': album},
        options: Options(
          sendTimeout: ApiConfig.artworkTimeout,
          receiveTimeout: ApiConfig.artworkTimeout,
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return data['artworkUrl'] as String?;
    } on DioException {
      return null;
    }
  }

  /// Batch resolve artwork URLs for multiple albums at once.
  /// Uses Task.async_stream on the backend for concurrent resolution.
  Future<Map<String, String>> batchGetArtworkUrls(
    List<({String artist, String title})> albums,
  ) async {
    if (albums.isEmpty) return {};

    try {
      final response = await _dio.post(
        '/api/artwork/batch',
        data: {
          'albums': albums
              .map((a) => {'artist': a.artist, 'title': a.title})
              .toList(),
        },
        options: Options(
          sendTimeout: ApiConfig.artworkTimeout,
          receiveTimeout: ApiConfig.artworkTimeout,
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];

      final urlMap = <String, String>{};
      for (final r in results) {
        final result = r as Map<String, dynamic>;
        final key = '${result['artist']}|${result['title']}';
        final url = result['artworkUrl'] as String?;
        if (url != null) {
          urlMap[key] = url;
        }
      }
      return urlMap;
    } on DioException {
      return {};
    }
  }
}
