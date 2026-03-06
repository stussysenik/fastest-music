import Foundation
import MusicKit

/// Protocol for MusicKit items that can be serialized to dictionaries
protocol MusicItemSerializable {
    func toDictionary() -> [String: Any?]
}

/// Generic mapper for MusicKit collections
struct MusicItemMapper {
    static func toDictArray<T: MusicItemSerializable>(_ items: MusicItemCollection<T>) -> [[String: Any?]] {
        items.map { $0.toDictionary() }
    }
}

// MARK: - MusicKit Type Extensions

extension Song: MusicItemSerializable {
    func toDictionary() -> [String: Any?] {
        [
            "id": id.rawValue,
            "title": title,
            "artistName": artistName,
            "albumTitle": albumTitle,
            "duration": duration ?? 0,
            "artworkUrl": artwork?.url(width: 600, height: 600)?.absoluteString,
            "trackNumber": trackNumber,
            "releaseDate": releaseDate?.description,
            "genreNames": genreNames,
        ]
    }
}

extension Album: MusicItemSerializable {
    func toDictionary() -> [String: Any?] {
        [
            "id": id.rawValue,
            "title": title,
            "artistName": artistName,
            "artworkUrl": artwork?.url(width: 600, height: 600)?.absoluteString,
            "trackCount": trackCount,
            "releaseDate": releaseDate?.ISO8601Format(),
            "genreNames": genreNames,
        ]
    }
}

extension Artist: MusicItemSerializable {
    func toDictionary() -> [String: Any?] {
        [
            "id": id.rawValue,
            "name": name,
            "artworkUrl": artwork?.url(width: 600, height: 600)?.absoluteString,
            "genreNames": genreNames,
        ]
    }
}

extension Track: MusicItemSerializable {
    func toDictionary() -> [String: Any?] {
        [
            "id": id.rawValue,
            "title": title,
            "artistName": artistName,
            "duration": duration ?? 0,
            "trackNumber": trackNumber,
        ]
    }
}
