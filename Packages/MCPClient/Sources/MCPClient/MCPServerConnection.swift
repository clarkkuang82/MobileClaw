import Foundation
import MCCore

public actor MCPServerConnection {
    public let id: String
    public let name: String
    public let config: MCPServerConfig
    private(set) public var isConnected: Bool = false
    private(set) public var discoveredTools: [ToolDefinition] = []
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var pendingRequests: [String: CheckedContinuation<Any, Error>] = [:]
    private var requestID: Int = 0
    private var readBuffer = Data()

    public init(id: String = UUID().uuidString, name: String, config: MCPServerConfig) {
        self.id = id
        self.name = name
        self.config = config
    }

    public func connect() async throws {
        switch config.transport {
        case .stdio(let command, let args, let env):
            #if os(macOS)
            try await connectStdio(command: command, arguments: args, environment: env)
            #else
            throw MCError.mcpConnectionFailed(serverName: name, message: "Stdio transport not supported on iOS")
            #endif
        case .sse(let url):
            try await connectSSE(url: url)
        }
    }

    public func disconnect() async {
        #if os(macOS)
        process?.terminate()
        process = nil
        #endif
        inputPipe = nil
        outputPipe = nil
        isConnected = false
        discoveredTools = []
        pendingRequests.removeAll()
    }

    public func listTools() async throws -> [ToolDefinition] {
        guard isConnected else {
            throw MCError.mcpConnectionFailed(serverName: name, message: "Not connected")
        }
        let result = try await sendRequest(method: "tools/list", params: [:])
        guard let dict = result as? [String: Any],
              let toolsArray = dict["tools"] as? [[String: Any]] else {
            return []
        }

        discoveredTools = toolsArray.compactMap { toolDict -> ToolDefinition? in
            guard let name = toolDict["name"] as? String,
                  let description = toolDict["description"] as? String else { return nil }
            let schema: String
            if let inputSchema = toolDict["inputSchema"],
               let data = try? JSONSerialization.data(withJSONObject: inputSchema),
               let str = String(data: data, encoding: .utf8) {
                schema = str
            } else {
                schema = "{}"
            }
            return ToolDefinition(name: name, description: description, inputSchemaJSON: schema, serverID: id)
        }
        return discoveredTools
    }

    public func callTool(name: String, argumentsJSON: String) async throws -> ToolResult {
        guard isConnected else {
            throw MCError.mcpConnectionFailed(serverName: self.name, message: "Not connected")
        }
        var args: Any = [String: Any]()
        if let data = argumentsJSON.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) {
            args = json
        }
        let params: [String: Any] = ["name": name, "arguments": args]
        let result = try await sendRequest(method: "tools/call", params: params)

        if let dict = result as? [String: Any],
           let content = dict["content"] as? [[String: Any]] {
            let text = content.compactMap { $0["text"] as? String }.joined(separator: "\n")
            let isError = dict["isError"] as? Bool ?? false
            return ToolResult(content: text, isError: isError)
        }
        return ToolResult(content: String(describing: result))
    }

    // MARK: - JSON-RPC over Stdio

    #if os(macOS)
    private func connectStdio(command: String, arguments: [String], environment: [String: String]?) async throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: command)
        proc.arguments = arguments
        if let env = environment {
            var fullEnv = ProcessInfo.processInfo.environment
            for (k, v) in env { fullEnv[k] = v }
            proc.environment = fullEnv
        }

        let inPipe = Pipe()
        let outPipe = Pipe()
        proc.standardInput = inPipe
        proc.standardOutput = outPipe
        proc.standardError = FileHandle.nullDevice

        self.process = proc
        self.inputPipe = inPipe
        self.outputPipe = outPipe

        try proc.run()
        isConnected = true

        // Start reading responses
        Task { [weak self] in
            guard let self else { return }
            let handle = outPipe.fileHandleForReading
            for try await data in handle.bytes(forStream: outPipe) {
                await self.handleIncomingData(data)
            }
        }

        // Send initialize
        _ = try await sendRequest(method: "initialize", params: [
            "protocolVersion": "2024-11-05",
            "capabilities": [:],
            "clientInfo": ["name": "MobileClaw", "version": "1.0.0"],
        ] as [String: Any])

        // Send initialized notification
        sendNotification(method: "notifications/initialized", params: [:])
    }
    #endif

    private func connectSSE(url: URL) async throws {
        // SSE transport - simplified for Phase 3
        // Full implementation would use SSE for server→client and POST for client→server
        throw MCError.mcpConnectionFailed(serverName: name, message: "SSE transport coming soon")
    }

    private func sendRequest(method: String, params: [String: Any]) async throws -> Any {
        requestID += 1
        let id = requestID
        let message: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params,
        ]

        let data = try JSONSerialization.data(withJSONObject: message)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw MCError.mcpConnectionFailed(serverName: name, message: "Failed to encode request")
        }

        let header = "Content-Length: \(data.count)\r\n\r\n"

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests["\(id)"] = continuation
            if let pipe = inputPipe {
                let fullMessage = header + jsonString
                pipe.fileHandleForWriting.write(fullMessage.data(using: .utf8)!)
            } else {
                continuation.resume(throwing: MCError.mcpConnectionFailed(serverName: name, message: "No pipe"))
                pendingRequests.removeValue(forKey: "\(id)")
            }
        }
    }

    private func sendNotification(method: String, params: [String: Any]) {
        let message: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        let header = "Content-Length: \(data.count)\r\n\r\n"
        inputPipe?.fileHandleForWriting.write((header + jsonString).data(using: .utf8)!)
    }

    private func handleIncomingData(_ byte: UInt8) {
        readBuffer.append(byte)

        // Look for complete JSON-RPC messages (Content-Length header + body)
        guard let str = String(data: readBuffer, encoding: .utf8),
              let headerEnd = str.range(of: "\r\n\r\n") else { return }

        let header = String(str[str.startIndex..<headerEnd.lowerBound])
        guard let lengthStr = header.components(separatedBy: "Content-Length: ").last,
              let length = Int(lengthStr.trimmingCharacters(in: .whitespaces)) else { return }

        let bodyStart = str[headerEnd.upperBound...]
        guard bodyStart.utf8.count >= length else { return }

        let bodyStr = String(bodyStart.prefix(length))
        readBuffer = Data(String(bodyStart.dropFirst(length)).utf8)

        // Parse JSON-RPC response
        guard let data = bodyStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let id = json["id"], let idStr = "\(id)" as String? {
            if let result = json["result"] {
                pendingRequests[idStr]?.resume(returning: result)
            } else if let error = json["error"] as? [String: Any] {
                let msg = error["message"] as? String ?? "Unknown MCP error"
                pendingRequests[idStr]?.resume(throwing: MCError.toolCallFailed(toolName: "", message: msg))
            }
            pendingRequests.removeValue(forKey: idStr)
        }
    }
}

// Helper for reading bytes from pipe
#if os(macOS)
extension FileHandle {
    func bytes(forStream pipe: Pipe) -> AsyncStream<UInt8> {
        AsyncStream { continuation in
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    continuation.finish()
                } else {
                    for byte in data {
                        continuation.yield(byte)
                    }
                }
            }
            continuation.onTermination = { _ in
                pipe.fileHandleForReading.readabilityHandler = nil
            }
        }
    }
}
#endif

public struct MCPServerConfig: Codable, Sendable {
    public let transport: MCPTransport

    public init(transport: MCPTransport) {
        self.transport = transport
    }
}

public enum MCPTransport: Codable, Sendable {
    case stdio(command: String, arguments: [String], environment: [String: String]?)
    case sse(url: URL)
}
