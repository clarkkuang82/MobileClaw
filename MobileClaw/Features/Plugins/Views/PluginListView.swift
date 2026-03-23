import SwiftUI
import MCCore

struct PluginListView: View {
    @State private var plugins: [PluginInfo] = PluginInfo.builtIn

    var body: some View {
        List {
            Section("Built-in Plugins") {
                ForEach(plugins) { plugin in
                    HStack(spacing: 12) {
                        Image(systemName: plugin.icon)
                            .font(.title3)
                            .foregroundStyle(plugin.isEnabled ? Color.accentColor : .secondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(plugin.name)
                                .fontWeight(.medium)
                            Text(plugin.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Toggle("", isOn: binding(for: plugin.id))
                            .labelsHidden()
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Text("More plugins coming in future updates")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .navigationTitle("Plugins")
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { plugins.first(where: { $0.id == id })?.isEnabled ?? false },
            set: { newValue in
                if let idx = plugins.firstIndex(where: { $0.id == id }) {
                    plugins[idx].isEnabled = newValue
                }
            }
        )
    }
}

struct PluginInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let version: String
    var isEnabled: Bool

    static let builtIn: [PluginInfo] = [
        PluginInfo(
            id: "web_search", name: "Web Search",
            description: "Search the web for up-to-date information",
            icon: "magnifyingglass", version: "1.0", isEnabled: true
        ),
        PluginInfo(
            id: "prompt_library", name: "Prompt Library",
            description: "Reusable prompt templates for common tasks",
            icon: "text.book.closed", version: "1.0", isEnabled: true
        ),
        PluginInfo(
            id: "code_highlighter", name: "Code Highlighter",
            description: "Syntax highlighting for code blocks in chat",
            icon: "chevron.left.forwardslash.chevron.right", version: "1.0", isEnabled: true
        ),
        PluginInfo(
            id: "translation", name: "Translation",
            description: "Translate messages between languages",
            icon: "globe", version: "1.0", isEnabled: false
        ),
    ]
}
