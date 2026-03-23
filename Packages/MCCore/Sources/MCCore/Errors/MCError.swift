import Foundation

public enum MCError: Error, Sendable, LocalizedError {
    case apiKeyMissing(LLMProvider)
    case networkError(String)
    case apiError(statusCode: Int, message: String)
    case streamingError(String)
    case decodingError(String)
    case rateLimited(retryAfter: TimeInterval?)
    case contextWindowExceeded(maxTokens: Int)
    case toolCallFailed(toolName: String, message: String)
    case mcpConnectionFailed(serverName: String, message: String)
    case agentError(String)
    case cancelled
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .apiKeyMissing(let provider):
            "API key missing for \(provider.displayName)"
        case .networkError(let msg):
            "Network error: \(msg)"
        case .apiError(let code, let msg):
            "API error (\(code)): \(msg)"
        case .streamingError(let msg):
            "Streaming error: \(msg)"
        case .decodingError(let msg):
            "Decoding error: \(msg)"
        case .rateLimited(let retry):
            if let retry { "Rate limited. Retry after \(Int(retry))s" }
            else { "Rate limited. Please try again later." }
        case .contextWindowExceeded(let max):
            "Context window exceeded (max: \(max) tokens)"
        case .toolCallFailed(let name, let msg):
            "Tool '\(name)' failed: \(msg)"
        case .mcpConnectionFailed(let name, let msg):
            "MCP server '\(name)' connection failed: \(msg)"
        case .agentError(let msg):
            "Agent error: \(msg)"
        case .cancelled:
            "Request cancelled"
        case .unknown(let msg):
            msg
        }
    }
}
