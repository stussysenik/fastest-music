import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/playlist_provider.dart';
import '../providers/authorization_provider.dart';
import '../shared_widgets/artwork_image.dart';
import '../shared_widgets/loading_indicator.dart';

/// Bottom sheet for adding a song to a user playlist.
///
/// ## UX pattern (educational)
///
/// A modal bottom sheet is the standard iOS/Android pattern for "add to"
/// actions. It slides up from the bottom, shows the list of playlists,
/// and a "New Playlist" option at the top. After selection, a snackbar
/// confirms the action with the playlist name — matching Apple Music's
/// behavior exactly.
class AddToPlaylistSheet extends ConsumerStatefulWidget {
  final String songId;
  final String songTitle;

  const AddToPlaylistSheet({
    super.key,
    required this.songId,
    required this.songTitle,
  });

  @override
  ConsumerState<AddToPlaylistSheet> createState() =>
      _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add to Playlist',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // New playlist option
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF5F5F5),
                child: Icon(Icons.add, color: Colors.black),
              ),
              title: const Text('New Playlist'),
              onTap: _isAdding ? null : () => _createNewPlaylist(context),
            ),
            const Divider(height: 1),
            // Playlists list
            Expanded(
              child: playlistsAsync.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return const Center(
                      child: Text(
                        'No playlists yet.\nCreate one above!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        leading: ArtworkImage(
                          url: playlist.artworkUrl,
                          size: 44,
                          borderRadius: 6,
                          placeholderIcon: Icons.queue_music,
                          imageSize: ArtworkImageSize.thumbnail,
                        ),
                        title: Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${playlist.trackCount} tracks',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                        trailing: _isAdding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline,
                                color: Color(0xFF999999)),
                        onTap: _isAdding
                            ? null
                            : () =>
                                _addToPlaylist(context, playlist.id, playlist.name),
                      );
                    },
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (e, _) => Center(
                  child: Text('Failed to load playlists: $e'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToPlaylist(
      BuildContext context, String playlistId, String playlistName) async {
    setState(() => _isAdding = true);
    try {
      final service = ref.read(musicKitServiceProvider);
      final success =
          await service.addSongToPlaylist(widget.songId, playlistId);
      if (!mounted) return;

      // Invalidate caches so the playlist grid and track list stay fresh
      ref.invalidate(userPlaylistsProvider);
      ref.invalidate(playlistTracksProvider(playlistId));

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Added "${widget.songTitle}" to $playlistName'
                : 'Failed to add to playlist',
          ),
          duration: const Duration(seconds: 3),
          action: success
              ? SnackBarAction(
                  label: 'View',
                  onPressed: () => context.push('/playlist/$playlistId'),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _createNewPlaylist(BuildContext context) async {
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
    if (!mounted) return;

    setState(() => _isAdding = true);
    try {
      final service = ref.read(musicKitServiceProvider);
      final playlist = await service.createPlaylist(name.trim());

      // Add the song to the new playlist
      await service.addSongToPlaylist(widget.songId, playlist.id);

      // Refresh playlists and the new playlist's track cache
      ref.invalidate(userPlaylistsProvider);
      ref.invalidate(playlistTracksProvider(playlist.id));

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Created "$name" and added "${widget.songTitle}"'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => context.push('/playlist/${playlist.id}'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Shows the add-to-playlist bottom sheet.
void showAddToPlaylistSheet(
    BuildContext context, String songId, String songTitle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => AddToPlaylistSheet(
      songId: songId,
      songTitle: songTitle,
    ),
  );
}
