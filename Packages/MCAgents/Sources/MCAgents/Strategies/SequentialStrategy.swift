import Foundation

public struct SequentialStrategy: OrchestrationStrategy {
    public init() {}

    public func execute(
        task: String,
        agents: [AgentRuntime],
        messageBus: AgentMessageBus
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var currentInput = task

                for agent in agents {
                    var agentResult = ""
                    for try await event in agent.run(task: currentInput) {
                        continuation.yield(event)
                        if case .completed(_, let result) = event {
                            agentResult = result
                        }
                    }
                    await messageBus.publish(from: agent.config.id, message: agentResult)
                    currentInput = agentResult
                }

                continuation.finish()
            }
        }
    }
}
