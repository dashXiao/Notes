import Foundation

struct DeepSeekRequest: Encodable {
    let model: String
    let messages: [DeepSeekMessage]
    let responseFormat: ResponseFormat
    let thinking: Thinking
    let temperature: Double
    let maxTokens: Int
    let stream: Bool

    struct ResponseFormat: Encodable {
        let type: String
    }

    struct Thinking: Encodable {
        let type: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
        case thinking
        case temperature
        case maxTokens = "max_tokens"
        case stream
    }
}

struct DeepSeekMessage: Encodable {
    let role: String
    let content: String
}

struct DeepSeekResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

struct DeepSeekPayload: Decodable {
    let isSchedule: Bool
    let title: String?
    let date: String?
    let time: String?
    let timeIsPending: Bool?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
        case isSchedule = "is_schedule"
        case title
        case date
        case time
        case timeIsPending = "time_is_pending"
        case confidence
    }
}

enum DeepSeekError: Error {
    case invalidRequest
    case requestFailed
    case invalidDate
}
