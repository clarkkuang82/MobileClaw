import Foundation

public enum StreamEvent: Sendable {
    case contentBlockStart(index: Int, type: ContentBlockType)
    case contentBlockDelta(index: Int, delta: ContentDelta)
    case contentBlockStop(index: Int)
    case messageStart(messageID: String?, model: String?)
    case messageStop(stopReason: StopReason?)
    case usage(inputTokens: Int?, outputTokens: Int?)
    case error(MCError)

    public enum ContentBlockType: Sendable {
        case text
        case toolUse(id: String, name: String)
        case thinking
    }

    public enum ContentDelta: Sendable {
        case text(String)
        case toolInput(String)
        case thinking(String)
    }

    public enum StopReason: String, Sendable {
        case endTurn = "end_turn"
        case toolUse = "tool_use"
        case maxTokens = "max_tokens"
        case stop
    }
}
