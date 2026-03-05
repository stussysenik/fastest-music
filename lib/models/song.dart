import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';
part 'song.g.dart';

@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    @Default('') String artistName,
    @Default('') String albumTitle,
    @Default(0) double duration,
    String? artworkUrl,
    int? trackNumber,
    String? releaseDate,
    @Default([]) List<String> genreNames,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}
