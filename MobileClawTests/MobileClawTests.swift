import XCTest
@testable import MCCore

final class MCCoreTests: XCTestCase {
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
    }

    func testChatMessageAssistant() {
        let msg = ChatMessage.assistant("Hi there", modelID: "claude-sonnet-4-20250514")
        XCTAssertEqual(msg.role, .assistant)
        XCTAssertEqual(msg.textContent, "Hi there")
        XCTAssertEqual(msg.modelID, "claude-sonnet-4-20250514")
    }

    func testContentBlockEncoding() throws {
        let blocks: [ContentBlock] = [
            .text("Hello"),
            .toolUse(ToolUseContent(id: "1", name: "test", argumentsJSON: "{}")),
        ]
        let data = try JSONEncoder().encode(blocks)
        let decoded = try JSONDecoder().decode([ContentBlock].self, from: data)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].textValue, "Hello")
    }

    func testChatMessageHasToolUse() {
        let msg = ChatMessage(role: .assistant, content: [
            .text("Let me check"),
            .toolUse(ToolUseContent(id: "1", name: "search", argumentsJSON: "{}"))
        ])
        XCTAssertTrue(msg.hasToolUse)
        XCTAssertEqual(msg.toolUseCalls.count, 1)
    }

    func testDefaultModels() {
        let anthropicModels = LLMModel.defaultModels(for: .anthropic)
        XCTAssertFalse(anthropicModels.isEmpty)
        XCTAssertTrue(anthropicModels.allSatisfy { $0.provider == .anthropic })

        let deepSeekModels = LLMModel.defaultModels(for: .deepSeek)
        XCTAssertFalse(deepSeekModels.isEmpty)
    }

    func testMCErrorDescriptions() {
        let error = MCError.apiKeyMissing(.anthropic)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Claude"))
    }
}
