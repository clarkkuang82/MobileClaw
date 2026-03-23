import Foundation
import MCCore

public enum LLMServiceFactory {
    public static func service(for provider: LLMProvider) -> any LLMService {
        switch provider {
        case .anthropic:
            AnthropicService()
        case .openAI, .deepSeek, .qwen, .moonshot, .custom:
            OpenAICompatibleService(provider: provider)
        }
    }
}
