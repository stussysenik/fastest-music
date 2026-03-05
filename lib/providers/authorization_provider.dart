import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/platform/music_kit_method_channel.dart';
import '../core/platform/music_kit_platform.dart';
import '../services/music_kit_service.dart';
import '../services/music_player_service.dart';
import '../models/music_authorization_status.dart';

final musicKitPlatformProvider = Provider<MusicKitPlatform>((ref) {
  return MusicKitMethodChannel();
});

final musicKitServiceProvider = Provider<MusicKitService>((ref) {
  return MusicKitService(ref.watch(musicKitPlatformProvider));
});

final musicPlayerServiceProvider = Provider<MusicPlayerService>((ref) {
  return MusicPlayerService(ref.watch(musicKitPlatformProvider));
});

final authorizationProvider =
    AsyncNotifierProvider<AuthorizationNotifier, MusicAuthorizationStatus>(
        AuthorizationNotifier.new);

class AuthorizationNotifier
    extends AsyncNotifier<MusicAuthorizationStatus> {
  @override
  Future<MusicAuthorizationStatus> build() async {
    final service = ref.read(musicKitServiceProvider);
    try {
      return await service.requestAuthorization();
    } catch (_) {
      return MusicAuthorizationStatus.denied;
    }
  }
}
