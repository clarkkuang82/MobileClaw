import XCTest
@testable import MCCore
@testable import MCNetworking
@testable import MCPersistence

// MARK: - MCCore Tests

final class MCCoreIntegrationTests: XCTestCase {
    func testLLMProviderDisplayName() {
        XCTAssertEqual(LLMProvider.anthropic.displayName, "Claude (Anthropic)")
        XCTAssertEqual(LLMProvider.deepSeek.displayName, "DeepSeek")
        XCTAssertEqual(LLMProvider.qwen.displayName, "Qwen (通义千问)")
    }

    func testLLMProviderIsOpenAICompatible() {
        XCTAssertFalse(LLMProvider.anthropic.isOpenAICompatible)
        XCTAssertTrue(LLMProvider.openAI.isOpenAICompatible)
        XCTAssertTrue(LLMProvider.deepSeek.isOpenAICompatible)
        XCTAssertTrue(LLMProvider.qwen.isOpenAICompatible)
        XCTAssertTrue(LLMProvider.moonshot.isOpenAICompatible)
    }

    func testChatMessageCreation() {
        let msg = ChatMessage.user("Hello")
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.textContent, "Hello")
        XCTAssertFalse(msg.hasToolUse)
    }

    func testChatMessageWithToolUse() {
        let msg = ChatMessage(role: .assistant, content: [
            .text("Let me check"),
            .toolUse(ToolUseContent(id: "tc_1", name: "search", argumentsJSON: "{\"query\":\"test\"}"))
        ])
        XCTAssertTrue(msg.hasToolUse)
        XCTAssertEqual(msg.toolUseCalls.count, 1)
        XCTAssertEqual(msg.toolUseCalls.first?.name, "search")
        XCTAssertEqual(msg.toolUseCalls.first?.argumentsJSON, "{\"query\":\"test\"}")
    }

    func testContentBlockRoundTrip() throws {
        let blocks: [ContentBlock] = [
            .text("Hello"),
            .toolUse(ToolUseContent(id: "1", name: "test", argumentsJSON: "{}")),
            .toolResult(ToolResultContent(toolUseId: "1", content: "ok")),
            .thinking("Let me think..."),
        ]
        let data = try JSONEncoder().encode(blocks)
        let decoded = try JSONDecoder().decode([ContentBlock].self, from: data)
        XCTAssertEqual(decoded.count, 4)
        XCTAssertEqual(decoded[0].textValue, "Hello")
        XCTAssertEqual(decoded[3].textValue, "Let me think...")
    }

    func testToolDefinitionUniqueID() {
        let tool1 = ToolDefinition(name: "search", description: "Search", serverID: "server_a")
        let tool2 = ToolDefinition(name: "search", description: "Search", serverID: "server_b")
        XCTAssertNotEqual(tool1.id, tool2.id)
    }

    func testDefaultModels() {
        let anthropicModels = LLMModel.defaultModels(for: .anthropic)
        XCTAssertEqual(anthropicModels.count, 3)
        XCTAssertTrue(anthropicModels.allSatisfy { $0.provider == .anthropic })

        let customModels = LLMModel.defaultModels(for: .custom)
        XCTAssertTrue(customModels.isEmpty)
    }

    func testMCErrorDescriptions() {
        let errors: [MCError] = [
            .apiKeyMissing(.anthropic),
            .networkError("timeout"),
            .apiError(statusCode: 429, message: "rate limited"),
            .rateLimited(retryAfter: 30),
            .cancelled,
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}

// MARK: - MCNetworking Tests

final class MCNetworkingIntegrationTests: XCTestCase {
    func testLLMServiceFactoryCreatesCorrectServices() {
        let anthropic = LLMServiceFactory.service(for: .anthropic)
        XCTAssertEqual(anthropic.provider, .anthropic)

        let deepSeek = LLMServiceFactory.service(for: .deepSeek)
        XCTAssertEqual(deepSeek.provider, .deepSeek)

        let qwen = LLMServiceFactory.service(for: .qwen)
        XCTAssertEqual(qwen.provider, .qwen)

        let moonshot = LLMServiceFactory.service(for: .moonshot)
        XCTAssertEqual(moonshot.provider, .moonshot)

        let openAI = LLMServiceFactory.service(for: .openAI)
        XCTAssertEqual(openAI.provider, .openAI)
    }
}

// MARK: - MCPersistence Tests

final class MCPersistenceIntegrationTests: XCTestCase {
    @MainActor
    func testConversationCRUD() throws {
        let container = try ModelContainerSetup.create(inMemory: true)
        let context = container.mainContext
        let repo = ConversationRepository(modelContext: context)

        // Create
        let conversation = repo.create(
            title: "Test Chat",
            provider: .anthropic,
            modelID: "claude-sonnet-4-20250514"
        )
        try repo.save()

        // Read
        let fetched = try repo.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Test Chat")

        // Add message
        _ = try repo.addMessage(
            to: conversation,
            role: "user",
            content: [.text("Hello")],
            modelID: nil
        )
        try repo.save()
        XCTAssertEqual(conversation.sortedMessages.count, 1)

        // Delete
        repo.delete(conversation)
        try repo.save()
        XCTAssertEqual(try repo.fetchAll().count, 0)
    }
}
