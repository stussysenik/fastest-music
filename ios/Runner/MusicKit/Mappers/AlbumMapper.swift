import Foundation
import MusicKit

struct AlbumMapper {
    static func toDict(_ album: Album) -> [String: Any?] {
        return [
            "id": album.id.rawValue,
            "title": album.title,
            "artistName": album.artistName,
            "artworkUrl": album.artwork?.url(width: 600, height: 600)?.absoluteString,
            "trackCount": album.trackCount,
            "releaseDate": album.releaseDate?.ISO8601Format(),
            "genreNames": album.genreNames,
        ]
    }

    static func toDictArray(_ albums: MusicItemCollection<Album>) -> [[String: Any?]] {
        return albums.map { toDict($0) }
    }
}
