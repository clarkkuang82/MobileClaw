import SwiftUI
import SwiftData
import MCCore
import MCNetworking
import MCPersistence
import MCPClient

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var streamingText: String = ""
    var thinkingText: String = ""
    var isStreaming: Bool = false
    var error: MCError?
    var activeToolCall: String?

    private(set) var conversation: ConversationEntity?
    private var currentTask: Task<Void, Never>?
    private var repository: ConversationRepository?
    private var serviceProvider: LLMServiceProvider?

    private let maxToolCallIterations = 10

    var currentProvider: LLMProvider {
        serviceProvider?.currentProvider ?? .anthropic
    }

    var currentModel: LLMModel {
        serviceProvider?.currentModel ?? .claudeSonnet
    }

    func setup(
        conversation: ConversationEntity,
        repository: ConversationRepository,
        serviceProvider: LLMServiceProvider
    ) {
        self.conversation = conversation
        self.repository = repository
        self.serviceProvider = serviceProvider
        loadMessages()
    }

    func loadMessages() {
        guard let conversation else { return }
        let entities = conversation.sortedMessages
        messages = entities.compactMap { entity -> ChatMessage? in
            guard let jsonString = entity.contentJSON,
                  let data = jsonString.data(using: .utf8),
                  let content = try? JSONDecoder().decode([ContentBlock].self, from: data) else {
                return nil
            }
            return ChatMessage(
                id: entity.id,
                role: ChatMessage.Role(rawValue: entity.role) ?? .user,
                content: content,
                createdAt: entity.createdAt,
                modelID: entity.modelID,
                tokenCount: entity.tokenCount
            )
        }
    }

    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isStreaming else { return }

        let userMessage = ChatMessage.user(text)
        messages.append(userMessage)
        persistMessage(userMessage)

        streamResponse()
    }

    func stopStreaming() {
        currentTask?.cancel()
        currentTask = nil
        isStreaming = false
        activeToolCall = nil

        if !streamingText.isEmpty {
            let assistantMessage = ChatMessage.assistant(streamingText, modelID: currentModel.id)
            messages.append(assistantMessage)
            persistMessage(assistantMessage)
            streamingText = ""
        }
    }

    private func streamResponse() {
        guard let serviceProvider else { return }

        isStreaming = true
        streamingText = ""
        thinkingText = ""
        activeToolCall = nil
        error = nil

        let service = serviceProvider.service()
        let model = serviceProvider.currentModel
        let systemPrompt = conversation?.systemPrompt

        currentTask = Task {
            do {
                var iteration = 0
                var shouldContinue = true

                while shouldContinue && iteration < maxToolCallIterations && !Task.isCancelled {
                    iteration += 1
                    shouldContinue = false

                    let tools = await MCPManager.shared.availableTools()
                    let messagesToSend = messages

                    var pendingToolCalls: [(id: String, name: String, args: String)] = []

                    let stream = service.streamMessage(
                        messages: messagesToSend,
                        model: model,
                        systemPrompt: systemPrompt,
                        tools: tools.isEmpty ? nil : tools,
                        maxTokens: model.maxOutputTokens
                    )

                    streamingText = ""
                    thinkingText = ""

                    for try await event in stream {
                        if Task.isCancelled { break }

                        switch event {
                        case .contentBlockDelta(_, let delta):
                            switch delta {
                            case .text(let text):
                                streamingText += text
                            case .toolInput(let json):
                                if !pendingToolCalls.isEmpty {
                                    pendingToolCalls[pendingToolCalls.count - 1].args += json
                                }
                            case .thinking(let text):
                                thinkingText += text
                            }

                        case .contentBlockStart(_, let type):
                            if case .toolUse(let id, let name) = type {
                                pendingToolCalls.append((id: id, name: name, args: ""))
                            }

                        case .messageStop(let reason):
                            if reason == .toolUse && !pendingToolCalls.isEmpty {
                                shouldContinue = true
                            }

                        case .error(let mcError):
                            self.error = mcError

                        default:
                            break
                        }
                    }

                    // Build assistant message with text + tool calls
                    if !streamingText.isEmpty || !thinkingText.isEmpty || !pendingToolCalls.isEmpty {
                        var content: [ContentBlock] = []
                        if !thinkingText.isEmpty {
                            content.append(.thinking(thinkingText))
                        }
                        if !streamingText.isEmpty {
                            content.append(.text(streamingText))
                        }
                        for tc in pendingToolCalls {
                            content.append(.toolUse(ToolUseContent(id: tc.id, name: tc.name, argumentsJSON: tc.args)))
                        }
                        let assistantMessage = ChatMessage(role: .assistant, content: content, modelID: model.id)
                        messages.append(assistantMessage)
                        persistMessage(assistantMessage)
                    }

                    // Execute tool calls if any
                    if shouldContinue && !pendingToolCalls.isEmpty {
                        var toolResults: [ContentBlock] = []

                        for tc in pendingToolCalls {
                            activeToolCall = tc.name
                            do {
                                let result = try await MCPManager.shared.callTool(
                                    name: tc.name,
                                    argumentsJSON: tc.args
                                )
                                toolResults.append(.toolResult(ToolResultContent(
                                    toolUseId: tc.id,
                                    content: result.content,
                                    isError: result.isError
                                )))
                            } catch {
                                toolResults.append(.toolResult(ToolResultContent(
                                    toolUseId: tc.id,
                                    content: "Error: \(error.localizedDescription)",
                                    isError: true
                                )))
                            }
                        }

                        // Add tool results as user message (Anthropic format)
                        let toolResultMessage = ChatMessage(role: .user, content: toolResults)
                        messages.append(toolResultMessage)
                        persistMessage(toolResultMessage)
                        activeToolCall = nil
                    }
                }

                streamingText = ""
                thinkingText = ""
                activeToolCall = nil
                isStreaming = false
            } catch {
                if !(error is CancellationError) {
                    self.error = .streamingError(error.localizedDescription)
                }
                isStreaming = false
                activeToolCall = nil
            }
        }
    }

    private func persistMessage(_ message: ChatMessage) {
        guard let conversation, let repository else { return }
        do {
            _ = try repository.addMessage(
                to: conversation,
                role: message.role.rawValue,
                content: message.content,
                modelID: message.modelID
            )
            try repository.save()
        } catch {
            self.error = .unknown("Failed to save message: \(error.localizedDescription)")
        }
    }
}
