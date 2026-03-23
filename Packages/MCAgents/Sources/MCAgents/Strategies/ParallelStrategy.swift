import Foundation

public struct ParallelStrategy: OrchestrationStrategy {
    public init() {}

    public func execute(
        task: String,
        agents: [AgentRuntime],
        messageBus: AgentMessageBus
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                await withTaskGroup(of: Void.self) { group in
                    for agent in agents {
                        group.addTask {
                            do {
                                for try await event in agent.run(task: task) {
                                    continuation.yield(event)
                                    if case .completed(_, let result) = event {
                                        await messageBus.publish(from: agent.config.id, message: result)
                                    }
                                }
                            } catch {
                                continuation.yield(.error(agentID: agent.config.id, error: error.localizedDescription))
                            }
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
}
