import Foundation
import MusicKit

class MusicPlayerController {
    static let shared = MusicPlayerController()
    private let player = ApplicationMusicPlayer.shared

    func playSong(id: String) async throws -> Bool {
        let musicItemID = MusicItemID(id)
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: musicItemID)
        let response = try await request.response()
        guard let song = response.items.first else { return false }

        player.queue = [song]
        try await player.play()
        return true
    }

    func playAlbum(id: String) async throws -> Bool {
        let musicItemID = MusicItemID(id)
        var request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: musicItemID)
        request.properties = [.tracks]
        let response = try await request.response()
        guard let album = response.items.first else { return false }

        player.queue = [album]
        try await player.play()
        return true
    }

    /// Plays an entire playlist by fetching it from the user's library
    /// and setting the player queue to the playlist.
    func playPlaylist(id: String) async throws -> Bool {
        let musicItemID = MusicItemID(id)
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: musicItemID)
        let response = try await request.response()
        guard let playlist = response.items.first else { return false }

        player.queue = [playlist]
        try await player.play()
        return true
    }

    func pause() -> Bool {
        player.pause()
        return true
    }

    func resume() async throws -> Bool {
        try await player.play()
        return true
    }

    func skipToNext() async throws -> Bool {
        try await player.skipToNextEntry()
        return true
    }

    func skipToPrevious() async throws -> Bool {
        try await player.skipToPreviousEntry()
        return true
    }

    func seekTo(position: Double) async -> Bool {
        player.playbackTime = position
        return true
    }

    var playbackTime: TimeInterval {
        player.playbackTime
    }

    var playbackStatus: MusicPlayer.PlaybackStatus {
        player.state.playbackStatus
    }

    var nowPlayingEntry: MusicPlayer.Queue.Entry? {
        player.queue.currentEntry
    }

    func toggleShuffle() -> String {
        if player.state.shuffleMode == .off {
            player.state.shuffleMode = .songs
            return "songs"
        } else {
            player.state.shuffleMode = .off
            return "off"
        }
    }

    func toggleRepeat() -> String {
        let current = player.state.repeatMode
        if current == .all {
            player.state.repeatMode = .one
            return "one"
        } else if current == .one {
            player.state.repeatMode = MusicPlayer.RepeatMode.none
            return "none"
        } else {
            player.state.repeatMode = .all
            return "all"
        }
    }

    func getShuffleMode() -> String {
        return player.state.shuffleMode == .songs ? "songs" : "off"
    }

    func getRepeatMode() -> String {
        let mode = player.state.repeatMode
        if mode == .all { return "all" }
        if mode == .one { return "one" }
        return "none"
    }
}
