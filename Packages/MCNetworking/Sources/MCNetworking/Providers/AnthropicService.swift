import Foundation
import MCCore

public final class AnthropicService: LLMService, @unchecked Sendable {
    public let provider: LLMProvider = .anthropic
    private let apiKeyStore: APIKeyStore
    private let lock = NSLock()
    private var _currentTask: Task<Void, Never>?

    private var currentTask: Task<Void, Never>? {
        get { lock.withLock { _currentTask } }
        set { lock.withLock { _currentTask = newValue } }
    }

    public init(apiKeyStore: APIKeyStore = .shared) {
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
                switch delta {
                case .text(let text):
                    fullText += text
                case .toolInput(let json):
                    if !toolCalls.isEmpty {
                        toolCalls[toolCalls.count - 1].args += json
                    }
                case .thinking:
                    break
                }
            case .contentBlockStart(_, let type):
                if case .toolUse(let id, let name) = type {
                    toolCalls.append((id: id, name: name, args: ""))
                }
            default:
                break
            }
        }

        var content: [ContentBlock] = []
        if !fullText.isEmpty {
            content.append(.text(fullText))
        }
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
                    guard let apiKey = self.apiKeyStore.apiKey(for: .anthropic) else {
                        throw MCError.apiKeyMissing(.anthropic)
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

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    public func availableModels() async throws -> [LLMModel] {
        LLMModel.defaultModels(for: .anthropic)
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
        var url = LLMProvider.anthropic.defaultBaseURL
        url.appendPathComponent("v1/messages")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 120

        var body: [String: Any] = [
            "model": model.id,
            "max_tokens": maxTokens,
            "stream": true,
        ]

        if let systemPrompt, !systemPrompt.isEmpty {
            body["system"] = systemPrompt
        }

        // Filter out system messages (handled via system prompt) and build API messages
        let apiMessages = messages.filter { $0.role != .system }
        body["messages"] = apiMessages.map { message -> [String: Any] in
            var msg: [String: Any] = ["role": message.role.rawValue]
            var contentArray: [[String: Any]] = []

            for block in message.content {
                switch block {
                case .text(let text):
                    contentArray.append(["type": "text", "text": text])
                case .image(let img):
                    contentArray.append([
                        "type": "image",
                        "source": [
                            "type": img.type.rawValue,
                            "media_type": img.mediaType,
                            "data": img.data,
                        ],
                    ])
                case .toolUse(let toolUse):
                    var args: Any = [String: Any]()
                    if let data = toolUse.argumentsJSON.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) {
                        args = json
                    }
                    contentArray.append([
                        "type": "tool_use",
                        "id": toolUse.id,
                        "name": toolUse.name,
                        "input": args,
                    ])
                case .toolResult(let result):
                    // Anthropic requires tool_result in user messages
                    contentArray.append([
                        "type": "tool_result",
                        "tool_use_id": result.toolUseId,
                        "content": result.content,
                    ])
                case .thinking:
                    // Don't re-send thinking blocks to the API
                    break
                }
            }

            msg["content"] = contentArray
            return msg
        }

        if let tools, !tools.isEmpty {
            body["tools"] = tools.map { tool -> [String: Any] in
                var schema: Any = [String: Any]()
                if let data = tool.inputSchemaJSON.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) {
                    schema = json
                }
                return [
                    "name": tool.name,
                    "description": tool.description,
                    "input_schema": schema,
                ]
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseSSEEvent(_ sseEvent: SSEEvent) -> [StreamEvent] {
        guard let eventType = sseEvent.event else { return [] }
        guard let data = sseEvent.data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        switch eventType {
        case "message_start":
            let message = json["message"] as? [String: Any]
            return [.messageStart(
                messageID: message?["id"] as? String,
                model: message?["model"] as? String
            )]

        case "content_block_start":
            let index = json["index"] as? Int ?? 0
            let contentBlock = json["content_block"] as? [String: Any]
            let type = contentBlock?["type"] as? String

            switch type {
            case "tool_use":
                let id = contentBlock?["id"] as? String ?? ""
                let name = contentBlock?["name"] as? String ?? ""
                return [.contentBlockStart(index: index, type: .toolUse(id: id, name: name))]
            case "thinking":
                return [.contentBlockStart(index: index, type: .thinking)]
            default:
                return [.contentBlockStart(index: index, type: .text)]
            }

        case "content_block_delta":
            let index = json["index"] as? Int ?? 0
            let delta = json["delta"] as? [String: Any]
            let deltaType = delta?["type"] as? String

            switch deltaType {
            case "text_delta":
                let text = delta?["text"] as? String ?? ""
                return [.contentBlockDelta(index: index, delta: .text(text))]
            case "input_json_delta":
                let partial = delta?["partial_json"] as? String ?? ""
                return [.contentBlockDelta(index: index, delta: .toolInput(partial))]
            case "thinking_delta":
                let text = delta?["thinking"] as? String ?? ""
                return [.contentBlockDelta(index: index, delta: .thinking(text))]
            default:
                return []
            }

        case "content_block_stop":
            let index = json["index"] as? Int ?? 0
            return [.contentBlockStop(index: index)]

        case "message_delta":
            let delta = json["delta"] as? [String: Any]
            let stopReason = (delta?["stop_reason"] as? String).flatMap { StreamEvent.StopReason(rawValue: $0) }
            let usage = json["usage"] as? [String: Any]
            var events: [StreamEvent] = []
            if let usage {
                events.append(.usage(
                    inputTokens: usage["input_tokens"] as? Int,
                    outputTokens: usage["output_tokens"] as? Int
                ))
            }
            events.append(.messageStop(stopReason: stopReason))
            return events

        case "message_stop":
            return []

        case "error":
            let error = json["error"] as? [String: Any]
            let message = error?["message"] as? String ?? "Unknown error"
            return [.error(.apiError(statusCode: 0, message: message))]

        default:
            return []
        }
    }
}
