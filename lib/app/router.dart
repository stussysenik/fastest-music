import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/last_listened/last_listened_screen.dart';
import '../screens/now_playing/now_playing_screen.dart';
import '../screens/browse/browse_screen.dart';
import '../screens/world_browse/world_browse_screen.dart';
import '../screens/playlist_library/playlist_library_screen.dart';
import '../screens/playlist_detail/playlist_detail_screen.dart';
import '../screens/artist_nationality/artist_nationality_screen.dart';
import '../screens/artist_detail/artist_detail_screen.dart';
import '../screens/album_detail/album_detail_screen.dart';
import '../screens/backend_artist_detail/backend_artist_detail_screen.dart';
import '../screens/decade_browse/decade_browse_screen.dart';
import '../screens/song_detail/song_detail_screen.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKeyA = GlobalKey<NavigatorState>(debugLabel: 'shellA');
final _shellNavigatorKeyB = GlobalKey<NavigatorState>(debugLabel: 'shellB');
final _shellNavigatorKeyC = GlobalKey<NavigatorState>(debugLabel: 'shellC');
final _shellNavigatorKeyD = GlobalKey<NavigatorState>(debugLabel: 'shellD');
final _shellNavigatorKeyE = GlobalKey<NavigatorState>(debugLabel: 'shellE');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/last-listened',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyA,
          routes: [
            GoRoute(
              path: '/last-listened',
              builder: (context, state) => const LastListenedScreen(),
              routes: [
                GoRoute(
                  path: 'nationalities',
                  builder: (context, state) =>
                      const ArtistNationalityScreen(),
                ),
                GoRoute(
                  path: 'decades',
                  builder: (context, state) =>
                      const DecadeBrowseScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyB,
          routes: [
            GoRoute(
              path: '/now-playing',
              builder: (context, state) => const NowPlayingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyC,
          routes: [
            GoRoute(
              path: '/browse',
              builder: (context, state) => const BrowseScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyD,
          routes: [
            GoRoute(
              path: '/world',
              builder: (context, state) => const WorldBrowseScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyE,
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const PlaylistLibraryScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/artist/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.uri.queryParameters['name'] ?? '';
        return ArtistDetailScreen(artistId: id, artistName: name);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/album/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final name = state.uri.queryParameters['name'] ?? '';
        return AlbumDetailScreen(albumId: id, albumName: name);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/backend-artist/:name',
      builder: (context, state) {
        final name = state.pathParameters['name']!;
        return BackendArtistDetailScreen(artistName: Uri.decodeComponent(name));
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/playlist/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final playlist = state.extra as Playlist?;
        return PlaylistDetailScreen(playlistId: id, playlist: playlist);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/song-detail',
      builder: (context, state) {
        final song = state.extra as Song;
        return SongDetailScreen(song: song);
      },
    ),
  ],
);
