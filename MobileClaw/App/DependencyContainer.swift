import SwiftUI
import MCCore
import MCNetworking

struct ServiceKey: EnvironmentKey {
    static let defaultValue: LLMServiceProvider = LLMServiceProvider()
}

extension EnvironmentValues {
    var serviceProvider: LLMServiceProvider {
        get { self[ServiceKey.self] }
        set { self[ServiceKey.self] = newValue }
    }
}

@Observable
final class LLMServiceProvider {
    var currentProvider: LLMProvider = .anthropic
    var currentModel: LLMModel = .claudeSonnet

    func service() -> any LLMService {
        LLMServiceFactory.service(for: currentProvider)
    }

    func service(for provider: LLMProvider) -> any LLMService {
        LLMServiceFactory.service(for: provider)
    }
}
