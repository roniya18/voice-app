import SwiftUI

struct RecordingPanelView: View {
    @ObservedObject var recorder: AudioRecorderManager
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Chevron handle
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.systemGray3))

            // Waveform
            WaveformView(
                samples: recorder.waveformSamples,
                color: .red,
                barWidth: 3,
                spacing: 2,
                minHeight: 3,
                animated: true
            )
            .frame(height: 48)
            .padding(.horizontal, 24)

            // Timer + controls row
            HStack(spacing: 20) {
                // Recording indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(blinkOpacity)

                    Text(formatTime(recorder.recordingTime))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Stop / save button
                RecordButton(isRecording: true, action: onStop)

                Spacer()
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 20, y: -4)
        )
    }

    // Blinking dot animation
    @State private var blinkOpacity: Double = 1.0

    private func startBlink() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            blinkOpacity = 0.2
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
