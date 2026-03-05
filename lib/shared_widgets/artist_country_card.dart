import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/artist_artwork_provider.dart';
import 'artwork_image.dart';

/// Circular artist card with artwork resolved from the backend.
///
/// ## Design pattern (educational)
///
/// This card uses a `Consumer` to watch the `artistArtworkProvider`,
/// which lazily resolves artwork on first render. The FutureProvider.family
/// caches the result, so scrolling back to a previously-viewed card
/// shows the artwork instantly without re-fetching.
class ArtistCountryCard extends ConsumerWidget {
  final String artistName;
  final VoidCallback? onTap;

  const ArtistCountryCard({
    super.key,
    required this.artistName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworkAsync = ref.watch(artistArtworkProvider(artistName));

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            artworkAsync.when(
              data: (url) => ArtworkImage(
                url: url,
                size: 72,
                borderRadius: 36,
                placeholderIcon: Icons.person,
              ),
              loading: () => const ArtworkImage(
                size: 72,
                borderRadius: 36,
                placeholderIcon: Icons.person,
              ),
              error: (_, __) => const ArtworkImage(
                size: 72,
                borderRadius: 36,
                placeholderIcon: Icons.person,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              artistName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
