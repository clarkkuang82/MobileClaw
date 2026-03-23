import XCTest
@testable import MCAgents
import MCCore

final class AgentMessageBusTests: XCTestCase {
    func testPublishAndSubscribe() async {
        let bus = AgentMessageBus()
        let stream = await bus.subscribe(agentID: "listener")

        await bus.publish(from: "sender", message: "Hello from sender")

        var receivedMessages: [AgentMessage] = []
        for await msg in stream {
            receivedMessages.append(msg)
            break // just get one
        }

        XCTAssertEqual(receivedMessages.count, 1)
        XCTAssertEqual(receivedMessages[0].fromAgentID, "sender")
        XCTAssertEqual(receivedMessages[0].content, "Hello from sender")
    }

    func testPublisherDoesNotReceiveOwnMessages() async {
        let bus = AgentMessageBus()

        // Subscribe agent A
        let streamA = await bus.subscribe(agentID: "agentA")

        // Agent A publishes (should not receive its own message)
        await bus.publish(from: "agentA", message: "My own message")

        // Agent B publishes (agent A should receive this)
        await bus.publish(from: "agentB", message: "From B")

        var messages: [AgentMessage] = []
        for await msg in streamA {
            messages.append(msg)
            break
        }

        XCTAssertEqual(messages.first?.fromAgentID, "agentB")
    }

    func testClear() async {
        let bus = AgentMessageBus()
        _ = await bus.subscribe(agentID: "agent1")
        _ = await bus.subscribe(agentID: "agent2")
        await bus.clear()
        // No crash = success
    }
}

final class AgentConfigTests: XCTestCase {
    func testDefaultValues() {
        let config = AgentConfig(name: "Test", systemPrompt: "You are a test agent")
        XCTAssertEqual(config.name, "Test")
        XCTAssertEqual(config.provider, .anthropic)
        XCTAssertEqual(config.maxIterations, 10)
        XCTAssertTrue(config.tools.isEmpty)
    }

    func testCustomValues() {
        let config = AgentConfig(
            name: "Researcher",
            systemPrompt: "Research assistant",
            provider: .deepSeek,
            model: .deepSeekChat,
            maxIterations: 5
        )
        XCTAssertEqual(config.provider, .deepSeek)
        XCTAssertEqual(config.model.id, "deepseek-chat")
        XCTAssertEqual(config.maxIterations, 5)
    }
}
