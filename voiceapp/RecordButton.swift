import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            ZStack {
                // Pulse ring (only while recording)
                if isRecording {
                    Circle()
                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 2)
                        .frame(width: 88, height: 88)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                }

                // Outer ring
                Circle()
                    .strokeBorder(isRecording ? Color.red.opacity(0.25) : Color(.systemGray5), lineWidth: 3)
                    .frame(width: 76, height: 76)

                // Inner button
                Circle()
                    .fill(isRecording ? Color.red : Color(.systemGray6))
                    .frame(width: 62, height: 62)
                    .shadow(color: isRecording ? .red.opacity(0.4) : .black.opacity(0.08), radius: isRecording ? 12 : 4, y: 2)

                // Icon
                if isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .buttonStyle(.plain)
        .onChange(of: isRecording) { _, recording in
            if recording {
                startPulse()
            } else {
                pulseScale = 1.0
                pulseOpacity = 0.0
            }
        }
    }

    private func startPulse() {
        guard isRecording else { return }
        pulseScale = 1.0
        pulseOpacity = 0.6

        withAnimation(.easeOut(duration: 1.2)) {
            pulseScale = 1.6
            pulseOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            if isRecording { startPulse() }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        RecordButton(isRecording: false) {}
        RecordButton(isRecording: true) {}
    }
    .padding()
}
