import SwiftUI

struct ContentView: View {
    
    @StateObject private var recorder = AudioRecorderManager()
    @StateObject private var player = AudioPlayerManager()
    @StateObject private var store = RecordingsStore()
    
    @State private var selectedRecording: Recording?
    @State private var showPlayback = false
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var tabArray = ["All", "Starred"]
    
    private var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            if selectedTab == 1 {
                return store.recordings.filter { $0.isFavourite }
            }
            return store.recordings
        }
        return store.recordings.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                TitleView()
                SearchBarView()
                TopTabView()
                RecordingListView()
                Spacer(minLength: 0)
            }
            RecordingCardView()
        }
        .sheet(isPresented: $showPlayback) {
            if let recording = selectedRecording {
                PlaybackControlsView(
                    recording: recording,
                    player: player,
                    onDismiss: {
                        showPlayback = false
                        selectedRecording = nil
                    }
                )
                .presentationDetents([.height(300)])
                .presentationBackground(.thinMaterial)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: recorder.isRecording)
    }
    
    private func TitleView() -> some View {
        HStack(alignment: .center) {
            Text("Voice App")
                .font(.system(size: 32, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    private func SearchBarView() -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
                TextField("Search", text: $searchText)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private func TopTabView() -> some View {
        HStack(spacing: 8) {
            ForEach(tabArray.indices, id: \.self) { i in
                Button(action: { selectedTab = i }) {
                    Text(tabArray[i])
                        .font(.system(size: 14, weight: selectedTab == i ? .semibold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedTab == i ? Color(.systemGray5) : Color.clear)
                        )
                        .foregroundStyle(.primary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func RecordingListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredRecordings.isEmpty {
                    EmptyView()
                } else {
                    ForEach(filteredRecordings) { recording in
                        RecordingRowView(
                            recording: recording,
                            isPlaying: player.isPlaying && player.playingRecordingID == recording.id,
                            isSelected: selectedRecording?.id == recording.id,
                            onTap: {
                                selectedRecording = recording
                                showPlayback = true
                                player.togglePlayback(for: recording)
                            },
                            onDelete: {
                                if player.playingRecordingID == recording.id { player.stop() }
                                withAnimation { store.delete(recording) }
                            },
                            onRename: { newTitle in
                                store.rename(recording, to: newTitle)
                            },
                            onFav: {
                                store.addOrRemoveFromFavourite(recording)
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, recorder.isRecording ? 180 : 100)
        }
        
    }
    
    
    private func RecordingCardView() -> some View {
        VStack(spacing: 0) {
            Spacer()
            VStack {
                if recorder.isRecording {
                    RecordingView()
                }
                RecordButtonView()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12.0)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(16)
        }
    }
    
    private func RecordingView() -> some View {
        ZStack {
            Color(.gray.opacity(0.2))
            WaveformView(
                samples: recorder.waveformSamples,
                barWidth: 3,
                spacing: 2,
                minHeight: 3,
                animated: true
            )
            HStack(spacing: 8) {
                Image(systemName: recorder.isRecording ? "pause.fill" : "triangle.right.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
                Text(formatTime(recorder.recordingTime))
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
            }
        }
        .frame(height: 50)
        .clipShape(Capsule())
    }
    
    private func RecordButtonView() -> some View {
        Text(recorder.isRecording ? "Done" : "Record")
            .foregroundStyle(recorder.isRecording ? .green: .blue)
            .frame(height: 50)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(
                Capsule()
                    .foregroundStyle(recorder.isRecording ? .green.opacity(0.3) : .blue.opacity(0.3))
            )
            .onTapGesture {
                if recorder.isRecording {
                    recorder.stopRecording { recording in
                        if let recording {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                store.add(recording)
                            }
                        }
                    }
                } else {
                    recorder.startRecording()
                }
            }
    }
    
    private func EmptyView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
                .padding(.top, 60)
            
            Text("No Recordings Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            if selectedTab == 0 {
                Text("Tap the record button below to capture your first recording.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
