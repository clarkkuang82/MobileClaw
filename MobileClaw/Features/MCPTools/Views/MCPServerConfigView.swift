import SwiftUI
import MCPClient

struct MCPServerConfigView: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: () -> Void

    @State private var serverName = ""
    @State private var command = ""
    @State private var arguments = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Info") {
                    TextField("Server Name", text: $serverName)
                }

                Section("Stdio Transport (macOS only)") {
                    TextField("Command (e.g. npx)", text: $command)
                    TextField("Arguments (space separated)", text: $arguments)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add MCP Server")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") { connectServer() }
                        .disabled(serverName.isEmpty || command.isEmpty || isConnecting)
                }
            }
        }
    }

    private func connectServer() {
        isConnecting = true
        errorMessage = nil

        let args = arguments.split(separator: " ").map(String.init)
        let config = MCPServerConfig(transport: .stdio(command: command, arguments: args, environment: nil))

        Task {
            do {
                _ = try await MCPManager.shared.addServer(name: serverName, config: config)
                onAdd()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isConnecting = false
            }
        }
    }
}
