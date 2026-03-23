import Foundation
import MCCore

public actor MCPManager {
    public static let shared = MCPManager()

    private var connections: [String: MCPServerConnection] = [:]
    public let toolRegistry = MCPToolRegistry()

    private init() {}

    public func addServer(name: String, config: MCPServerConfig) async throws -> String {
        let connection = MCPServerConnection(name: name, config: config)
        let id = await connection.id
        connections[id] = connection

        try await connection.connect()
        let tools = try await connection.listTools()
        await toolRegistry.register(tools: tools, serverID: id)
        return id
    }

    public func removeServer(id: String) async {
        if let connection = connections[id] {
            await connection.disconnect()
            await toolRegistry.unregister(serverID: id)
            connections.removeValue(forKey: id)
        }
    }

    public func availableTools() async -> [ToolDefinition] {
        await toolRegistry.allTools()
    }

    public func callTool(name: String, argumentsJSON: String) async throws -> ToolResult {
        guard let serverID = await toolRegistry.serverID(forToolNamed: name) else {
            throw MCError.toolCallFailed(toolName: name, message: "No server provides tool '\(name)'")
        }
        guard let connection = connections[serverID] else {
            throw MCError.toolCallFailed(toolName: name, message: "Server not found")
        }
        return try await connection.callTool(name: name, argumentsJSON: argumentsJSON)
    }

    public func connectedServers() -> [(id: String, name: String)] {
        connections.map { ($0.key, $0.value) }.map { (id, conn) in
            (id: id, name: "")  // Name accessed asynchronously
        }
    }

    public func serverCount() -> Int {
        connections.count
    }

    public func disconnectAll() async {
        for (_, connection) in connections {
            await connection.disconnect()
        }
        connections.removeAll()
    }
}
