import 'package:flutter/services.dart';
import '../../core/constants/channel_constants.dart';
import 'music_kit_platform.dart';
import 'music_kit_event_channel.dart';

class MusicKitMethodChannel implements MusicKitPlatform {
  final MethodChannel _channel =
      const MethodChannel(ChannelConstants.methodChannel);
  final MusicKitEventChannel _eventChannel = MusicKitEventChannel();

  @override
  Future<String> requestAuthorization() async {
    final result = await _channel.invokeMethod<String>('requestAuthorization');
    return result ?? 'unknown';
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 10}) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getRecentlyPlayed',
      {'limit': limit},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<Map<String, dynamic>> searchCatalog({
    required String term,
    List<String> types = const ['songs', 'albums', 'artists'],
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'searchCatalog',
      {'term': term, 'types': types},
    );
    return _deepConvertMap(result ?? {});
  }

  @override
  Future<Map<String, dynamic>> getArtist(String id) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getArtist',
      {'id': id},
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<List<Map<String, dynamic>>> getArtistTopSongs(String id,
      {int limit = 10}) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getArtistTopSongs',
      {'id': id, 'limit': limit},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<List<Map<String, dynamic>>> getArtistAlbums(String id) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getArtistAlbums',
      {'id': id},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<Map<String, dynamic>> getAlbum(String id) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getAlbum',
      {'id': id},
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<List<Map<String, dynamic>>> getAlbumTracks(String id) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getAlbumTracks',
      {'id': id},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<bool> playSong(String id) async {
    final result =
        await _channel.invokeMethod<bool>('playSong', {'id': id});
    return result ?? false;
  }

  @override
  Future<bool> playAlbum(String id) async {
    final result =
        await _channel.invokeMethod<bool>('playAlbum', {'id': id});
    return result ?? false;
  }

  @override
  Future<bool> pause() async {
    final result = await _channel.invokeMethod<bool>('pause');
    return result ?? false;
  }

  @override
  Future<bool> resume() async {
    final result = await _channel.invokeMethod<bool>('resume');
    return result ?? false;
  }

  @override
  Future<bool> skipToNext() async {
    final result = await _channel.invokeMethod<bool>('skipToNext');
    return result ?? false;
  }

  @override
  Future<bool> skipToPrevious() async {
    final result = await _channel.invokeMethod<bool>('skipToPrevious');
    return result ?? false;
  }

  @override
  Future<bool> seekTo(double position) async {
    final result =
        await _channel.invokeMethod<bool>('seekTo', {'position': position});
    return result ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getUserPlaylists',
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<Map<String, dynamic>> createPlaylist(String name) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'createPlaylist',
      {'name': name},
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<bool> addSongToPlaylist(String songId, String playlistId) async {
    final result = await _channel.invokeMethod<bool>(
      'addSongToPlaylist',
      {'songId': songId, 'playlistId': playlistId},
    );
    return result ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getPlaylistTracks',
      {'playlistId': playlistId},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<bool> playPlaylist(String id) async {
    final result =
        await _channel.invokeMethod<bool>('playPlaylist', {'id': id});
    return result ?? false;
  }

  @override
  Future<String> toggleShuffle() async {
    final result = await _channel.invokeMethod<String>('toggleShuffle');
    return result ?? 'off';
  }

  @override
  Future<String> toggleRepeat() async {
    final result = await _channel.invokeMethod<String>('toggleRepeat');
    return result ?? 'none';
  }

  @override
  Future<String> getShuffleMode() async {
    final result = await _channel.invokeMethod<String>('getShuffleMode');
    return result ?? 'off';
  }

  @override
  Future<String> getRepeatMode() async {
    final result = await _channel.invokeMethod<String>('getRepeatMode');
    return result ?? 'none';
  }

  @override
  Future<List<Map<String, dynamic>>> getUserLibraryAlbums({int limit = 100}) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getUserLibraryAlbums',
      {'limit': limit},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<List<Map<String, dynamic>>> getUserLibrarySongs({int limit = 200}) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getUserLibrarySongs',
      {'limit': limit},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Future<List<Map<String, dynamic>>> getUserLibraryArtists({int limit = 100}) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getUserLibraryArtists',
      {'limit': limit},
    );
    return result
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
  }

  @override
  Stream<Map<String, dynamic>> get playbackStateStream =>
      _eventChannel.playbackStateStream;

  Map<String, dynamic> _deepConvertMap(Map<dynamic, dynamic> original) {
    return original.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepConvertMap(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((e) {
            if (e is Map) {
              return _deepConvertMap(e);
            }
            return e;
          }).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }
}
