import Foundation

public protocol OrchestrationStrategy: Sendable {
    func execute(
        task: String,
        agents: [AgentRuntime],
        messageBus: AgentMessageBus
    ) -> AsyncThrowingStream<AgentEvent, Error>
}
