import Foundation
import MCCore
import MCNetworking
import MCPClient

public struct AgentConfig: Sendable {
    public let id: String
    public let name: String
    public let systemPrompt: String
    public let provider: LLMProvider
    public let model: LLMModel
    public let tools: [ToolDefinition]
    public let maxIterations: Int

    public init(
        id: String = UUID().uuidString,
        name: String,
        systemPrompt: String,
        provider: LLMProvider = .anthropic,
        model: LLMModel = .claudeSonnet,
        tools: [ToolDefinition] = [],
        maxIterations: Int = 10
    ) {
        self.id = id
        self.name = name
        self.systemPrompt = systemPrompt
        self.provider = provider
        self.model = model
        self.tools = tools
        self.maxIterations = maxIterations
    }
}

public enum AgentEvent: Sendable {
    case started(agentID: String)
    case streaming(agentID: String, text: String)
    case toolCall(agentID: String, toolName: String)
    case toolResult(agentID: String, toolName: String, result: String)
    case completed(agentID: String, result: String)
    case error(agentID: String, error: String)
}

public final class AgentRuntime: Sendable {
    public let config: AgentConfig
    private let service: any LLMService

    public init(config: AgentConfig) {
        self.config = config
        self.service = LLMServiceFactory.service(for: config.provider)
    }

    public func run(task: String) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    continuation.yield(.started(agentID: config.id))
                    // Local messages array - no shared mutable state
                    var messages: [ChatMessage] = [.user(task)]
                    var iteration = 0
                    var finalResult = ""

                    while iteration < config.maxIterations {
                        iteration += 1

                        let response = try await service.sendMessage(
                            messages: messages,
                            model: config.model,
                            systemPrompt: config.systemPrompt,
                            tools: config.tools.isEmpty ? nil : config.tools,
                            maxTokens: config.model.maxOutputTokens
                        )

                        messages.append(response)

                        if response.hasToolUse {
                            for toolUse in response.toolUseCalls {
                                continuation.yield(.toolCall(agentID: config.id, toolName: toolUse.name))

                                let result: ToolResult
                                do {
                                    result = try await MCPManager.shared.callTool(
                                        name: toolUse.name,
                                        argumentsJSON: toolUse.argumentsJSON
                                    )
                                } catch {
                                    result = ToolResult(content: "Error: \(error.localizedDescription)", isError: true)
                                }

                                continuation.yield(.toolResult(
                                    agentID: config.id,
                                    toolName: toolUse.name,
                                    result: result.content
                                ))

                                messages.append(ChatMessage(
                                    role: .user,
                                    content: [.toolResult(ToolResultContent(
                                        toolUseId: toolUse.id,
                                        content: result.content,
                                        isError: result.isError
                                    ))]
                                ))
                            }
                        } else {
                            finalResult = response.textContent
                            continuation.yield(.streaming(agentID: config.id, text: finalResult))
                            break
                        }
                    }

                    continuation.yield(.completed(agentID: config.id, result: finalResult))
                    continuation.finish()
                } catch {
                    continuation.yield(.error(agentID: config.id, error: error.localizedDescription))
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
