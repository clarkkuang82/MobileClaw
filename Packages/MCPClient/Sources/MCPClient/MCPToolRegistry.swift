import Foundation
import MCCore

public actor MCPToolRegistry {
    private var tools: [String: ToolDefinition] = [:]
    private var serverTools: [String: Set<String>] = [:]

    public init() {}

    public func register(tools newTools: [ToolDefinition], serverID: String) {
        serverTools[serverID] = Set(newTools.map(\.id))
        for tool in newTools {
            var t = tool
            t.serverID = serverID
            tools[t.id] = t
        }
    }

    public func unregister(serverID: String) {
        if let toolIDs = serverTools[serverID] {
            for id in toolIDs {
                tools.removeValue(forKey: id)
            }
            serverTools.removeValue(forKey: serverID)
        }
    }

    public func allTools() -> [ToolDefinition] {
        Array(tools.values)
    }

    public func tool(named name: String) -> ToolDefinition? {
        tools.values.first { $0.name == name }
    }

    public func serverID(forToolNamed name: String) -> String? {
        tools.values.first { $0.name == name }?.serverID
    }
}
