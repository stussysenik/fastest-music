import 'package:flutter/services.dart';
import '../../core/constants/channel_constants.dart';

class MusicKitEventChannel {
  final EventChannel _eventChannel =
      const EventChannel(ChannelConstants.playbackStateEventChannel);

  Stream<Map<String, dynamic>>? _playbackStream;

  Stream<Map<String, dynamic>> get playbackStateStream {
    _playbackStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });
    return _playbackStream!;
  }
}
