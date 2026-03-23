import Foundation

public protocol Plugin: Sendable {
    var id: String { get }
    var name: String { get }
    var version: String { get }
    var pluginDescription: String { get }

    func preprocessMessage(_ message: ChatMessage) async throws -> ChatMessage
    func postprocessMessage(_ message: ChatMessage) async throws -> ChatMessage

    func providedTools() -> [ToolDefinition]
    func handleToolCall(name: String, argumentsJSON: String) async throws -> ToolResult
}

// Default no-op implementations
public extension Plugin {
    func preprocessMessage(_ message: ChatMessage) async throws -> ChatMessage { message }
    func postprocessMessage(_ message: ChatMessage) async throws -> ChatMessage { message }
    func providedTools() -> [ToolDefinition] { [] }
    func handleToolCall(name: String, argumentsJSON: String) async throws -> ToolResult {
        ToolResult(content: "Not implemented", isError: true)
    }
}
