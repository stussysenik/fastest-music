import '../core/platform/music_kit_platform.dart';
import '../models/playback_state.dart';

class MusicPlayerService {
  final MusicKitPlatform _platform;

  MusicPlayerService(this._platform);

  Future<bool> playSong(String id) => _platform.playSong(id);
  Future<bool> playAlbum(String id) => _platform.playAlbum(id);
  Future<bool> pause() => _platform.pause();
  Future<bool> resume() => _platform.resume();
  Future<bool> skipToNext() => _platform.skipToNext();
  Future<bool> skipToPrevious() => _platform.skipToPrevious();
  Future<bool> seekTo(double position) => _platform.seekTo(position);
  Future<bool> playPlaylist(String id) => _platform.playPlaylist(id);
  Future<String> toggleShuffle() => _platform.toggleShuffle();
  Future<String> toggleRepeat() => _platform.toggleRepeat();
  Future<String> getShuffleMode() => _platform.getShuffleMode();
  Future<String> getRepeatMode() => _platform.getRepeatMode();

  Stream<PlaybackState> get playbackStateStream =>
      _platform.playbackStateStream.map((map) {
        return PlaybackState.fromPlatformMap(map);
      });
}
