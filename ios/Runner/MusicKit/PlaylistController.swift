import Foundation
import MusicKit

class PlaylistController {
    static let shared = PlaylistController()

    /// Fetches the user's library playlists.
    func getUserPlaylists() async throws -> [[String: Any?]] {
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        return PlaylistMapper.toDictArray(response.items)
    }

    /// Creates a new playlist with the given name.
    func createPlaylist(name: String) async throws -> [String: Any?] {
        let playlist = try await MusicLibrary.shared.createPlaylist(name: name)
        return PlaylistMapper.toDict(playlist)
    }

    /// Fetches the tracks for a specific playlist.
    ///
    /// Uses `MusicLibraryRequest` to find the playlist by ID, then loads
    /// its `.tracks` relationship via `with([.tracks])`. Each track is
    /// mapped through `TrackMapper` to produce a Flutter-compatible dict.
    func getPlaylistTracks(playlistId: String) async throws -> [[String: Any?]] {
        let playlistMusicItemID = MusicItemID(playlistId)
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: playlistMusicItemID)
        let response = try await request.response()
        guard let playlist = response.items.first else { return [] }

        // Load the tracks relationship
        let detailedPlaylist = try await playlist.with([.tracks])
        guard let tracks = detailedPlaylist.tracks else { return [] }

        return TrackMapper.toDictArray(tracks)
    }

    /// Adds a song to a playlist by their IDs.
    func addSongToPlaylist(songId: String, playlistId: String) async throws -> Bool {
        let songMusicItemID = MusicItemID(songId)
        let playlistMusicItemID = MusicItemID(playlistId)

        // Fetch the song
        let songRequest = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: songMusicItemID)
        let songResponse = try await songRequest.response()
        guard let song = songResponse.items.first else { return false }

        // Fetch the playlist from the library
        var playlistRequest = MusicLibraryRequest<Playlist>()
        playlistRequest.filter(matching: \.id, equalTo: playlistMusicItemID)
        let playlistResponse = try await playlistRequest.response()
        guard let playlist = playlistResponse.items.first else { return false }

        // Add the song to the playlist
        try await MusicLibrary.shared.add(song, to: playlist)
        return true
    }
}
