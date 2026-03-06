import 'package:flutter/material.dart';
import 'alphabet_index_view.dart';

/// Example usage of AlphabetIndexView with an album library
class AlbumLibraryWithIndex extends StatefulWidget {
  const AlbumLibraryWithIndex({super.key});

  @override
  State<AlbumLibraryWithIndex> createState() => _AlbumLibraryWithIndexState();
}

class _AlbumLibraryWithIndexState extends State<AlbumLibraryWithIndex> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AlphabetIndexViewState> _indexKey = GlobalKey();
  
  // Example album data grouped by first letter
  final Map<String, List<Album>> _albumsByLetter = {};
  List<String> _availableLetters = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    // This would normally call your MusicKit plugin
    // For example: await MusicKitService.getUserLibraryAlbums()
    
    // Mock data for demonstration
    final albums = [
      Album(id: '1', title: 'Abbey Road', artistName: 'The Beatles', artworkUrl: null),
      Album(id: '2', title: 'Back in Black', artistName: 'AC/DC', artworkUrl: null),
      Album(id: '3', title: 'Thriller', artistName: 'Michael Jackson', artworkUrl: null),
      // ... more albums
    ];

    // Group albums by first letter
    final grouped = <String, List<Album>>{};
    for (final album in albums) {
      final firstChar = album.title.isNotEmpty 
          ? album.title[0].toUpperCase() 
          : '#';
      final letter = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';
      grouped.putIfAbsent(letter, () => []).add(album);
    }

    setState(() {
      _albumsByLetter.clear();
      _albumsByLetter.addAll(grouped);
      _availableLetters = grouped.keys.toList()..sort();
    });
  }

  void _scrollToLetter(String letter) {
    // Calculate the position to scroll to based on letter
    int itemIndex = 0;
    for (final l in _availableLetters) {
      if (l == letter) break;
      itemIndex += (_albumsByLetter[l]?.length ?? 0) + 1; // +1 for header
    }

    if (_scrollController.hasClients && itemIndex >= 0) {
      final position = itemIndex * 80.0; // Approximate item height
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
      ),
      body: Stack(
        children: [
          // Main album list
          ListView.builder(
            controller: _scrollController,
            itemCount: _getTotalItemCount(),
            itemBuilder: (context, index) {
              final item = _getItemAt(index);
              if (item is String) {
                // Section header
                return _buildSectionHeader(item);
              } else if (item is Album) {
                // Album item
                return _buildAlbumTile(item);
              }
              return const SizedBox.shrink();
            },
          ),
          // Alphabet index overlay
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 30,
              child: AlphabetIndexView(
                key: _indexKey,
                letters: _availableLetters.isNotEmpty ? _availableLetters : null,
                onLetterChanged: _scrollToLetter,
                onLetterSelected: (letter) {
                  // Optionally provide haptic feedback or other actions
                  debugPrint('Selected letter: $letter');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalItemCount() {
    int count = 0;
    for (final letter in _availableLetters) {
      count += 1 + (_albumsByLetter[letter]?.length ?? 0); // Header + albums
    }
    return count;
  }

  dynamic _getItemAt(int index) {
    int currentIndex = 0;
    for (final letter in _availableLetters) {
      if (currentIndex == index) return letter; // Section header
      currentIndex++;
      
      final albums = _albumsByLetter[letter] ?? [];
      for (final album in albums) {
        if (currentIndex == index) return album;
        currentIndex++;
      }
    }
    return null;
  }

  Widget _buildSectionHeader(String letter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAlbumTile(Album album) {
    return ListTile(
      leading: album.artworkUrl != null
          ? Image.network(
              album.artworkUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.album, size: 50),
            )
          : const Icon(Icons.album, size: 50),
      title: Text(album.title),
      subtitle: Text(album.artistName),
      onTap: () {
        // Handle album tap - play album, show details, etc.
        debugPrint('Tapped album: ${album.title}');
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class Album {
  final String id;
  final String title;
  final String artistName;
  final String? artworkUrl;

  Album({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
  });
}
