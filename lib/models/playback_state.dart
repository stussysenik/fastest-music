import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_state.freezed.dart';
part 'playback_state.g.dart';

enum PlaybackStatus {
  playing,
  paused,
  stopped,
  interrupted,
  seekingForward,
  seekingBackward,
  unknown,
}

@freezed
class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    @Default(PlaybackStatus.stopped) PlaybackStatus status,
    @Default(0) double playbackTime,
    String? title,
    String? subtitle,
    String? artworkUrl,
    String? songId,
    @Default(0) double duration,
    String? artistName,
    String? albumTitle,
  }) = _PlaybackState;

  factory PlaybackState.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateFromJson(json);

  factory PlaybackState.fromPlatformMap(Map<String, dynamic> map) {
    return PlaybackState(
      status: _parseStatus(map['status'] as String? ?? 'stopped'),
      playbackTime: (map['playbackTime'] as num?)?.toDouble() ?? 0,
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      artworkUrl: map['artworkUrl'] as String?,
      songId: map['songId'] as String?,
      duration: (map['duration'] as num?)?.toDouble() ?? 0,
      artistName: map['artistName'] as String?,
      albumTitle: map['albumTitle'] as String?,
    );
  }
}

PlaybackStatus _parseStatus(String status) {
  switch (status) {
    case 'playing':
      return PlaybackStatus.playing;
    case 'paused':
      return PlaybackStatus.paused;
    case 'stopped':
      return PlaybackStatus.stopped;
    case 'interrupted':
      return PlaybackStatus.interrupted;
    case 'seekingForward':
      return PlaybackStatus.seekingForward;
    case 'seekingBackward':
      return PlaybackStatus.seekingBackward;
    default:
      return PlaybackStatus.unknown;
  }
}
