import Foundation
import MCCore

public final class OpenAICompatibleService: LLMService, @unchecked Sendable {
    public let provider: LLMProvider
    private let apiKeyStore: APIKeyStore
    private let lock = NSLock()
    private var _currentTask: Task<Void, Never>?

    private var currentTask: Task<Void, Never>? {
        get { lock.withLock { _currentTask } }
        set { lock.withLock { _currentTask = newValue } }
    }

    public init(provider: LLMProvider, apiKeyStore: APIKeyStore = .shared) {
        precondition(provider.isOpenAICompatible, "\(provider) is not OpenAI-compatible")
        self.provider = provider
        self.apiKeyStore = apiKeyStore
    }

    public func sendMessage(
        messages: [ChatMessage],
        model: LLMModel,
        systemPrompt: String?,
        tools: [ToolDefinition]?,
        maxTokens: Int
    ) async throws -> ChatMessage {
        var fullText = ""
        var toolCalls: [(id: String, name: String, args: String)] = []

        for try await event in streamMessage(
            messages: messages,
            model: model,
            systemPrompt: systemPrompt,
            tools: tools,
            maxTokens: maxTokens
        ) {
            switch event {
            case .contentBlockDelta(_, let delta):
                if case .text(let text) = delta { fullText += text }
                if case .toolInput(let json) = delta {
                    if !toolCalls.isEmpty {
                        toolCalls[toolCalls.count - 1].args += json
                    }
                }
            case .contentBlockStart(_, let type):
                if case .toolUse(let id, let name) = type {
                    toolCalls.append((id: id, name: name, args: ""))
                }
            default: break
            }
        }

        var content: [ContentBlock] = []
        if !fullText.isEmpty { content.append(.text(fullText)) }
        for tc in toolCalls {
            content.append(.toolUse(ToolUseContent(id: tc.id, name: tc.name, argumentsJSON: tc.args)))
        }

        return ChatMessage(role: .assistant, content: content, modelID: model.id)
    }

    public func streamMessage(
        messages: [ChatMessage],
        model: LLMModel,
        systemPrompt: String?,
        tools: [ToolDefinition]?,
        maxTokens: Int
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let apiKey = self.apiKeyStore.apiKey(for: self.provider) else {
                        throw MCError.apiKeyMissing(self.provider)
                    }

                    let request = try self.buildRequest(
                        messages: messages,
                        model: model,
                        systemPrompt: systemPrompt,
                        tools: tools,
                        maxTokens: maxTokens,
                        apiKey: apiKey
                    )

                    for try await sseEvent in SSEClientFactory.stream(request: request) {
                        if Task.isCancelled { break }
                        if sseEvent.data == "[DONE]" {
                            continuation.yield(.messageStop(stopReason: .endTurn))
                            break
                        }
                        let events = self.parseSSEEvent(sseEvent)
                        for event in events {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            self.currentTask = task
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    public func availableModels() async throws -> [LLMModel] {
        LLMModel.defaultModels(for: provider)
    }

    // MARK: - Private

    private func buildRequest(
        messages: [ChatMessage],
        model: LLMModel,
        systemPrompt: String?,
        tools: [ToolDefinition]?,
        maxTokens: Int,
        apiKey: String
    ) throws -> URLRequest {
        let baseURL: URL
        if let custom = apiKeyStore.customBaseURL(for: provider),
           let url = URL(string: custom) {
            baseURL = url
        } else {
            baseURL = provider.defaultBaseURL
        }

        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120

        var openAIMessages: [[String: Any]] = []

        // Add system prompt (only once - skip .system role messages if systemPrompt provided)
        if let systemPrompt, !systemPrompt.isEmpty {
            openAIMessages.append(["role": "system", "content": systemPrompt])
        }

        for msg in messages {
            switch msg.role {
            case .system:
                // Only add system messages from the array if no explicit systemPrompt was provided
                if systemPrompt == nil || systemPrompt?.isEmpty == true {
                    openAIMessages.append(["role": "system", "content": msg.textContent])
                }
            case .user:
                // Handle tool results from user role
                if msg.content.contains(where: { if case .toolResult = $0 { return true }; return false }) {
                    for block in msg.content {
                        if case .toolResult(let result) = block {
                            openAIMessages.append([
                                "role": "tool",
                                "tool_call_id": result.toolUseId,
                                "content": result.content,
                            ])
                        }
                    }
                } else {
                    openAIMessages.append(["role": "user", "content": msg.textContent])
                }
            case .assistant:
                var assistantMsg: [String: Any] = ["role": "assistant"]
                let text = msg.textContent
                assistantMsg["content"] = text.isEmpty ? NSNull() : text
                let toolUseCalls = msg.toolUseCalls
                if !toolUseCalls.isEmpty {
                    assistantMsg["tool_calls"] = toolUseCalls.map { tc -> [String: Any] in
                        [
                            "id": tc.id,
                            "type": "function",
                            "function": [
                                "name": tc.name,
                                "arguments": tc.argumentsJSON,
                            ],
                        ]
                    }
                }
                openAIMessages.append(assistantMsg)
            }
        }

        var body: [String: Any] = [
            "model": model.id,
            "messages": openAIMessages,
            "max_tokens": maxTokens,
            "stream": true,
        ]

        if let tools, !tools.isEmpty {
            body["tools"] = tools.map { tool -> [String: Any] in
                [
                    "type": "function",
                    "function": [
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": (try? JSONSerialization.jsonObject(
                            with: tool.inputSchemaJSON.data(using: .utf8) ?? Data()
                        )) ?? [:],
                    ],
                ]
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseSSEEvent(_ sseEvent: SSEEvent) -> [StreamEvent] {
        guard let data = sseEvent.data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        var events: [StreamEvent] = []

        if let choices = json["choices"] as? [[String: Any]], let choice = choices.first {
            let delta = choice["delta"] as? [String: Any] ?? [:]
            let finishReason = choice["finish_reason"] as? String

            if let content = delta["content"] as? String, !content.isEmpty {
                events.append(.contentBlockDelta(index: 0, delta: .text(content)))
            }

            if let toolCalls = delta["tool_calls"] as? [[String: Any]] {
                for tc in toolCalls {
                    let index = tc["index"] as? Int ?? 0
                    if let function = tc["function"] as? [String: Any] {
                        if let name = function["name"] as? String {
                            let id = tc["id"] as? String ?? UUID().uuidString
                            events.append(.contentBlockStart(index: index, type: .toolUse(id: id, name: name)))
                        }
                        if let args = function["arguments"] as? String, !args.isEmpty {
                            events.append(.contentBlockDelta(index: index, delta: .toolInput(args)))
                        }
                    }
                }
            }

            if let reason = finishReason {
                let stopReason: StreamEvent.StopReason = reason == "tool_calls" ? .toolUse : .endTurn
                events.append(.messageStop(stopReason: stopReason))
            }
        }

        if let usage = json["usage"] as? [String: Any] {
            events.append(.usage(
                inputTokens: usage["prompt_tokens"] as? Int,
                outputTokens: usage["completion_tokens"] as? Int
            ))
        }

        return events
    }
}
