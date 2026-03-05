import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/music_authorization_status.dart';
import 'authorization_provider.dart';

/// MusicKit availability states.
///
/// ## Why a separate provider? (educational)
///
/// The authorization provider throws on failure (MusicKit entitlement missing,
/// simulator, etc). This provider wraps that and exposes a simple tri-state:
/// - `available` — MusicKit authorized, playback and recently-played work
/// - `unavailable` — auth failed or denied, app works in browse-only mode
/// - `checking` — still attempting authorization
///
/// This lets the UI render immediately without blocking on MusicKit.
enum MusicKitAvailability { checking, available, unavailable }

final musicKitAvailabilityProvider = Provider<MusicKitAvailability>((ref) {
  final authAsync = ref.watch(authorizationProvider);

  return authAsync.when(
    data: (status) {
      if (status == MusicAuthorizationStatus.authorized) {
        return MusicKitAvailability.available;
      }
      return MusicKitAvailability.unavailable;
    },
    loading: () => MusicKitAvailability.checking,
    error: (_, __) => MusicKitAvailability.unavailable,
  );
});
