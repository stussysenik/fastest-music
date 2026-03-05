import Foundation
import MusicKit

struct PlaylistMapper {
    static func toDict(_ playlist: Playlist) -> [String: Any?] {
        return [
            "id": playlist.id.rawValue,
            "name": playlist.name,
            "artworkUrl": playlist.artwork?.url(width: 300, height: 300)?.absoluteString,
            "trackCount": playlist.tracks?.count ?? 0,
            "lastModifiedDate": playlist.lastModifiedDate?.description,
        ]
    }

    static func toDictArray(_ playlists: MusicItemCollection<Playlist>) -> [[String: Any?]] {
        return playlists.map { toDict($0) }
    }
}
