import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/artist.dart';
import 'authorization_provider.dart';

/// Providers for the user's personal Apple Music library.
///
/// ## MusicLibraryRequest vs MusicCatalogResourceRequest (educational)
///
/// MusicKit distinguishes between the **catalog** (all of Apple Music)
/// and the **library** (user's personal collection). These providers use
/// `getUserLibrary*` methods which map to `MusicLibraryRequest<T>()` on
/// the native side — fetching only what the user has added to their library.
///
/// These are FutureProviders with `.family` omitted since they don't need
/// parameters — the user's library is a single, global dataset.

final userLibraryAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getUserLibraryAlbums();
});

final userLibrarySongsProvider = FutureProvider<List<Song>>((ref) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getUserLibrarySongs();
});

final userLibraryArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final service = ref.watch(musicKitServiceProvider);
  return service.getUserLibraryArtists();
});
