import Foundation

public protocol MCPClientProtocol: Sendable {
    func connect() async throws
    func disconnect() async throws

    func listTools() async throws -> [ToolDefinition]
    func callTool(name: String, arguments: [String: Any]) async throws -> ToolResult

    var isConnected: Bool { get }
    var serverName: String { get }
}
