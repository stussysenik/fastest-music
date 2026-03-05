import '../core/platform/music_kit_platform.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/music_authorization_status.dart';

class MusicKitService {
  final MusicKitPlatform _platform;

  MusicKitService(this._platform);

  Future<MusicAuthorizationStatus> requestAuthorization() async {
    final result = await _platform.requestAuthorization();
    return MusicAuthorizationStatus.fromString(result);
  }

  Future<List<Song>> getRecentlyPlayed({int limit = 10}) async {
    final data = await _platform.getRecentlyPlayed(limit: limit);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  Future<({List<Song> songs, List<Album> albums, List<Artist> artists})>
      searchCatalog(String term) async {
    final data = await _platform.searchCatalog(term: term);
    final songs = (data['songs'] as List<dynamic>?)
            ?.map((e) => Song.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    final albums = (data['albums'] as List<dynamic>?)
            ?.map((e) => Album.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    final artists = (data['artists'] as List<dynamic>?)
            ?.map((e) => Artist.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return (songs: songs, albums: albums, artists: artists);
  }

  Future<Artist> getArtist(String id) async {
    final data = await _platform.getArtist(id);
    return Artist.fromJson(data);
  }

  Future<List<Song>> getArtistTopSongs(String id, {int limit = 10}) async {
    final data = await _platform.getArtistTopSongs(id, limit: limit);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Album>> getArtistAlbums(String id) async {
    final data = await _platform.getArtistAlbums(id);
    return data.map((e) => Album.fromJson(e)).toList();
  }

  Future<Album> getAlbum(String id) async {
    final data = await _platform.getAlbum(id);
    return Album.fromJson(data);
  }

  Future<List<Song>> getAlbumTracks(String id) async {
    final data = await _platform.getAlbumTracks(id);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Playlist>> getUserPlaylists() async {
    final data = await _platform.getUserPlaylists();
    return data.map((e) => Playlist.fromJson(e)).toList();
  }

  Future<Playlist> createPlaylist(String name) async {
    final data = await _platform.createPlaylist(name);
    return Playlist.fromJson(data);
  }

  Future<bool> addSongToPlaylist(String songId, String playlistId) async {
    return _platform.addSongToPlaylist(songId, playlistId);
  }

  Future<List<Song>> getPlaylistTracks(String playlistId) async {
    final data = await _platform.getPlaylistTracks(playlistId);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Album>> getUserLibraryAlbums({int limit = 100}) async {
    final data = await _platform.getUserLibraryAlbums(limit: limit);
    return data.map((e) => Album.fromJson(e)).toList();
  }

  Future<List<Song>> getUserLibrarySongs({int limit = 200}) async {
    final data = await _platform.getUserLibrarySongs(limit: limit);
    return data.map((e) => Song.fromJson(e)).toList();
  }

  Future<List<Artist>> getUserLibraryArtists({int limit = 100}) async {
    final data = await _platform.getUserLibraryArtists(limit: limit);
    return data.map((e) => Artist.fromJson(e)).toList();
  }
}
