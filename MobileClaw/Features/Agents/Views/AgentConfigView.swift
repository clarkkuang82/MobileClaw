import SwiftUI
import SwiftData
import MCCore
import MCPersistence

struct AgentConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var systemPrompt = ""
    @State private var provider: LLMProvider = .anthropic
    @State private var modelID = "claude-sonnet-4-20250514"
    @State private var temperature = 0.7
    @State private var maxTokens = 4096

    var editingAgent: AgentEntity?

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Agent Name", text: $name)
                    TextField("System Prompt", text: $systemPrompt, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Model") {
                    Picker("Provider", selection: $provider) {
                        ForEach(LLMProvider.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }

                    Picker("Model", selection: $modelID) {
                        ForEach(LLMModel.defaultModels(for: provider)) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                }

                Section("Parameters") {
                    HStack {
                        Text("Temperature: \(temperature, specifier: "%.1f")")
                        Slider(value: $temperature, in: 0...2, step: 0.1)
                    }

                    Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 256...32000, step: 256)
                }
            }
            .navigationTitle(editingAgent == nil ? "New Agent" : "Edit Agent")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || systemPrompt.isEmpty)
                }
            }
            .onAppear {
                if let agent = editingAgent {
                    name = agent.name
                    systemPrompt = agent.systemPrompt
                    provider = LLMProvider(rawValue: agent.providerRawValue) ?? .anthropic
                    modelID = agent.modelID
                    temperature = agent.temperature
                    maxTokens = agent.maxTokens
                }
            }
        }
    }

    private func save() {
        let agent = editingAgent ?? AgentEntity(name: name, systemPrompt: systemPrompt)
        agent.name = name
        agent.systemPrompt = systemPrompt
        agent.providerRawValue = provider.rawValue
        agent.modelID = modelID
        agent.temperature = temperature
        agent.maxTokens = maxTokens
        agent.updatedAt = Date()

        if editingAgent == nil {
            modelContext.insert(agent)
        }
        try? modelContext.save()
        dismiss()
    }
}
