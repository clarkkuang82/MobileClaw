import SwiftUI
import MCCore
import MCNetworking

struct SettingsView: View {
    @Environment(\.serviceProvider) private var serviceProvider
    @State private var apiKeys: [LLMProvider: String] = [:]
    @State private var showingSaveConfirmation = false

    var body: some View {
        Form {
            Section("Current Model") {
                Picker("Provider", selection: Bindable(serviceProvider).currentProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                Picker("Model", selection: Bindable(serviceProvider).currentModel) {
                    ForEach(LLMModel.defaultModels(for: serviceProvider.currentProvider)) { model in
                        Text(model.name).tag(model)
                    }
                }
            }

            Section("API Keys") {
                ForEach(LLMProvider.allCases.filter { $0 != .custom }) { provider in
                    HStack {
                        Text(provider.displayName)
                        Spacer()
                        SecureField("API Key", text: binding(for: provider))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 280)
                    }
                }

                Button("Save API Keys") {
                    saveAPIKeys()
                    showingSaveConfirmation = true
                }
                .alert("Saved", isPresented: $showingSaveConfirmation) {
                    Button("OK") {}
                } message: {
                    Text("API keys saved to Keychain")
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "Phase 1")
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadAPIKeys)
    }

    private func binding(for provider: LLMProvider) -> Binding<String> {
        Binding(
            get: { apiKeys[provider] ?? "" },
            set: { apiKeys[provider] = $0 }
        )
    }

    private func loadAPIKeys() {
        let store = APIKeyStore.shared
        for provider in LLMProvider.allCases {
            apiKeys[provider] = store.apiKey(for: provider) ?? ""
        }
    }

    private func saveAPIKeys() {
        let store = APIKeyStore.shared
        for (provider, key) in apiKeys {
            if key.isEmpty {
                try? store.removeAPIKey(for: provider)
            } else {
                try? store.setAPIKey(key, for: provider)
            }
        }
    }
}
