import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var alertItem: AlertItem?

    private let service = OpenAIService()
    private let logURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logURL = documents.appendingPathComponent("chat_log.txt")
        loadHistory()
    }

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        await saveHistory()
        do {
            if let response = try await service.send(messages: messages) {
                messages.append(response)
                await saveHistory()
            }
        } catch {
            alertItem = AlertItem(message: error.localizedDescription)
        }
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: logURL) else { return }
        if let history = try? JSONDecoder().decode(ChatHistory.self, from: data) {
            messages = history.messages
        }
    }

    private func saveHistory() async {
        let history = ChatHistory(messages: messages)
        if let data = try? JSONEncoder().encode(history) {
            try? data.write(to: logURL, options: .atomic)
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
