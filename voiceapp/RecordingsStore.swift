import Foundation
import Combine
import SwiftUI

class RecordingsStore: ObservableObject {

    @Published var recordings: [Recording] = []

    private let storageKey = "saved_recordings"

    init() {
        load()
    }

    func add(_ recording: Recording) {
        recordings.insert(recording, at: 0)
        save()
    }

    func delete(_ recording: Recording) {
        // Remove file from disk
        try? FileManager.default.removeItem(at: recording.fileURL)
        recordings.removeAll { $0.id == recording.id }
        save()
    }

    func rename(_ recording: Recording, to newTitle: String) {
        if let index = recordings.firstIndex(of: recording) {
            recordings[index].title = newTitle
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            try? FileManager.default.removeItem(at: recording.fileURL)
        }
        recordings.remove(atOffsets: offsets)
        save()
    }
    
    func addOrRemoveFromFavourite(_ recording: Recording) {
        if let index = recordings.firstIndex(of: recording) {
            recordings[index].isFavourite.toggle()
        }
        save()
    }
    // MARK: - Persistence
    private func save() {
        if let encoded = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Recording].self, from: data)
        else { return }
        recordings = decoded
    }
}
