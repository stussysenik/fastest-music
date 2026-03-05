import Foundation
import MusicKit

struct PlaybackStateMapper {
    static func toDict(
        status: MusicPlayer.PlaybackStatus,
        nowPlaying: MusicPlayer.Queue.Entry?,
        playbackTime: TimeInterval
    ) -> [String: Any?] {
        var dict: [String: Any?] = [
            "status": statusString(status),
            "playbackTime": playbackTime,
        ]

        if let entry = nowPlaying {
            dict["title"] = entry.title
            dict["subtitle"] = entry.subtitle
            dict["artworkUrl"] = entry.artwork?.url(width: 600, height: 600)?.absoluteString

            switch entry.item {
            case .song(let song):
                dict["songId"] = song.id.rawValue
                dict["duration"] = song.duration
                dict["artistName"] = song.artistName
                dict["albumTitle"] = song.albumTitle
            default:
                break
            }
        }

        return dict
    }

    private static func statusString(_ status: MusicPlayer.PlaybackStatus) -> String {
        switch status {
        case .playing: return "playing"
        case .paused: return "paused"
        case .stopped: return "stopped"
        case .interrupted: return "interrupted"
        case .seekingForward: return "seekingForward"
        case .seekingBackward: return "seekingBackward"
        @unknown default: return "unknown"
        }
    }
}
