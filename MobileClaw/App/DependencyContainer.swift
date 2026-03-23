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

    private var cachedServices: [LLMProvider: any LLMService] = [:]

    func service() -> any LLMService {
        service(for: currentProvider)
    }

    func service(for provider: LLMProvider) -> any LLMService {
        if let existing = cachedServices[provider] {
            return existing
        }
        let svc = LLMServiceFactory.service(for: provider)
        cachedServices[provider] = svc
        return svc
    }
}
