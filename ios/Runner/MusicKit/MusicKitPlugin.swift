import Flutter
import UIKit

class MusicKitPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.fastestmusic/musickit",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.fastestmusic/musickit/playback_state",
            binaryMessenger: registrar.messenger()
        )

        let streamHandler = PlaybackStateStreamHandler()
        eventChannel.setStreamHandler(streamHandler)

        channel.setMethodCallHandler { (call, result) in
            Task {
                await handleMethodCall(call: call, result: result)
            }
        }
    }

    private static func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) async {
        let service = MusicKitService.shared
        let playerController = MusicPlayerController.shared
        let args = call.arguments as? [String: Any]

        do {
            switch call.method {
            case "requestAuthorization":
                let status = await service.requestAuthorization()
                result(status)

            case "getRecentlyPlayed":
                let limit = args?["limit"] as? Int ?? 10
                let data = try await service.getRecentlyPlayed(limit: limit)
                result(data)

            case "searchCatalog":
                guard let term = args?["term"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "term is required", details: nil))
                    return
                }
                let types = args?["types"] as? [String] ?? ["songs", "albums", "artists"]
                let data = try await service.searchCatalog(term: term, types: types)
                result(data)

            case "getArtist":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let data = try await service.getArtist(id: id)
                result(data)

            case "getArtistTopSongs":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let limit = args?["limit"] as? Int ?? 10
                let data = try await service.getArtistTopSongs(id: id, limit: limit)
                result(data)

            case "getArtistAlbums":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let data = try await service.getArtistAlbums(id: id)
                result(data)

            case "getAlbum":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let data = try await service.getAlbum(id: id)
                result(data)

            case "getAlbumTracks":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let data = try await service.getAlbumTracks(id: id)
                result(data)

            case "playSong":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let success = try await playerController.playSong(id: id)
                result(success)

            case "playAlbum":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let success = try await playerController.playAlbum(id: id)
                result(success)

            case "pause":
                let success = playerController.pause()
                result(success)

            case "resume":
                let success = try await playerController.resume()
                result(success)

            case "skipToNext":
                let success = try await playerController.skipToNext()
                result(success)

            case "skipToPrevious":
                let success = try await playerController.skipToPrevious()
                result(success)

            case "seekTo":
                guard let position = args?["position"] as? Double else {
                    result(FlutterError(code: "INVALID_ARGS", message: "position is required", details: nil))
                    return
                }
                let success = await playerController.seekTo(position: position)
                result(success)

            case "getUserPlaylists":
                let playlistController = PlaylistController.shared
                let data = try await playlistController.getUserPlaylists()
                result(data)

            case "createPlaylist":
                guard let name = args?["name"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "name is required", details: nil))
                    return
                }
                let playlistController = PlaylistController.shared
                let data = try await playlistController.createPlaylist(name: name)
                result(data)

            case "getPlaylistTracks":
                guard let playlistId = args?["playlistId"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "playlistId is required", details: nil))
                    return
                }
                let playlistController = PlaylistController.shared
                let data = try await playlistController.getPlaylistTracks(playlistId: playlistId)
                result(data)

            case "playPlaylist":
                guard let id = args?["id"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "id is required", details: nil))
                    return
                }
                let success = try await playerController.playPlaylist(id: id)
                result(success)

            case "addSongToPlaylist":
                guard let songId = args?["songId"] as? String,
                      let playlistId = args?["playlistId"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "songId and playlistId are required", details: nil))
                    return
                }
                let playlistController = PlaylistController.shared
                let success = try await playlistController.addSongToPlaylist(songId: songId, playlistId: playlistId)
                result(success)

            case "toggleShuffle":
                let mode = playerController.toggleShuffle()
                result(mode)

            case "toggleRepeat":
                let mode = playerController.toggleRepeat()
                result(mode)

            case "getShuffleMode":
                let mode = playerController.getShuffleMode()
                result(mode)

            case "getRepeatMode":
                let mode = playerController.getRepeatMode()
                result(mode)

            case "getUserLibraryAlbums":
                let limit = args?["limit"] as? Int ?? 100
                let data = try await service.getUserLibraryAlbums(limit: limit)
                result(data)

            case "getUserLibrarySongs":
                let limit = args?["limit"] as? Int ?? 200
                let data = try await service.getUserLibrarySongs(limit: limit)
                result(data)

            case "getUserLibraryArtists":
                let limit = args?["limit"] as? Int ?? 100
                let data = try await service.getUserLibraryArtists(limit: limit)
                result(data)

            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            let message = "\(type(of: error)): \(error.localizedDescription)"
            result(FlutterError(code: "MUSICKIT_ERROR", message: message, details: String(describing: error)))
        }
    }
}
