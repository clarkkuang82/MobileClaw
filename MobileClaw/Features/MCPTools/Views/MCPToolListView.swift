import SwiftUI
import MCCore
import MCPClient

struct MCPToolListView: View {
    @State private var tools: [ToolDefinition] = []
    @State private var servers: [(id: String, name: String)] = []
    @State private var showingAddServer = false
    @State private var isLoading = false

    var body: some View {
        List {
            Section("Connected Servers") {
                if servers.isEmpty {
                    Text("No MCP servers connected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(servers, id: \.id) { server in
                        HStack {
                            Image(systemName: "server.rack")
                            Text(server.name)
                            Spacer()
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption2)
                        }
                    }
                }
            }

            Section("Available Tools (\(tools.count))") {
                if tools.isEmpty {
                    Text("No tools available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tools) { tool in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "wrench")
                                Text(tool.name)
                                    .fontWeight(.medium)
                            }
                            Text(tool.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("MCP Tools")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingAddServer = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showingAddServer) {
            MCPServerConfigView(onAdd: { refresh() })
        }
        .task { refresh() }
    }

    private func refresh() {
        isLoading = true
        Task { @MainActor in
            tools = await MCPManager.shared.availableTools()
            servers = await MCPManager.shared.connectedServers()
            isLoading = false
        }
    }
}
