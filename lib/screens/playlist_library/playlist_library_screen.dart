import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/authorization_provider.dart';
import '../../providers/music_kit_availability_provider.dart';
import '../../providers/user_library_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/error_view.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/alphabet_index.dart';

/// "My Music" library screen with segmented tabs and A-Z scrolling index.
///
/// ## Segmented control pattern (educational)
///
/// Flutter's `SegmentedButton` (Material 3) gives us a native-feeling
/// tab switcher without the overhead of a full `TabBar` + `TabBarView`.
/// We pair it with `IndexedStack` to preserve scroll state across tabs —
/// when you switch from Albums to Songs and back, your scroll position
/// is remembered.
///
/// ## A-Z index (educational)
///
/// The right-edge letter index (like iOS Contacts) uses a `ScrollController`
/// with `jumpTo` to seek to section header positions. Items are grouped by
/// their first letter, with section headers rendered inline in the list.
class PlaylistLibraryScreen extends ConsumerStatefulWidget {
  const PlaylistLibraryScreen({super.key});

  @override
  ConsumerState<PlaylistLibraryScreen> createState() =>
      _PlaylistLibraryScreenState();
}

enum _LibraryTab { albums, artists, songs, playlists }

class _PlaylistLibraryScreenState extends ConsumerState<PlaylistLibraryScreen> {
  _LibraryTab _selectedTab = _LibraryTab.albums;

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(musicKitAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Music'),
        actions: [
          if (availability == MusicKitAvailability.available)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _createPlaylist(context, ref),
            ),
        ],
      ),
      body: availability == MusicKitAvailability.checking
          ? const Center(child: LoadingIndicator())
          : availability == MusicKitAvailability.unavailable
              ? _buildUnavailable()
              : _buildLibrary(),
    );
  }

  Widget _buildUnavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music,
                size: 64, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            const Text(
              'Connect Apple Music\nto see your library',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(authorizationProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Request Access',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrary() {
    return Column(
      children: [
        // Segmented control
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_LibraryTab>(
              segments: const [
                ButtonSegment(
                    value: _LibraryTab.albums,
                    label: Text('Albums', style: TextStyle(fontSize: 13))),
                ButtonSegment(
                    value: _LibraryTab.artists,
                    label: Text('Artists', style: TextStyle(fontSize: 13))),
                ButtonSegment(
                    value: _LibraryTab.songs,
                    label: Text('Songs', style: TextStyle(fontSize: 13))),
                ButtonSegment(
                    value: _LibraryTab.playlists,
                    label: Text('Playlists', style: TextStyle(fontSize: 13))),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (tabs) {
                setState(() => _selectedTab = tabs.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),

        // Tab content
        Expanded(
          child: IndexedStack(
            index: _selectedTab.index,
            children: const [
              _AlbumsTab(),
              _ArtistsTab(),
              _SongsTab(),
              _PlaylistsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Playlist name'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final service = ref.read(musicKitServiceProvider);
      await service.createPlaylist(name.trim());
      ref.invalidate(userPlaylistsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "$name"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating playlist: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Albums Tab — grid with A-Z index
// ---------------------------------------------------------------------------

class _AlbumsTab extends ConsumerStatefulWidget {
  const _AlbumsTab();

  @override
  ConsumerState<_AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends ConsumerState<_AlbumsTab> {
  final ScrollController _scrollController = ScrollController();
  String? _activeLetter;
  final Map<String, double> _sectionOffsets = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, List<Album>> _groupByLetter(List<Album> albums) {
    final grouped = <String, List<Album>>{};
    for (final album in albums) {
      final letter = album.title.isNotEmpty
          ? album.title[0].toUpperCase()
          : '#';
      final key = RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
      grouped.putIfAbsent(key, () => []).add(album);
    }
    // Sort keys alphabetically, '#' at end
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(userLibraryAlbumsProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(
            child: Text('No albums in your library',
                style: TextStyle(color: Color(0xFF999999))),
          );
        }

        final grouped = _groupByLetter(albums);
        final availableLetters = grouped.keys.toList();

        // Build flat list of items: section headers + album pairs (for grid rows)
        final items = <_ListItem>[];
        for (final entry in grouped.entries) {
          items.add(_ListItem.header(entry.key));
          // Add albums in pairs for 2-column grid
          for (var i = 0; i < entry.value.length; i += 2) {
            items.add(_ListItem.albumRow(
              entry.value[i],
              i + 1 < entry.value.length ? entry.value[i + 1] : null,
            ));
          }
        }

        // Calculate section offsets for A-Z jumping
        double offset = 0;
        _sectionOffsets.clear();
        for (final item in items) {
          if (item.isHeader) {
            _sectionOffsets[item.letter!] = offset;
            offset += 36; // header height
          } else {
            offset += 200; // album row height
          }
        }

        return Row(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userLibraryAlbumsProvider);
                  await ref.read(userLibraryAlbumsProvider.future);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.isHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          item.letter!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                              child: _AlbumCard(album: item.album1!)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: item.album2 != null
                                ? _AlbumCard(album: item.album2!)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // A-Z sidebar
            AlphabetIndex(
              activeLetter: _activeLetter,
              availableLetters: availableLetters,
              onLetterSelected: (letter) {
                setState(() => _activeLetter = letter);
                final offset = _sectionOffsets[letter];
                if (offset != null) {
                  _scrollController.animateTo(
                    offset,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/album/${album.id}?name=${Uri.encodeComponent(album.title)}',
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ArtworkImage(
                url: album.artworkUrl,
                size: double.infinity,
                borderRadius: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              album.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Artists Tab — list with circular artwork and A-Z index
// ---------------------------------------------------------------------------

class _ArtistsTab extends ConsumerStatefulWidget {
  const _ArtistsTab();

  @override
  ConsumerState<_ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends ConsumerState<_ArtistsTab> {
  final ScrollController _scrollController = ScrollController();
  String? _activeLetter;
  final Map<String, double> _sectionOffsets = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, List<Artist>> _groupByLetter(List<Artist> artists) {
    final grouped = <String, List<Artist>>{};
    for (final artist in artists) {
      final letter = artist.name.isNotEmpty
          ? artist.name[0].toUpperCase()
          : '#';
      final key = RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
      grouped.putIfAbsent(key, () => []).add(artist);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(userLibraryArtistsProvider);

    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) {
          return const Center(
            child: Text('No artists in your library',
                style: TextStyle(color: Color(0xFF999999))),
          );
        }

        final grouped = _groupByLetter(artists);
        final availableLetters = grouped.keys.toList();

        // Flat list: headers + individual artists
        final items = <_ArtistListItem>[];
        for (final entry in grouped.entries) {
          items.add(_ArtistListItem.header(entry.key));
          for (final artist in entry.value) {
            items.add(_ArtistListItem.artist(artist));
          }
        }

        // Calculate offsets
        double offset = 0;
        _sectionOffsets.clear();
        for (final item in items) {
          if (item.isHeader) {
            _sectionOffsets[item.letter!] = offset;
            offset += 36;
          } else {
            offset += 64;
          }
        }

        return Row(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userLibraryArtistsProvider);
                  await ref.read(userLibraryArtistsProvider.future);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.isHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          item.letter!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      );
                    }
                    final artist = item.artist!;
                    return ListTile(
                      leading: ArtworkImage(
                        url: artist.artworkUrl,
                        size: 44,
                        borderRadius: 22,
                        placeholderIcon: Icons.person,
                      ),
                      title: Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: artist.genreNames.isNotEmpty
                          ? Text(
                              artist.genreNames.first,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF999999)),
                            )
                          : null,
                      onTap: () => context.push(
                        '/artist/${artist.id}?name=${Uri.encodeComponent(artist.name)}',
                      ),
                    );
                  },
                ),
              ),
            ),
            AlphabetIndex(
              activeLetter: _activeLetter,
              availableLetters: availableLetters,
              onLetterSelected: (letter) {
                setState(() => _activeLetter = letter);
                final offset = _sectionOffsets[letter];
                if (offset != null) {
                  _scrollController.animateTo(
                    offset,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}

// ---------------------------------------------------------------------------
// Songs Tab — list with A-Z index
// ---------------------------------------------------------------------------

class _SongsTab extends ConsumerStatefulWidget {
  const _SongsTab();

  @override
  ConsumerState<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<_SongsTab> {
  final ScrollController _scrollController = ScrollController();
  String? _activeLetter;
  final Map<String, double> _sectionOffsets = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, List<Song>> _groupByLetter(List<Song> songs) {
    final grouped = <String, List<Song>>{};
    for (final song in songs) {
      final letter = song.title.isNotEmpty
          ? song.title[0].toUpperCase()
          : '#';
      final key = RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
      grouped.putIfAbsent(key, () => []).add(song);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(userLibrarySongsProvider);

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text('No songs in your library',
                style: TextStyle(color: Color(0xFF999999))),
          );
        }

        final grouped = _groupByLetter(songs);
        final availableLetters = grouped.keys.toList();

        final items = <_SongListItem>[];
        for (final entry in grouped.entries) {
          items.add(_SongListItem.header(entry.key));
          for (final song in entry.value) {
            items.add(_SongListItem.song(song));
          }
        }

        // Calculate offsets (header 36px, song tile ~72px)
        double offset = 0;
        _sectionOffsets.clear();
        for (final item in items) {
          if (item.isHeader) {
            _sectionOffsets[item.letter!] = offset;
            offset += 36;
          } else {
            offset += 72;
          }
        }

        return Row(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userLibrarySongsProvider);
                  await ref.read(userLibrarySongsProvider.future);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.isHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          item.letter!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      );
                    }
                    return SongTile(song: item.song!);
                  },
                ),
              ),
            ),
            AlphabetIndex(
              activeLetter: _activeLetter,
              availableLetters: availableLetters,
              onLetterSelected: (letter) {
                setState(() => _activeLetter = letter);
                final offset = _sectionOffsets[letter];
                if (offset != null) {
                  _scrollController.animateTo(
                    offset,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}

// ---------------------------------------------------------------------------
// Playlists Tab — preserved from original grid
// ---------------------------------------------------------------------------

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userPlaylistsProvider);
        await ref.read(userPlaylistsProvider.future);
      },
      child: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                const Icon(Icons.queue_music,
                    size: 64, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                const Text(
                  'No playlists yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to create your first playlist',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
              ],
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _PlaylistCard(playlist: playlist);
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ErrorView(message: e.toString()),
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/playlist/${playlist.id}', extra: playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ArtworkImage(
              url: playlist.artworkUrl,
              size: double.infinity,
              borderRadius: 10,
              placeholderIcon: Icons.queue_music,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            '${playlist.trackCount} tracks',
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List item helpers for building mixed header/content lists
// ---------------------------------------------------------------------------

class _ListItem {
  final String? letter;
  final Album? album1;
  final Album? album2;
  bool get isHeader => letter != null && album1 == null;

  const _ListItem._({this.letter, this.album1, this.album2});

  factory _ListItem.header(String letter) =>
      _ListItem._(letter: letter);

  factory _ListItem.albumRow(Album a1, Album? a2) =>
      _ListItem._(album1: a1, album2: a2);
}

class _ArtistListItem {
  final String? letter;
  final Artist? artist;
  bool get isHeader => letter != null && artist == null;

  const _ArtistListItem._({this.letter, this.artist});

  factory _ArtistListItem.header(String letter) =>
      _ArtistListItem._(letter: letter);

  factory _ArtistListItem.artist(Artist artist) =>
      _ArtistListItem._(artist: artist);
}

class _SongListItem {
  final String? letter;
  final Song? song;
  bool get isHeader => letter != null && song == null;

  const _SongListItem._({this.letter, this.song});

  factory _SongListItem.header(String letter) =>
      _SongListItem._(letter: letter);

  factory _SongListItem.song(Song song) =>
      _SongListItem._(song: song);
}
