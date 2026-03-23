import XCTest
@testable import MCNetworking
import MCCore

final class MCNetworkingTests: XCTestCase {
    func testLLMServiceFactoryCreatesAnthropicService() {
        let service = LLMServiceFactory.service(for: .anthropic)
        XCTAssertEqual(service.provider, .anthropic)
    }

    func testLLMServiceFactoryCreatesOpenAICompatible() {
        let deepSeekService = LLMServiceFactory.service(for: .deepSeek)
        XCTAssertEqual(deepSeekService.provider, .deepSeek)

        let qwenService = LLMServiceFactory.service(for: .qwen)
        XCTAssertEqual(qwenService.provider, .qwen)

        let moonshotService = LLMServiceFactory.service(for: .moonshot)
        XCTAssertEqual(moonshotService.provider, .moonshot)
    }
}
