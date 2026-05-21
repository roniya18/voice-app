import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {

    // MARK: - Published State
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playingRecordingID: UUID?

    // MARK: - Private
    private var player: AVAudioPlayer?
    private var timer: Timer?

    // MARK: - Playback
    func play(recording: Recording) {
        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: recording.fileURL)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()

            duration = player?.duration ?? recording.duration
            playingRecordingID = recording.id
            isPlaying = true

            startProgressTimer()
        } catch {
            print("Playback error: \(error)")
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
    }

    func resume() {
        player?.play()
        isPlaying = true
        startProgressTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        timer?.invalidate()
        timer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        playingRecordingID = nil
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }

    func togglePlayback(for recording: Recording) {
        if playingRecordingID == recording.id {
            if isPlaying {
                pause()
            } else {
                resume()
            }
        } else {
            play(recording: recording)
        }
    }

    // MARK: - Timer
    private func startProgressTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            DispatchQueue.main.async {
                self.currentTime = player.currentTime
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.currentTime = 0
            self?.playingRecordingID = nil
            self?.timer?.invalidate()
        }
    }
}
