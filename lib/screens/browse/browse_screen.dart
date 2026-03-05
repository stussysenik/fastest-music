import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/search_provider.dart';
import '../../shared_widgets/artwork_image.dart';
import '../../shared_widgets/stacked_artwork_preview.dart';
import '../../shared_widgets/song_tile.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../../shared_widgets/empty_state.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = query;
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final genre = ref.read(searchGenreFilterProvider);
    final yearFrom = ref.read(searchYearFromFilterProvider);
    final yearTo = ref.read(searchYearToFilterProvider);
    ref.read(searchResultsProvider.notifier).search(
      query,
      genre: genre,
      yearFrom: yearFrom,
      yearTo: yearTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _hasActiveFilters() ? Colors.blue : null,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search Apple Music...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Genre & year filter controls
          if (_showFilters) _buildFilterBar(),
          Expanded(
            child: searchResults.when(
              data: (result) {
                if (result.songs.isEmpty &&
                    result.albums.isEmpty &&
                    result.artists.isEmpty) {
                  final query = ref.read(searchQueryProvider);
                  if (query.isEmpty) {
                    return const EmptyState(
                      message: 'Search for songs, albums, and artists',
                      icon: Icons.search,
                    );
                  }
                  return const EmptyState(
                    message: 'No results found',
                    icon: Icons.search_off,
                  );
                }
                return _buildResults(context, result);
              },
              loading: () => const LoadingIndicator(),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return ref.read(searchGenreFilterProvider) != null ||
        ref.read(searchYearFromFilterProvider) != null ||
        ref.read(searchYearToFilterProvider) != null;
  }

  Widget _buildFilterBar() {
    final selectedGenre = ref.watch(searchGenreFilterProvider);
    final yearFrom = ref.watch(searchYearFromFilterProvider);
    final yearTo = ref.watch(searchYearToFilterProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final genre in ['Rock', 'Pop', 'Hip-Hop', 'Electronic', 'Jazz', 'Classical', 'R&B', 'Metal'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(genre),
                      selected: selectedGenre == genre,
                      onSelected: (selected) {
                        ref.read(searchGenreFilterProvider.notifier).state =
                            selected ? genre : null;
                        final query = ref.read(searchQueryProvider);
                        if (query.isNotEmpty) _performSearch(query);
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Year range
          Row(
            children: [
              const Text('Year: ', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
              SizedBox(
                width: 70,
                height: 36,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: yearFrom?.toString() ?? 'From',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    ref.read(searchYearFromFilterProvider.notifier).state =
                        v.isEmpty ? null : int.tryParse(v);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('–', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(
                width: 70,
                height: 36,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: yearTo?.toString() ?? 'To',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    ref.read(searchYearToFilterProvider.notifier).state =
                        v.isEmpty ? null : int.tryParse(v);
                  },
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton(
                  onPressed: () {
                    ref.read(searchGenreFilterProvider.notifier).state = null;
                    ref.read(searchYearFromFilterProvider.notifier).state = null;
                    ref.read(searchYearToFilterProvider.notifier).state = null;
                    final query = ref.read(searchQueryProvider);
                    if (query.isNotEmpty) _performSearch(query);
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchResult result) {
    // Collect artwork URLs for the stacked preview hero
    final artworkUrls = result.albums
        .where((a) => a.artworkUrl != null && a.artworkUrl!.isNotEmpty)
        .take(5)
        .map((a) => a.artworkUrl!)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Stacked artwork preview header
        if (artworkUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Center(
              child: StackedArtworkPreview(
                artworkUrls: artworkUrls,
                cardSize: 100,
              ),
            ),
          ),
        // Artists
        if (result.artists.isNotEmpty) ...[
          _sectionHeader('Artists'),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: result.artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final artist = result.artists[index];
                return GestureDetector(
                  onTap: () => context.push(
                    '/artist/${artist.id}?name=${Uri.encodeComponent(artist.name)}',
                  ),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        ArtworkImage(
                          url: artist.artworkUrl,
                          size: 72,
                          borderRadius: 36,
                          placeholderIcon: Icons.person,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Albums
        if (result.albums.isNotEmpty) ...[
          _sectionHeader('Albums'),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: result.albums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final album = result.albums[index];
                return GestureDetector(
                  onTap: () => context.push(
                    '/album/${album.id}?name=${Uri.encodeComponent(album.title)}',
                  ),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ArtworkImage(
                              url: album.artworkUrl,
                              size: 140,
                              borderRadius: 10,
                            ),
                            if (album.releaseDate != null &&
                                album.releaseDate!.length >= 4)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    album.releaseDate!.substring(0, 4),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          album.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                album.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ),
                            if (album.trackCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  '${album.trackCount} trks',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFBBBBBB),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Songs
        if (result.songs.isNotEmpty) ...[
          _sectionHeader('Songs'),
          ...result.songs.map((song) => SongTile(song: song)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
