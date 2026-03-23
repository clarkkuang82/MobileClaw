import XCTest
@testable import MCCore

final class MCCorePackageTests: XCTestCase {
    func testLLMProviderAllCases() {
        XCTAssertEqual(LLMProvider.allCases.count, 6)
    }

    func testContentBlockCodable() throws {
        let block = ContentBlock.text("Hello")
        let data = try JSONEncoder().encode(block)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)
        XCTAssertEqual(decoded.textValue, "Hello")
    }
}
