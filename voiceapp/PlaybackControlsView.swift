import SwiftUI

struct PlaybackControlsView: View {
    let recording: Recording
    @ObservedObject var player: AudioPlayerManager
    let onDismiss: () -> Void

    private var progress: Double {
        guard player.duration > 0 else { return 0 }
        return player.currentTime / player.duration
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(recording.title)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)

                Text(recording.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Seek slider
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 3)

                    Capsule()
                        .fill(Color.primary)
                        .frame(width: geo.size.width * CGFloat(progress), height: 3)

                    Circle()
                        .fill(Color.primary)
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, geo.size.width * CGFloat(progress) - 7))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let ratio = max(0, min(1, value.location.x / geo.size.width))
                            player.seek(to: ratio * player.duration)
                        }
                )
            }
            .frame(height: 20)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // Time labels
            HStack {
                Text(formatTime(player.currentTime))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatTime(player.duration))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)


            // Playback controls
            HStack(spacing: 44) {
                // Rewind 15s
                Button(action: {
                    let newTime = max(0, player.currentTime - 15)
                    player.seek(to: newTime)
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                }

                // Play/Pause
                Button(action: {
                    player.togglePlayback(for: recording)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 64, height: 64)

                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color(.systemBackground))
                    }
                }

                // Forward 15s
                Button(action: {
                    let newTime = min(player.duration, player.currentTime + 15)
                    player.seek(to: newTime)
                }) {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                }
            }
        }
        .onAppear {
            if player.playingRecordingID != recording.id {
                player.play(recording: recording)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
