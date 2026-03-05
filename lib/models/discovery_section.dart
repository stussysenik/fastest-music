import 'album.dart';

/// A themed section in the discovery feed.
///
/// ## Design (educational)
///
/// Each section groups albums by a musical theme (K-Pop, Afrobeats, etc.)
/// rather than raw country codes. This makes the feed feel curated rather
/// than a data dump. The optional `countryCode` lets us show flag emojis.
class DiscoverySection {
  final String title;
  final List<Album> albums;
  final String? countryCode;

  const DiscoverySection({
    required this.title,
    this.albums = const [],
    this.countryCode,
  });
}
