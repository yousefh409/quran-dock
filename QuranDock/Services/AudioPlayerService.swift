import AVFoundation
import Combine

@MainActor
class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var speed: Float = 1.0

    var onTrackFinished: (() -> Void)?

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    // MARK: - Playback

    func loadAndPlay(url: URL) {
        stop()
        isLoading = true

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        statusObservation = item.observe(\.status) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.duration = item.duration.seconds.isNaN ? 0 : item.duration.seconds
                    self.isLoading = false
                    self.player?.rate = self.speed
                    self.isPlaying = true
                case .failed:
                    self.isLoading = false
                    print("[AudioPlayer] Failed: \(item.error?.localizedDescription ?? "unknown")")
                default:
                    break
                }
            }
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self, !self.isSeeking else { return }
                self.currentTime = time.seconds
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    func play() {
        player?.rate = speed
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func stop() {
        player?.pause()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        statusObservation?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    // MARK: - Seeking

    private var isSeeking = false

    func seek(to time: TimeInterval) {
        // Immediately reflect the new position so the UI doesn't snap back
        currentTime = time
        isSeeking = true

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.isSeeking = false
            }
        }
    }

    func skipForward(_ seconds: TimeInterval = AppConstants.skipInterval) {
        seek(to: min(currentTime + seconds, duration))
    }

    func skipBackward(_ seconds: TimeInterval = AppConstants.skipInterval) {
        seek(to: max(currentTime - seconds, 0))
    }

    // MARK: - Speed

    func setSpeed(_ value: Float) {
        speed = min(max(value, 0.5), 2.0)
        if isPlaying {
            player?.rate = speed
        }
    }

    func setPresetSpeed(_ preset: PlaybackSpeed) {
        setSpeed(preset.rawValue)
    }

    // MARK: - Private

    @objc private func playerDidFinish() {
        isPlaying = false
        currentTime = 0
        onTrackFinished?()
    }
}
