import Foundation

enum SpeechInputError: Error {
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
