import Foundation

struct OpenAIChatRequest: Codable {
    struct Message: Codable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
}

struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

final class OpenAIService {
    private let apiKey: String

    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }

    func send(messages: [ChatMessage]) async throws -> ChatMessage? {
        guard !apiKey.isEmpty else { throw OpenAIError.missingAPIKey }
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestMessages = messages.map { OpenAIChatRequest.Message(role: $0.role.rawValue, content: $0.content) }
        let body = OpenAIChatRequest(model: "gpt-3.5-turbo", messages: requestMessages)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OpenAIError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let message = decoded.choices.first?.message else { return nil }
        return ChatMessage(role: .assistant, content: message.content.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    enum OpenAIError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case decodingError

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing OpenAI API Key"
            case .invalidResponse:
                return "Invalid response from server"
            case .decodingError:
                return "Failed to decode response"
            }
        }
    }
}
