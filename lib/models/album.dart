import 'package:freezed_annotation/freezed_annotation.dart';

part 'album.freezed.dart';
part 'album.g.dart';

@freezed
class Album with _$Album {
  const factory Album({
    required String id,
    required String title,
    @Default('') String artistName,
    String? artworkUrl,
    @Default(0) int trackCount,
    String? releaseDate,
    @Default([]) List<String> genreNames,
  }) = _Album;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
}
