import Flutter
import Foundation
import MusicKit
import Combine

class PlaybackStateStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var cancellables = Set<AnyCancellable>()
    private let player = ApplicationMusicPlayer.shared
    private var timer: Timer?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        player.state.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.sendPlaybackState()
            }
            .store(in: &cancellables)

        player.queue.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.sendPlaybackState()
            }
            .store(in: &cancellables)

        // Timer for playback time updates during playback
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.player.state.playbackStatus == .playing {
                self.sendPlaybackState()
            }
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        cancellables.removeAll()
        timer?.invalidate()
        timer = nil
        return nil
    }

    private func sendPlaybackState() {
        let controller = MusicPlayerController.shared
        let dict = PlaybackStateMapper.toDict(
            status: controller.playbackStatus,
            nowPlaying: controller.nowPlayingEntry,
            playbackTime: controller.playbackTime
        )
        eventSink?(dict)
    }
}
