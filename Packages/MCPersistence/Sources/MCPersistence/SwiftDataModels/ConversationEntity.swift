import SwiftData
import Foundation

@Model
public final class ConversationEntity {
    public var id: UUID = UUID()
    public var title: String = ""
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    public var isPinned: Bool = false
    public var providerRawValue: String = "anthropic"
    public var modelID: String = ""
    public var systemPrompt: String?
    public var agentID: UUID?

    @Relationship(deleteRule: .cascade, inverse: \MessageEntity.conversation)
    public var messages: [MessageEntity]? = []

    public init(
        title: String = "",
        providerRawValue: String = "anthropic",
        modelID: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.providerRawValue = providerRawValue
        self.modelID = modelID
    }

    public var sortedMessages: [MessageEntity] {
        (messages ?? []).sorted { $0.createdAt < $1.createdAt }
    }
}
