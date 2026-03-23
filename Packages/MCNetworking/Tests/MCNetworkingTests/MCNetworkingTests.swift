import XCTest
@testable import MCNetworking
import MCCore

final class LLMServiceFactoryTests: XCTestCase {
    func testAllProvidersCreateService() {
        for provider in LLMProvider.allCases {
            let service = LLMServiceFactory.service(for: provider)
            XCTAssertEqual(service.provider, provider)
        }
    }

    func testAnthropicServiceType() {
        let service = LLMServiceFactory.service(for: .anthropic)
        XCTAssertTrue(service is AnthropicService)
    }

    func testOpenAICompatibleServiceType() {
        for provider in [LLMProvider.openAI, .deepSeek, .qwen, .moonshot, .custom] {
            let service = LLMServiceFactory.service(for: provider)
            XCTAssertTrue(service is OpenAICompatibleService, "\(provider) should use OpenAICompatibleService")
        }
    }
}

final class SSEBufferTests: XCTestCase {
    func testParsesSingleEvent() {
        let buffer = SSEBuffer()
        let events = buffer.append("event: message_start\ndata: {\"type\":\"message_start\"}\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].event, "message_start")
        XCTAssertEqual(events[0].data, "{\"type\":\"message_start\"}")
    }

    func testParsesMultipleEvents() {
        let buffer = SSEBuffer()
        let events = buffer.append("data: first\n\ndata: second\n\n")
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].data, "first")
        XCTAssertEqual(events[1].data, "second")
    }

    func testHandlesChunkedData() {
        let buffer = SSEBuffer()
        let events1 = buffer.append("event: delta\nda")
        XCTAssertTrue(events1.isEmpty)

        let events2 = buffer.append("ta: partial\n\n")
        XCTAssertEqual(events2.count, 1)
        XCTAssertEqual(events2[0].event, "delta")
        XCTAssertEqual(events2[0].data, "partial")
    }

    func testParsesEventWithID() {
        let buffer = SSEBuffer()
        let events = buffer.append("id: 123\nevent: test\ndata: hello\n\n")
        XCTAssertEqual(events[0].id, "123")
        XCTAssertEqual(events[0].event, "test")
    }

    func testMultiLineData() {
        let buffer = SSEBuffer()
        let events = buffer.append("data: line1\ndata: line2\n\n")
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].data, "line1\nline2")
    }

    func testIgnoresEmptyData() {
        let buffer = SSEBuffer()
        let events = buffer.append("\n\n")
        XCTAssertTrue(events.isEmpty)
    }
}
