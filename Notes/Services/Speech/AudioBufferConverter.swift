import AVFAudio

final class AudioBufferConverter: @unchecked Sendable {
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
