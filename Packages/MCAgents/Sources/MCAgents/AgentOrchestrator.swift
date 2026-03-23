import Foundation
import MCCore

public final class AgentOrchestrator: Sendable {
    public static let shared = AgentOrchestrator()

    private init() {}

    public func run(
        task: String,
        agents: [AgentRuntime],
        strategy: any OrchestrationStrategy
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        // Create a fresh message bus per invocation to prevent cross-contamination
        let messageBus = AgentMessageBus()
        return strategy.execute(task: task, agents: agents, messageBus: messageBus)
    }

    public func runSequential(task: String, agents: [AgentRuntime]) -> AsyncThrowingStream<AgentEvent, Error> {
        run(task: task, agents: agents, strategy: SequentialStrategy())
    }

    public func runParallel(task: String, agents: [AgentRuntime]) -> AsyncThrowingStream<AgentEvent, Error> {
        run(task: task, agents: agents, strategy: ParallelStrategy())
    }

    public func runSupervisor(
        task: String,
        supervisor: AgentConfig,
        workers: [AgentRuntime]
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        let strategy = SupervisorStrategy(supervisorConfig: supervisor)
        return run(task: task, agents: workers, strategy: strategy)
    }
}
