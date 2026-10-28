import Foundation

struct DeepSeekConfiguration: Sendable {
    let apiKey: String
    let model: String

    static var current: DeepSeekConfiguration? {
        let environment = ProcessInfo.processInfo.environment
        let apiKey = (
            environment["DEEPSEEK_API_KEY"]
                ?? Bundle.main.object(
                    forInfoDictionaryKey: "DEEPSEEK_API_KEY"
                ) as? String
                ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !apiKey.isEmpty,
              apiKey != "sk-your-deepseek-api-key" else {
            return nil
        }

        let model = (
            environment["DEEPSEEK_MODEL"]
                ?? Bundle.main.object(
                    forInfoDictionaryKey: "DEEPSEEK_MODEL"
                ) as? String
                ?? "deepseek-flash"
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return DeepSeekConfiguration(
            apiKey: apiKey,
            model: model.isEmpty ? "deepseek-flash" : model
        )
    }
}
