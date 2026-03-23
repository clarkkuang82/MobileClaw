import Foundation

public enum ContentBlock: Codable, Sendable, Hashable {
    case text(String)
    case image(ImageContent)
    case toolUse(ToolUseContent)
    case toolResult(ToolResultContent)
    case thinking(String)

    public var textValue: String? {
        switch self {
        case .text(let text): text
        case .thinking(let text): text
        default: nil
        }
    }
}

public struct ImageContent: Codable, Sendable, Hashable {
    public let type: ImageSourceType
    public let mediaType: String
    public let data: String

    public init(type: ImageSourceType = .base64, mediaType: String, data: String) {
        self.type = type
        self.mediaType = mediaType
        self.data = data
    }

    public enum ImageSourceType: String, Codable, Sendable, Hashable {
        case base64
        case url
    }
}

public struct ToolUseContent: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let argumentsJSON: String

    public init(id: String, name: String, argumentsJSON: String) {
        self.id = id
        self.name = name
        self.argumentsJSON = argumentsJSON
    }
}

public struct ToolResultContent: Codable, Sendable, Hashable {
    public let toolUseId: String
    public let content: String
    public let isError: Bool

    public init(toolUseId: String, content: String, isError: Bool = false) {
        self.toolUseId = toolUseId
        self.content = content
        self.isError = isError
    }
}
