import Foundation
import MusicKit

struct SongMapper {
    static func toDict(_ song: Song) -> [String: Any?] {
        return [
            "id": song.id.rawValue,
            "title": song.title,
            "artistName": song.artistName,
            "albumTitle": song.albumTitle,
            "duration": song.duration ?? 0,
            "artworkUrl": song.artwork?.url(width: 600, height: 600)?.absoluteString,
            "trackNumber": song.trackNumber,
            "releaseDate": song.releaseDate?.description,
            "genreNames": song.genreNames,
        ]
    }

    static func toDictArray(_ songs: MusicItemCollection<Song>) -> [[String: Any?]] {
        return songs.map { toDict($0) }
    }
}
