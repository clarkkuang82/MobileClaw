import XCTest
import SwiftData
@testable import MCPersistence
import MCCore

final class MCPersistenceTests: XCTestCase {
    @MainActor
    func testCreateConversation() throws {
        let container = try ModelContainerSetup.create(inMemory: true)
        let context = container.mainContext
        let repo = ConversationRepository(modelContext: context)

        let conversation = repo.create(
            title: "Test Chat",
            provider: .anthropic,
            modelID: "claude-sonnet-4-20250514"
        )
        try repo.save()

        let fetched = try repo.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Test Chat")
        XCTAssertEqual(fetched.first?.providerRawValue, "anthropic")
    }

    @MainActor
    func testAddMessageToConversation() throws {
        let container = try ModelContainerSetup.create(inMemory: true)
        let context = container.mainContext
        let repo = ConversationRepository(modelContext: context)

        let conversation = repo.create(
            title: "Test",
            provider: .anthropic,
            modelID: "claude-sonnet-4-20250514"
        )

        _ = try repo.addMessage(
            to: conversation,
            role: "user",
            content: [.text("Hello")],
            modelID: nil
        )
        try repo.save()

        XCTAssertEqual(conversation.sortedMessages.count, 1)
        XCTAssertEqual(conversation.sortedMessages.first?.role, "user")
    }

    @MainActor
    func testDeleteConversation() throws {
        let container = try ModelContainerSetup.create(inMemory: true)
        let context = container.mainContext
        let repo = ConversationRepository(modelContext: context)

        let conversation = repo.create(
            title: "To Delete",
            provider: .openAI,
            modelID: "gpt-4o"
        )
        try repo.save()

        repo.delete(conversation)
        try repo.save()

        let fetched = try repo.fetchAll()
        XCTAssertEqual(fetched.count, 0)
    }
}
