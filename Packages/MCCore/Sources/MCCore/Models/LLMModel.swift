import Foundation

public struct LLMModel: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let provider: LLMProvider
    public let contextWindow: Int
    public let maxOutputTokens: Int
    public let supportsVision: Bool
    public let supportsToolCalling: Bool

    public init(
        id: String,
        name: String,
        provider: LLMProvider,
        contextWindow: Int = 128_000,
        maxOutputTokens: Int = 4096,
        supportsVision: Bool = false,
        supportsToolCalling: Bool = true
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.contextWindow = contextWindow
        self.maxOutputTokens = maxOutputTokens
        self.supportsVision = supportsVision
        self.supportsToolCalling = supportsToolCalling
    }
}

// MARK: - Built-in Models

public extension LLMModel {
    static let claudeOpus = LLMModel(
        id: "claude-opus-4-20250514",
        name: "Claude Opus 4",
        provider: .anthropic,
        contextWindow: 200_000,
        maxOutputTokens: 32_000,
        supportsVision: true
    )

    static let claudeSonnet = LLMModel(
        id: "claude-sonnet-4-20250514",
        name: "Claude Sonnet 4",
        provider: .anthropic,
        contextWindow: 200_000,
        maxOutputTokens: 16_000,
        supportsVision: true
    )

    static let claudeHaiku = LLMModel(
        id: "claude-haiku-4-5-20251001",
        name: "Claude Haiku 4.5",
        provider: .anthropic,
        contextWindow: 200_000,
        maxOutputTokens: 8192,
        supportsVision: true
    )

    static let gpt4o = LLMModel(
        id: "gpt-4o",
        name: "GPT-4o",
        provider: .openAI,
        contextWindow: 128_000,
        maxOutputTokens: 16_384,
        supportsVision: true
    )

    static let gpt4oMini = LLMModel(
        id: "gpt-4o-mini",
        name: "GPT-4o Mini",
        provider: .openAI,
        contextWindow: 128_000,
        maxOutputTokens: 16_384,
        supportsVision: true
    )

    static let deepSeekChat = LLMModel(
        id: "deepseek-chat",
        name: "DeepSeek V3",
        provider: .deepSeek,
        contextWindow: 64_000,
        maxOutputTokens: 8192
    )

    static let deepSeekReasoner = LLMModel(
        id: "deepseek-reasoner",
        name: "DeepSeek R1",
        provider: .deepSeek,
        contextWindow: 64_000,
        maxOutputTokens: 8192
    )

    static let qwenMax = LLMModel(
        id: "qwen-max",
        name: "Qwen Max",
        provider: .qwen,
        contextWindow: 32_000,
        maxOutputTokens: 8192,
        supportsVision: true
    )

    static let qwenTurbo = LLMModel(
        id: "qwen-turbo",
        name: "Qwen Turbo",
        provider: .qwen,
        contextWindow: 128_000,
        maxOutputTokens: 8192
    )

    static let moonshotV1 = LLMModel(
        id: "moonshot-v1-128k",
        name: "Moonshot V1 128K",
        provider: .moonshot,
        contextWindow: 128_000,
        maxOutputTokens: 4096
    )

    static func defaultModels(for provider: LLMProvider) -> [LLMModel] {
        switch provider {
        case .anthropic: [.claudeOpus, .claudeSonnet, .claudeHaiku]
        case .openAI: [.gpt4o, .gpt4oMini]
        case .deepSeek: [.deepSeekChat, .deepSeekReasoner]
        case .qwen: [.qwenMax, .qwenTurbo]
        case .moonshot: [.moonshotV1]
        case .custom: []
        }
    }
}
