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
        return MusicItemMapper.toDictArray(response.items)
    }

    func searchCatalog(term: String, types: [String]) async throws -> [String: Any] {
        var request = MusicCatalogSearchRequest(term: term, types: [Song.self, Album.self, Artist.self])
        request.limit = 25
        let response = try await request.response()

        return [
            "songs": MusicItemMapper.toDictArray(response.songs),
            "albums": MusicItemMapper.toDictArray(response.albums),
            "artists": MusicItemMapper.toDictArray(response.artists),
        ]
    }

    func getArtist(id: String) async throws -> [String: Any?] {
        let musicItemID = MusicItemID(id)
        let request = MusicCatalogResourceRequest<Artist>(matching: \.id, equalTo: musicItemID)
        let response = try await request.response()
        guard let artist = response.items.first else {
            throw MusicKitServiceError.notFound
        }
        return artist.toDictionary()
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
        return MusicItemMapper.toDictArray(limited)
    }

    func getArtistAlbums(id: String) async throws -> [[String: Any?]] {
        let musicItemID = MusicItemID(id)
        var request = MusicCatalogResourceRequest<Artist>(matching: \.id, equalTo: musicItemID)
        request.properties = [.albums]
        let response = try await request.response()
        guard let artist = response.items.first, let albums = artist.albums else {
            return []
        }
        return MusicItemMapper.toDictArray(albums)
    }

    func getAlbum(id: String) async throws -> [String: Any?] {
        let musicItemID = MusicItemID(id)
        let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: musicItemID)
        let response = try await request.response()
        guard let album = response.items.first else {
            throw MusicKitServiceError.notFound
        }
        return album.toDictionary()
    }

    func getAlbumTracks(id: String) async throws -> [[String: Any?]] {
        let musicItemID = MusicItemID(id)
        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: musicItemID)
        request.properties = [.tracks]
        let response = try await request.response()
        guard let album = response.items.first, let tracks = album.tracks else {
            return []
        }
        return MusicItemMapper.toDictArray(tracks)
    }

    // MARK: - User Library

    func getUserLibraryAlbums(limit: Int) async throws -> [[String: Any?]] {
        var request = MusicLibraryRequest<Album>()
        request.limit = limit
        let response = try await request.response()
        return MusicItemMapper.toDictArray(response.items)
    }

    func getUserLibrarySongs(limit: Int) async throws -> [[String: Any?]] {
        var request = MusicLibraryRequest<Song>()
        request.limit = limit
        let response = try await request.response()
        return MusicItemMapper.toDictArray(response.items)
    }

    func getUserLibraryArtists(limit: Int) async throws -> [[String: Any?]] {
        var request = MusicLibraryRequest<Artist>()
        request.limit = limit
        let response = try await request.response()
        return MusicItemMapper.toDictArray(response.items)
    }
}

enum MusicKitServiceError: Error {
    case notFound
}
