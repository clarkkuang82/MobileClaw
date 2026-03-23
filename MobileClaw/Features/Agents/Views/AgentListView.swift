import SwiftUI
import SwiftData
import MCPersistence

struct AgentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AgentEntity.updatedAt, order: .reverse) private var agents: [AgentEntity]
    @State private var showingCreateAgent = false

    var body: some View {
        List {
            ForEach(agents) { agent in
                NavigationLink(value: agent.id) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: agent.colorHex ?? "#007AFF").opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: agent.iconName ?? "person.circle")
                                    .foregroundStyle(Color(hex: agent.colorHex ?? "#007AFF"))
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(agent.name)
                                .fontWeight(.medium)
                            Text(agent.systemPrompt.prefix(60))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .onDelete(perform: deleteAgents)
        }
        .overlay {
            if agents.isEmpty {
                ContentUnavailableView {
                    Label("No Agents", systemImage: "person.3")
                } description: {
                    Text("Create agents to automate complex tasks")
                } actions: {
                    Button("Create Agent") { showingCreateAgent = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Agents")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingCreateAgent = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateAgent) {
            AgentConfigView()
        }
    }

    private func deleteAgents(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(agents[index])
        }
        try? modelContext.save()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
