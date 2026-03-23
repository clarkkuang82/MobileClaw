import Foundation

public struct ChatMessage: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let role: Role
    public var content: [ContentBlock]
    public let createdAt: Date
    public var modelID: String?
    public var tokenCount: Int?

    public init(
        id: UUID = UUID(),
        role: Role,
        content: [ContentBlock],
        createdAt: Date = Date(),
        modelID: String? = nil,
        tokenCount: Int? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.modelID = modelID
        self.tokenCount = tokenCount
    }

    public enum Role: String, Codable, Sendable, Hashable {
        case user
        case assistant
        case system
    }

    // Convenience for simple text messages
    public var textContent: String {
        content.compactMap(\.textValue).joined()
    }

    public static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: .user, content: [.text(text)])
    }

    public static func assistant(_ text: String, modelID: String? = nil) -> ChatMessage {
        ChatMessage(role: .assistant, content: [.text(text)], modelID: modelID)
    }

    public static func system(_ text: String) -> ChatMessage {
        ChatMessage(role: .system, content: [.text(text)])
    }

    // Check if message contains tool calls
    public var hasToolUse: Bool {
        content.contains { block in
            if case .toolUse = block { return true }
            return false
        }
    }

    public var toolUseCalls: [ToolUseContent] {
        content.compactMap { block in
            if case .toolUse(let toolUse) = block { return toolUse }
            return nil
        }
    }
}
