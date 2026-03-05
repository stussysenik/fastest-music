import Foundation
import MusicKit

class MusicKitService {
    static let shared = MusicKitService()

    func requestAuthorization() async -> String {
        let status = await MusicAuthorization.request()
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }

    func getRecentlyPlayed(limit: Int) async throws -> [[String: Any?]] {
        var request = MusicRecentlyPlayedRequest<Song>()
        request.limit = limit
        let response = try await request.response()
        return SongMapper.toDictArray(response.items)
    }

    func searchCatalog(term: String, types: [String]) async throws -> [String: Any] {
        var request = MusicCatalogSearchRequest(term: term, types: [Song.self, Album.self, Artist.self])
        request.limit = 25
        let response = try await request.response()

        var result: [String: Any] = [:]
        result["songs"] = SongMapper.toDictArray(response.songs)
        result["albums"] = AlbumMapper.toDictArray(response.albums)
        result["artists"] = ArtistMapper.toDictArray(response.artists)
        return result
    }

    func getArtist(id: String) async throws -> [String: Any?] {
        let musicItemID = MusicItemID(id)
        let request = MusicCatalogResourceRequest<Artist>(matching: \.id, equalTo: musicItemID)
        let response = try await request.response()
        guard let artist = response.items.first else {
            throw MusicKitServiceError.notFound
        }
        return ArtistMapper.toDict(artist)
    }

    func getArtistTopSongs(id: String, limit: Int) async throws -> [[String: Any?]] {
        let musicItemID = MusicItemID(id)
        var request = MusicCatalogResourceRequest<Artist>(matching: \.id, equalTo: musicItemID)
        request.properties = [.topSongs]
        let response = try await request.response()
        guard let artist = response.items.first, let topSongs = artist.topSongs else {
            return []
        }
        let limited = MusicItemCollection(Array(topSongs.prefix(limit)))
        return SongMapper.toDictArray(limited)
    }

    func getArtistAlbums(id: String) async throws -> [[String: Any?]] {
        let musicItemID = MusicItemID(id)
        var request = MusicCatalogResourceRequest<Artist>(matching: \.id, equalTo: musicItemID)
        request.properties = [.albums]
        let response = try await request.response()
        guard let artist = response.items.first, let albums = artist.albums else {
            return []
        }
        return AlbumMapper.toDictArray(albums)
    }

    func getAlbum(id: String) async throws -> [String: Any?] {
        let musicItemID = MusicItemID(id)
        let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: musicItemID)
        let response = try await request.response()
        guard let album = response.items.first else {
            throw MusicKitServiceError.notFound
        }
        return AlbumMapper.toDict(album)
    }

    func getAlbumTracks(id: String) async throws -> [[String: Any?]] {
        let musicItemID = MusicItemID(id)
        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: musicItemID)
        request.properties = [.tracks]
        let response = try await request.response()
        guard let album = response.items.first, let tracks = album.tracks else {
            return []
        }
        return TrackMapper.toDictArray(tracks)
    }

    // MARK: - User Library

    func getUserLibraryAlbums(limit: Int) async throws -> [[String: Any?]] {
        var request = MusicLibraryRequest<Album>()
        request.limit = limit
        let response = try await request.response()
        return response.items.map { album in
            return [
                "id": album.id.rawValue,
                "title": album.title,
                "artistName": album.artistName,
                "artworkUrl": album.artwork?.url(width: 600, height: 600)?.absoluteString,
                "trackCount": album.trackCount,
                "releaseDate": album.releaseDate?.ISO8601Format(),
                "genreNames": album.genreNames,
            ] as [String: Any?]
        }
    }

    func getUserLibrarySongs(limit: Int) async throws -> [[String: Any?]] {
        var request = MusicLibraryRequest<Song>()
        request.limit = limit
        let response = try await request.response()
        return response.items.map { song in
            return [
                "id": song.id.rawValue,
                "title": song.title,
                "artistName": song.artistName,
                "albumTitle": song.albumTitle,
                "duration": song.duration ?? 0,
                "artworkUrl": song.artwork?.url(width: 600, height: 600)?.absoluteString,
                "trackNumber": song.trackNumber,
                "genreNames": song.genreNames,
            ] as [String: Any?]
        }
    }

    func getUserLibraryArtists(limit: Int) async throws -> [[String: Any?]] {
        var request = MusicLibraryRequest<Artist>()
        request.limit = limit
        let response = try await request.response()
        return response.items.map { artist in
            return [
                "id": artist.id.rawValue,
                "name": artist.name,
                "artworkUrl": artist.artwork?.url(width: 600, height: 600)?.absoluteString,
                "genreNames": artist.genreNames,
            ] as [String: Any?]
        }
    }
}

enum MusicKitServiceError: Error {
    case notFound
}
