import SwiftUI

struct RecordingRowView: View {
    let recording: Recording
    let isPlaying: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void
    let onFav: () -> Void

    @State private var showRenameAlert = false
    @State private var newTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(recording.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(recording.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(recording.formattedDuration)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill( Color(.systemGray5))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // Action buttons
                Button(action: {
                    newTitle = recording.title
                    showRenameAlert = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Button(action: onFav) {
                    Image(systemName: recording.isFavourite ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .alert("Rename Recording", isPresented: $showRenameAlert) {
            TextField("Recording name", text: $newTitle)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if !newTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    onRename(newTitle.trimmingCharacters(in: .whitespaces))
                }
            }
        }
    }
}
