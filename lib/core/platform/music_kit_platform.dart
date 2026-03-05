abstract class MusicKitPlatform {
  Future<String> requestAuthorization();
  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 10});
  Future<Map<String, dynamic>> searchCatalog({
    required String term,
    List<String> types = const ['songs', 'albums', 'artists'],
  });
  Future<Map<String, dynamic>> getArtist(String id);
  Future<List<Map<String, dynamic>>> getArtistTopSongs(String id,
      {int limit = 10});
  Future<List<Map<String, dynamic>>> getArtistAlbums(String id);
  Future<Map<String, dynamic>> getAlbum(String id);
  Future<List<Map<String, dynamic>>> getAlbumTracks(String id);
  Future<bool> playSong(String id);
  Future<bool> playAlbum(String id);
  Future<bool> pause();
  Future<bool> resume();
  Future<bool> skipToNext();
  Future<bool> skipToPrevious();
  Future<bool> seekTo(double position);
  Stream<Map<String, dynamic>> get playbackStateStream;

  // Playlist operations
  Future<List<Map<String, dynamic>>> getUserPlaylists();
  Future<Map<String, dynamic>> createPlaylist(String name);
  Future<bool> addSongToPlaylist(String songId, String playlistId);
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId);
  Future<bool> playPlaylist(String id);

  // Shuffle & repeat
  Future<String> toggleShuffle();
  Future<String> toggleRepeat();
  Future<String> getShuffleMode();
  Future<String> getRepeatMode();

  // User library operations
  Future<List<Map<String, dynamic>>> getUserLibraryAlbums({int limit = 100});
  Future<List<Map<String, dynamic>>> getUserLibrarySongs({int limit = 200});
  Future<List<Map<String, dynamic>>> getUserLibraryArtists({int limit = 100});
}
