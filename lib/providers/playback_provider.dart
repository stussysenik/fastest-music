import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playback_state.dart';
import 'authorization_provider.dart';

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final playerService = ref.watch(musicPlayerServiceProvider);
  return playerService.playbackStateStream;
});
