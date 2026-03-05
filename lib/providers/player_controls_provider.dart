import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'authorization_provider.dart';

final playerControlsProvider =
    Provider<PlayerControls>((ref) {
  final playerService = ref.watch(musicPlayerServiceProvider);
  return PlayerControls(playerService);
});

class PlayerControls {
  final dynamic _playerService;

  PlayerControls(this._playerService);

  Future<bool> playSong(String id) => _playerService.playSong(id);
  Future<bool> playAlbum(String id) => _playerService.playAlbum(id);
  Future<bool> pause() => _playerService.pause();
  Future<bool> resume() => _playerService.resume();
  Future<bool> skipToNext() => _playerService.skipToNext();
  Future<bool> skipToPrevious() => _playerService.skipToPrevious();
  Future<bool> seekTo(double position) => _playerService.seekTo(position);
  Future<bool> playPlaylist(String id) => _playerService.playPlaylist(id);
  Future<String> toggleShuffle() => _playerService.toggleShuffle();
  Future<String> toggleRepeat() => _playerService.toggleRepeat();
  Future<String> getShuffleMode() => _playerService.getShuffleMode();
  Future<String> getRepeatMode() => _playerService.getRepeatMode();
}
