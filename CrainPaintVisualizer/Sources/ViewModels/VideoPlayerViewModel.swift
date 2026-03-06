import Foundation

@MainActor
@Observable
final class VideoPlayerViewModel {
    var isPlaying = false
    var progress: Double = 0.22
    var isLoading = false

    var elapsedText: String { timeText(for: progress * duration) }
    var remainingText: String { timeText(for: max(duration - (progress * duration), 0)) }

    let duration: TimeInterval

    init(duration: TimeInterval = 12 * 60 + 40) {
        self.duration = duration
    }

    func togglePlay() {
        isPlaying.toggle()
    }

    func seek(to value: Double) {
        progress = min(max(value, 0), 1)
    }

    private func timeText(for seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
