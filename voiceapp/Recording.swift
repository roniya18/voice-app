import Foundation

struct Recording: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var fileName: String
    var duration: TimeInterval
    var createdAt: Date
    var isFavourite: Bool

    init(id: UUID = UUID(), title: String, fileName: String, duration: TimeInterval, createdAt: Date = Date(), isFavourite: Bool = false) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.duration = duration
        self.createdAt = createdAt
        self.isFavourite = isFavourite
    }

    var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · h:mm a"
        return formatter.string(from: createdAt)
    }

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.id == rhs.id
    }
}
