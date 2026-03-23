import Foundation

public struct AgentMessage: Sendable {
    public let fromAgentID: String
    public let content: String
    public let timestamp: Date

    public init(fromAgentID: String, content: String, timestamp: Date = Date()) {
        self.fromAgentID = fromAgentID
        self.content = content
        self.timestamp = timestamp
    }
}

public actor AgentMessageBus {
    private var subscribers: [String: AsyncStream<AgentMessage>.Continuation] = [:]

    public init() {}

    public func subscribe(agentID: String) -> AsyncStream<AgentMessage> {
        AsyncStream { continuation in
            subscribers[agentID] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.unsubscribe(agentID: agentID) }
            }
        }
    }

    public func unsubscribe(agentID: String) {
        subscribers[agentID]?.finish()
        subscribers.removeValue(forKey: agentID)
    }

    public func publish(from agentID: String, message: String) {
        let msg = AgentMessage(fromAgentID: agentID, content: message)
        for (id, continuation) in subscribers where id != agentID {
            continuation.yield(msg)
        }
    }

    public func broadcast(message: AgentMessage) {
        for (_, continuation) in subscribers {
            continuation.yield(message)
        }
    }

    public func clear() {
        for (_, continuation) in subscribers {
            continuation.finish()
        }
        subscribers.removeAll()
    }
}
