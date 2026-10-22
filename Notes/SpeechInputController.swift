import AVFAudio
import Combine
import Foundation
import Speech

@MainActor
final class SpeechInputController: ObservableObject {
    enum State: Equatable {
        case idle
        case requestingPermission
        case preparing
        case listening
        case finishing
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var completedText: String?

    private var audioEngine: AVAudioEngine?
    private var speechAnalyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultTask: Task<Void, Never>?
    private var resultSegments: [String] = []

    var isListening: Bool {
        state == .listening
    }

    var isBusy: Bool {
        switch state {
        case .requestingPermission, .preparing, .finishing:
            true
        case .idle, .listening, .failed:
            false
        }
    }

    var errorMessage: String? {
        guard case let .failed(message) = state else {
            return nil
        }
        return message
    }

    func toggle() async {
        if isListening {
            await stop()
        } else if !isBusy {
            await start()
        }
    }

    func stopIfListening() async {
        guard isListening else {
            return
        }
        await stop()
    }

    func consumeCompletedText() {
        completedText = nil
    }

    func clearError() {
        guard case .failed = state else {
            return
        }
        state = .idle
    }

    private func start() async {
        state = .requestingPermission
        resultSegments = []
        completedText = nil

        do {
            try await requestPermissions()
            state = .preparing

            let requestedLocale = Locale(identifier: "en_US")
            guard let locale = await DictationTranscriber.supportedLocale(
                equivalentTo: requestedLocale
            ) else {
                throw SpeechInputError.englishUnavailable
            }

            let transcriber = DictationTranscriber(
                locale: locale,
                contentHints: [],
                transcriptionOptions: [.punctuation],
                reportingOptions: [.frequentFinalization],
                attributeOptions: []
            )

            try await prepareAssets(for: transcriber)

            guard let analyzerFormat = await SpeechAnalyzer
                .bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
                throw SpeechInputError.audioUnavailable
            }

            let (inputStream, continuation) = AsyncStream.makeStream(
                of: AnalyzerInput.self
            )

            let analyzer = SpeechAnalyzer(modules: [transcriber])
            try await analyzer.prepareToAnalyze(in: analyzerFormat)

            speechAnalyzer = analyzer
            inputContinuation = continuation
            startResultTask(for: transcriber)

            try await analyzer.start(inputSequence: inputStream)
            try startAudioCapture(
                convertingTo: analyzerFormat,
                continuation: continuation
            )
            state = .listening
        } catch {
            await resetPipeline()
            state = .failed(SpeechInputError.message(for: error))
        }
    }

    private func stop() async {
        guard isListening,
              let analyzer = speechAnalyzer,
              let continuation = inputContinuation else {
            return
        }

        state = .finishing
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        continuation.finish()
        inputContinuation = nil

        do {
            try await analyzer.finalizeAndFinishThroughEndOfInput()
            await resultTask?.value

            let transcript = normalizedTranscript
            guard !transcript.isEmpty else {
                throw SpeechInputError.noSpeechDetected
            }

            completedText = transcript
            await resetPipeline()
            state = .idle
        } catch {
            await resetPipeline()
            state = .failed(SpeechInputError.message(for: error))
        }
    }

    private var normalizedTranscript: String {
        resultSegments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func startResultTask(for transcriber: DictationTranscriber) {
        resultTask?.cancel()
        resultTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                for try await result in transcriber.results {
                    guard !Task.isCancelled else {
                        return
                    }

                    let segment = String(result.text.characters)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !segment.isEmpty {
                        self.resultSegments.append(segment)
                    }
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                await self.handleRecognitionFailure(error)
            }
        }
    }

    private func handleRecognitionFailure(_ error: Error) async {
        await resetPipeline()
        state = .failed(SpeechInputError.message(for: error))
    }

    private func startAudioCapture(
        convertingTo analyzerFormat: AVAudioFormat,
        continuation: AsyncStream<AnalyzerInput>.Continuation
    ) throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .record,
            mode: .measurement,
            options: [.allowBluetoothHFP]
        )
        try audioSession.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AudioBufferConverter(
            inputFormat: inputFormat,
            outputFormat: analyzerFormat
        ) else {
            throw SpeechInputError.audioUnavailable
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1_024,
            format: inputFormat
        ) { buffer, _ in
            guard let convertedBuffer = converter.convert(buffer) else {
                return
            }
            continuation.yield(AnalyzerInput(buffer: convertedBuffer))
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
    }

    private func requestPermissions() async throws {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization {
                continuation.resume(returning: $0)
            }
        }

        guard speechStatus == .authorized else {
            throw SpeechInputError.speechPermissionDenied
        }

        let microphoneGranted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission {
                continuation.resume(returning: $0)
            }
        }

        guard microphoneGranted else {
            throw SpeechInputError.microphonePermissionDenied
        }
    }

    private func prepareAssets(
        for transcriber: DictationTranscriber
    ) async throws {
        let status = await AssetInventory.status(forModules: [transcriber])

        switch status {
        case .installed:
            return
        case .unsupported:
            throw SpeechInputError.englishUnavailable
        case .supported, .downloading:
            guard let request = try await AssetInventory
                .assetInstallationRequest(supporting: [transcriber]) else {
                throw SpeechInputError.modelUnavailable
            }
            try await request.downloadAndInstall()
        @unknown default:
            throw SpeechInputError.modelUnavailable
        }
    }

    private func resetPipeline() async {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        inputContinuation?.finish()
        inputContinuation = nil

        resultTask?.cancel()
        resultTask = nil

        if let analyzer = speechAnalyzer {
            await analyzer.cancelAndFinishNow()
        }
        speechAnalyzer = nil

        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}

private enum SpeechInputError: Error {
    case speechPermissionDenied
    case microphonePermissionDenied
    case englishUnavailable
    case modelUnavailable
    case audioUnavailable
    case noSpeechDetected

    static func message(for error: Error) -> String {
        guard let error = error as? SpeechInputError else {
            return "Speech recognition failed. Please try again."
        }

        switch error {
        case .speechPermissionDenied:
            return "Speech recognition access is required. Enable it in Settings."
        case .microphonePermissionDenied:
            return "Microphone access is required. Enable it in Settings."
        case .englishUnavailable:
            return "English speech recognition is not available on this device."
        case .modelUnavailable:
            return "The English speech model could not be prepared."
        case .audioUnavailable:
            return "The microphone is currently unavailable."
        case .noSpeechDetected:
            return "No speech was detected. Please try again."
        }
    }
}

private final class AudioBufferConverter: @unchecked Sendable {
    private let converter: AVAudioConverter
    private let outputFormat: AVAudioFormat

    init?(inputFormat: AVAudioFormat, outputFormat: AVAudioFormat) {
        guard let converter = AVAudioConverter(
            from: inputFormat,
            to: outputFormat
        ) else {
            return nil
        }

        self.converter = converter
        self.outputFormat = outputFormat
    }

    func convert(_ inputBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let sampleRateRatio = outputFormat.sampleRate
            / inputBuffer.format.sampleRate
        let frameCapacity = AVAudioFrameCount(
            ceil(Double(inputBuffer.frameLength) * sampleRateRatio)
        )

        guard frameCapacity > 0,
              let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: frameCapacity
              ) else {
            return nil
        }

        var suppliedInput = false
        var conversionError: NSError?
        let status = converter.convert(
            to: outputBuffer,
            error: &conversionError
        ) { _, inputStatus in
            if suppliedInput {
                inputStatus.pointee = .noDataNow
                return nil
            }

            suppliedInput = true
            inputStatus.pointee = .haveData
            return inputBuffer
        }

        guard status != .error,
              conversionError == nil,
              outputBuffer.frameLength > 0 else {
            return nil
        }

        return outputBuffer
    }
}
