import Foundation
import AVFoundation
import Combine

class AudioRecorderManager: NSObject, ObservableObject {

    // MARK: - Published State
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var waveformSamples: [Float] = Array(repeating: 0, count: 60)
    @Published var permissionGranted = false

    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var currentFileURL: URL?
    private var recordingStartTime: Date?
    private var timer: Timer?
    private var meterTimer: Timer?
    private let maxSamples = 10

    override init() {
        super.init()
        requestPermission()
    }

    // MARK: - Permission
    func requestPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
            }
        }
    }

    // MARK: - Recording Control
    func startRecording() {
        guard permissionGranted else {
            requestPermission()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let engine = AVAudioEngine()
            audioEngine = engine
            inputNode = engine.inputNode
            guard let inputNode else { return }
            let format = inputNode.outputFormat(forBus: 0)
            let fileName = "recording_\(UUID().uuidString).m4a"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            currentFileURL = fileURL

            // Use AAC format for saving
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioFile = try AVAudioFile(
                forWriting: fileURL,
                settings: settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                guard let self = self else { return }
                do {
                    try self.audioFile?.write(from: buffer)
                } catch {
                    print("Write error: \(error)")
                }
                self.processMeterData(buffer: buffer)
            }

            try engine.start()

            recordingStartTime = Date()
            isRecording = true
            waveformSamples = Array(repeating: 0, count: maxSamples)

            // Timer for elapsed time
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let start = self.recordingStartTime else { return }
                DispatchQueue.main.async {
                    self.recordingTime = Date().timeIntervalSince(start)
                }
            }

        } catch {
            print("Recording error: \(error)")
        }
    }

    func stopRecording(completion: @escaping (Recording?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }

        timer?.invalidate()
        timer = nil

        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        let duration = recordingTime
        isRecording = false
        recordingTime = 0

        try? AVAudioSession.sharedInstance().setActive(false)

        guard let fileURL = currentFileURL else {
            completion(nil)
            return
        }

        let fileName = fileURL.lastPathComponent
        let recording = Recording(
            title: generateTitle(),
            fileName: fileName,
            duration: duration
        )

        DispatchQueue.main.async {
            completion(recording)
        }
    }

    // MARK: - Waveform Processing
    private func processMeterData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        var rms: Float = 0
        for i in 0..<frameLength {
            rms += channelData[i] * channelData[i]
        }
        rms = sqrt(rms / Float(frameLength))

        // Normalize and add some visual gain
        let normalized = min(rms * 8, 1.0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var samples = self.waveformSamples
            samples.removeFirst()
            samples.append(normalized)
            self.waveformSamples = samples
        }
    }

    // MARK: - Helpers
    private func generateTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "Recording \(formatter.string(from: Date()))"
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
