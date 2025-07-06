import Foundation

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
    }
    let id = UUID()
    let role: Role
    let content: String
}

struct ChatHistory: Codable {
    var messages: [ChatMessage]
}
