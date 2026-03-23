import Foundation
import KeychainAccess
import MCCore

public final class APIKeyStore: Sendable {
    private let keychain: Keychain

    public static let shared = APIKeyStore()

    private init() {
        keychain = Keychain(service: "com.mobileclaw.apikeys")
            .accessibility(.whenUnlocked)
    }

    public func apiKey(for provider: LLMProvider) -> String? {
        try? keychain.get(provider.rawValue)
    }

    public func setAPIKey(_ key: String, for provider: LLMProvider) throws {
        try keychain.set(key, key: provider.rawValue)
    }

    public func removeAPIKey(for provider: LLMProvider) throws {
        try keychain.remove(provider.rawValue)
    }

    public func hasAPIKey(for provider: LLMProvider) -> Bool {
        apiKey(for: provider) != nil
    }

    public func setCustomBaseURL(_ url: String, for provider: LLMProvider) throws {
        try keychain.set(url, key: "\(provider.rawValue)_baseurl")
    }

    public func customBaseURL(for provider: LLMProvider) -> String? {
        try? keychain.get("\(provider.rawValue)_baseurl")
    }
}
