import Foundation

public enum LLMProvider: String, Codable, CaseIterable, Sendable, Identifiable {
    case anthropic
    case openAI
    case deepSeek
    case qwen
    case moonshot
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .anthropic: "Claude (Anthropic)"
        case .openAI: "GPT (OpenAI)"
        case .deepSeek: "DeepSeek"
        case .qwen: "Qwen (通义千问)"
        case .moonshot: "Moonshot (月之暗面)"
        case .custom: "Custom"
        }
    }

    public var defaultBaseURL: URL {
        switch self {
        case .anthropic:
            URL(string: "https://api.anthropic.com")!
        case .openAI:
            URL(string: "https://api.openai.com/v1")!
        case .deepSeek:
            URL(string: "https://api.deepseek.com")!
        case .qwen:
            URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1")!
        case .moonshot:
            URL(string: "https://api.moonshot.cn/v1")!
        case .custom:
            URL(string: "https://localhost")!
        }
    }

    public var supportsVision: Bool {
        switch self {
        case .anthropic, .openAI, .qwen: true
        case .deepSeek, .moonshot, .custom: false
        }
    }

    public var supportsToolCalling: Bool {
        switch self {
        case .anthropic, .openAI, .deepSeek, .qwen, .moonshot: true
        case .custom: false
        }
    }

    public var isOpenAICompatible: Bool {
        switch self {
        case .openAI, .deepSeek, .qwen, .moonshot, .custom: true
        case .anthropic: false
        }
    }
}
