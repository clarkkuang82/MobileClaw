import SwiftData
import Foundation

@Model
public final class MessageEntity {
    public var id: UUID = UUID()
    public var role: String = "user"
    public var contentJSON: String?
    public var createdAt: Date = Date()
    public var tokenCount: Int?
    public var modelID: String?
    public var isStreaming: Bool = false

    public var conversation: ConversationEntity?

    public init(
        role: String = "user",
        contentJSON: String? = nil,
        modelID: String? = nil
    ) {
        self.id = UUID()
        self.role = role
        self.contentJSON = contentJSON
        self.createdAt = Date()
        self.modelID = modelID
    }
}
