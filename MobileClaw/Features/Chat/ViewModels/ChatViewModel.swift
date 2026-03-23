import SwiftUI
import SwiftData
import MCCore
import MCNetworking
import MCPersistence

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var streamingText: String = ""
    var thinkingText: String = ""
    var isStreaming: Bool = false
    var error: MCError?

    private(set) var conversation: ConversationEntity?
    private var currentTask: Task<Void, Never>?
    private var repository: ConversationRepository?
    private var serviceProvider: LLMServiceProvider?

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
        error = nil

        let service = serviceProvider.service()
        let model = serviceProvider.currentModel
        let systemPrompt = conversation?.systemPrompt
        let messagesToSend = messages

        currentTask = Task {
            do {
                var toolCallID = ""
                var toolCallName = ""
                var toolCallArgs = ""
                var hasToolUse = false

                let stream = service.streamMessage(
                    messages: messagesToSend,
                    model: model,
                    systemPrompt: systemPrompt,
                    tools: nil,
                    maxTokens: model.maxOutputTokens
                )

                for try await event in stream {
                    if Task.isCancelled { break }

                    switch event {
                    case .contentBlockDelta(_, let delta):
                        switch delta {
                        case .text(let text):
                            streamingText += text
                        case .toolInput(let json):
                            toolCallArgs += json
                        case .thinking(let text):
                            thinkingText += text
                        }

                    case .contentBlockStart(_, let type):
                        if case .toolUse(let id, let name) = type {
                            toolCallID = id
                            toolCallName = name
                            toolCallArgs = ""
                            hasToolUse = true
                        }

                    case .messageStop(let reason):
                        if reason == .toolUse && hasToolUse {
                            // Tool calling will be implemented in Phase 3
                        }

                    case .error(let mcError):
                        self.error = mcError

                    default:
                        break
                    }
                }

                if !streamingText.isEmpty || !self.thinkingText.isEmpty {
                    var content: [ContentBlock] = []
                    if !self.thinkingText.isEmpty {
                        content.append(.thinking(self.thinkingText))
                    }
                    if !streamingText.isEmpty {
                        content.append(.text(streamingText))
                    }
                    let assistantMessage = ChatMessage(
                        role: .assistant, content: content, modelID: model.id
                    )
                    messages.append(assistantMessage)
                    persistMessage(assistantMessage)
                }

                streamingText = ""
                self.thinkingText = ""
                isStreaming = false
            } catch {
                if !(error is CancellationError) {
                    self.error = .streamingError(error.localizedDescription)
                }
                isStreaming = false
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
