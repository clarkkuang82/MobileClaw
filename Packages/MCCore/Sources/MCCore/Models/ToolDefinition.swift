import Foundation

public struct ToolDefinition: Codable, Sendable, Identifiable, Hashable {
    public let name: String
    public let description: String
    public let inputSchemaJSON: String
    public var serverID: String?

    public var id: String { "\(serverID ?? "local")_\(name)" }

    public init(
        name: String,
        description: String,
        inputSchemaJSON: String = "{}",
        serverID: String? = nil
    ) {
        self.name = name
        self.description = description
        self.inputSchemaJSON = inputSchemaJSON
        self.serverID = serverID
    }
}

public struct ToolResult: Sendable {
    public let content: String
    public let isError: Bool

    public init(content: String, isError: Bool = false) {
        self.content = content
        self.isError = isError
    }
}
