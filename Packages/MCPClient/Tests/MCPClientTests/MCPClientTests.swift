import XCTest
@testable import MCPClient
import MCCore

final class MCPToolRegistryTests: XCTestCase {
    func testRegisterAndQueryTools() async {
        let registry = MCPToolRegistry()
        let tools = [
            ToolDefinition(name: "search", description: "Search the web", serverID: "s1"),
            ToolDefinition(name: "calculator", description: "Calculate math", serverID: "s1"),
        ]
        await registry.register(tools: tools, serverID: "s1")

        let all = await registry.allTools()
        XCTAssertEqual(all.count, 2)

        let search = await registry.tool(named: "search")
        XCTAssertNotNil(search)
        XCTAssertEqual(search?.name, "search")
    }

    func testUnregisterRemovesTools() async {
        let registry = MCPToolRegistry()
        let tools = [ToolDefinition(name: "test", description: "Test tool", serverID: "s1")]
        await registry.register(tools: tools, serverID: "s1")
        XCTAssertEqual(await registry.allTools().count, 1)

        await registry.unregister(serverID: "s1")
        XCTAssertEqual(await registry.allTools().count, 0)
    }

    func testServerIDLookup() async {
        let registry = MCPToolRegistry()
        await registry.register(tools: [
            ToolDefinition(name: "tool_a", description: "A", serverID: "server1"),
        ], serverID: "server1")
        await registry.register(tools: [
            ToolDefinition(name: "tool_b", description: "B", serverID: "server2"),
        ], serverID: "server2")

        let sid = await registry.serverID(forToolNamed: "tool_b")
        XCTAssertEqual(sid, "server2")
    }

    func testMultipleServersWithSameToolName() async {
        let registry = MCPToolRegistry()
        await registry.register(tools: [
            ToolDefinition(name: "search", description: "Server 1 search", serverID: "s1"),
        ], serverID: "s1")
        await registry.register(tools: [
            ToolDefinition(name: "search", description: "Server 2 search", serverID: "s2"),
        ], serverID: "s2")

        // Both should exist (different IDs due to serverID prefix)
        let all = await registry.allTools()
        XCTAssertEqual(all.count, 2)
    }
}

final class MCPServerConfigTests: XCTestCase {
    func testStdioConfigCreation() {
        let config = MCPServerConfig(transport: .stdio(
            command: "/usr/local/bin/node",
            arguments: ["server.js"],
            environment: ["API_KEY": "test"]
        ))
        if case .stdio(let cmd, let args, let env) = config.transport {
            XCTAssertEqual(cmd, "/usr/local/bin/node")
            XCTAssertEqual(args, ["server.js"])
            XCTAssertEqual(env?["API_KEY"], "test")
        } else {
            XCTFail("Expected stdio transport")
        }
    }

    func testSSEConfigCreation() {
        let config = MCPServerConfig(transport: .sse(url: URL(string: "https://mcp.example.com")!))
        if case .sse(let url) = config.transport {
            XCTAssertEqual(url.absoluteString, "https://mcp.example.com")
        } else {
            XCTFail("Expected SSE transport")
        }
    }
}
