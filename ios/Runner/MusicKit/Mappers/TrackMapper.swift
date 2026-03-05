import Foundation
import MusicKit

struct TrackMapper {
    static func toDict(_ track: Track) -> [String: Any?] {
        return [
            "id": track.id.rawValue,
            "title": track.title,
            "artistName": track.artistName,
            "duration": track.duration ?? 0,
            "artworkUrl": track.artwork?.url(width: 600, height: 600)?.absoluteString,
            "trackNumber": track.trackNumber,
            "albumTitle": track.albumTitle,
            "releaseDate": track.releaseDate?.description,
            "genreNames": track.genreNames,
        ]
    }

    static func toDictArray(_ tracks: MusicItemCollection<Track>) -> [[String: Any?]] {
        return tracks.map { toDict($0) }
    }
}
