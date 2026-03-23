import Foundation
import MCCore
import MCNetworking

public struct SupervisorStrategy: OrchestrationStrategy {
    private let supervisorConfig: AgentConfig

    public init(supervisorConfig: AgentConfig) {
        self.supervisorConfig = supervisorConfig
    }

    public func execute(
        task: String,
        agents: [AgentRuntime],
        messageBus: AgentMessageBus
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let service = LLMServiceFactory.service(for: supervisorConfig.provider)

                    let workerDescriptions = agents.map { agent in
                        "- \(agent.config.name): \(agent.config.systemPrompt.prefix(200))"
                    }.joined(separator: "\n")

                    let supervisorPrompt = """
                    You are a supervisor coordinating multiple AI agents to complete a task.

                    Available workers:
                    \(workerDescriptions)

                    For each subtask, respond with JSON:
                    {"agent": "agent_name", "task": "subtask description"}

                    When all subtasks are done, respond with:
                    {"done": true, "summary": "final combined result"}

                    Be concise. Delegate effectively.
                    """

                    var supervisorMessages: [ChatMessage] = [.user(task)]
                    var iterations = 0
                    let maxIterations = agents.count * 2 + 2

                    continuation.yield(.started(agentID: supervisorConfig.id))

                    while iterations < maxIterations {
                        iterations += 1

                        let response = try await service.sendMessage(
                            messages: supervisorMessages,
                            model: supervisorConfig.model,
                            systemPrompt: supervisorPrompt,
                            tools: nil,
                            maxTokens: 2048
                        )
                        supervisorMessages.append(response)

                        let text = response.textContent

                        if let data = text.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                            if json["done"] as? Bool == true {
                                let summary = json["summary"] as? String ?? text
                                continuation.yield(.completed(agentID: supervisorConfig.id, result: summary))
                                break
                            }

                            if let agentName = json["agent"] as? String,
                               let subtask = json["task"] as? String,
                               let worker = agents.first(where: { $0.config.name == agentName }) {

                                continuation.yield(.streaming(
                                    agentID: supervisorConfig.id,
                                    text: "Delegating to \(agentName): \(subtask)"
                                ))

                                var workerResult = ""
                                for try await event in worker.run(task: subtask) {
                                    continuation.yield(event)
                                    if case .completed(_, let result) = event {
                                        workerResult = result
                                    }
                                }

                                await messageBus.publish(from: worker.config.id, message: workerResult)
                                supervisorMessages.append(.user("Result from \(agentName): \(workerResult)"))
                            }
                        } else {
                            continuation.yield(.completed(agentID: supervisorConfig.id, result: text))
                            break
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
