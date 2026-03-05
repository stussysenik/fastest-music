import Foundation
import MusicKit

struct ArtistMapper {
    static func toDict(_ artist: Artist) -> [String: Any?] {
        return [
            "id": artist.id.rawValue,
            "name": artist.name,
            "artworkUrl": artist.artwork?.url(width: 600, height: 600)?.absoluteString,
            "genreNames": artist.genreNames,
        ]
    }

    static func toDictArray(_ artists: MusicItemCollection<Artist>) -> [[String: Any?]] {
        return artists.map { toDict($0) }
    }
}
