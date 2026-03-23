import Foundation
import MCCore

/// Manages multiple MCP server connections and aggregates their tools.
/// Full implementation coming in Phase 3.
public final class MCPManager: @unchecked Sendable {
    public static let shared = MCPManager()

    private init() {}

    public func availableTools() -> [ToolDefinition] {
        []
    }

    public func callTool(name: String, arguments: [String: Any]) async throws -> ToolResult {
        throw MCError.toolCallFailed(toolName: name, message: "MCP not yet configured")
    }
}
