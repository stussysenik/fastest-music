import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cache/local_cache_service.dart';

/// Global provider for the local cache service.
///
/// ## Why a Provider and not a StateProvider? (educational)
///
/// LocalCacheService is initialized once at startup and never changes.
/// A plain Provider is ideal for singleton services — Riverpod will
/// lazily create it and keep it alive for the app's lifetime.
/// The service is overridden in ProviderScope after Hive.init() completes.
final localCacheProvider = Provider<LocalCacheService>((ref) {
  // This will be overridden in main.dart after initialization.
  // Throwing here ensures we catch misconfiguration early.
  throw UnimplementedError(
    'LocalCacheService must be initialized before use. '
    'Override this provider in ProviderScope.',
  );
});
