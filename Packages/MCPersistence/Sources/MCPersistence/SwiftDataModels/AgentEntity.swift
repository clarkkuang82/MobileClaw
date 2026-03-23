import SwiftData
import Foundation

@Model
public final class AgentEntity {
    public var id: UUID = UUID()
    public var name: String = ""
    public var systemPrompt: String = ""
    public var providerRawValue: String = "anthropic"
    public var modelID: String = ""
    public var temperature: Double = 0.7
    public var maxTokens: Int = 4096
    public var toolIDs: [String]?
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    public var iconName: String?
    public var colorHex: String?

    public init(name: String = "", systemPrompt: String = "") {
        self.id = UUID()
        self.name = name
        self.systemPrompt = systemPrompt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
