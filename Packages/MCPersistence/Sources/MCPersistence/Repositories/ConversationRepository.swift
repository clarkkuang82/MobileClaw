import SwiftData
import Foundation
import MCCore

@MainActor
public final class ConversationRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func fetchAll() throws -> [ConversationEntity] {
        let descriptor = FetchDescriptor<ConversationEntity>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetch(id: UUID) throws -> ConversationEntity? {
        let descriptor = FetchDescriptor<ConversationEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    public func create(
        title: String,
        provider: LLMProvider,
        modelID: String,
        systemPrompt: String? = nil
    ) -> ConversationEntity {
        let entity = ConversationEntity(
            title: title,
            providerRawValue: provider.rawValue,
            modelID: modelID
        )
        entity.systemPrompt = systemPrompt
        modelContext.insert(entity)
        return entity
    }

    public func addMessage(
        to conversation: ConversationEntity,
        role: String,
        content: [ContentBlock],
        modelID: String? = nil
    ) throws -> MessageEntity {
        let data = try JSONEncoder().encode(content)
        let jsonString = String(data: data, encoding: .utf8)
        let message = MessageEntity(role: role, contentJSON: jsonString, modelID: modelID)
        message.conversation = conversation
        modelContext.insert(message)
        conversation.updatedAt = Date()
        return message
    }

    public func delete(_ conversation: ConversationEntity) {
        modelContext.delete(conversation)
    }

    public func save() throws {
        try modelContext.save()
    }
}
