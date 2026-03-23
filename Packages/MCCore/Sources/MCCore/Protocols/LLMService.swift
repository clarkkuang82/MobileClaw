import Foundation

public protocol LLMService: Sendable {
    var provider: LLMProvider { get }

    func sendMessage(
        messages: [ChatMessage],
        model: LLMModel,
        systemPrompt: String?,
        tools: [ToolDefinition]?,
        maxTokens: Int
    ) async throws -> ChatMessage

    func streamMessage(
        messages: [ChatMessage],
        model: LLMModel,
        systemPrompt: String?,
        tools: [ToolDefinition]?,
        maxTokens: Int
    ) -> AsyncThrowingStream<StreamEvent, Error>

    func cancel()

    func availableModels() async throws -> [LLMModel]
}

// Default implementations
public extension LLMService {
    func sendMessage(
        messages: [ChatMessage],
        model: LLMModel,
        systemPrompt: String? = nil,
        tools: [ToolDefinition]? = nil,
        maxTokens: Int = 4096
    ) async throws -> ChatMessage {
        try await sendMessage(
            messages: messages,
            model: model,
            systemPrompt: systemPrompt,
            tools: tools,
            maxTokens: maxTokens
        )
    }

    func availableModels() async throws -> [LLMModel] {
        LLMModel.defaultModels(for: provider)
    }
}
