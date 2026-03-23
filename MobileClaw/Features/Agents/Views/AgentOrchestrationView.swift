import SwiftUI
import SwiftData
import MCCore
import MCPersistence
import MCAgents
import MCPClient

struct AgentOrchestrationView: View {
    @Query private var agentEntities: [AgentEntity]
    @State private var selectedAgentIDs: Set<UUID> = []
    @State private var task = ""
    @State private var strategy: StrategyType = .sequential
    @State private var events: [AgentEvent] = []
    @State private var isRunning = false

    enum StrategyType: String, CaseIterable {
        case sequential = "Sequential"
        case parallel = "Parallel"
        case supervisor = "Supervisor"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Agent selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(agentEntities) { agent in
                        agentChip(agent)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            // Strategy picker
            Picker("Strategy", selection: $strategy) {
                ForEach(StrategyType.allCases, id: \.self) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Events log
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                        eventView(event)
                    }
                }
                .padding()
            }

            Divider()

            // Input
            HStack {
                TextField("Describe the task...", text: $task, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: runOrchestration) {
                    Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isRunning ? .red : Color.accentColor)
                }
                .disabled(selectedAgentIDs.isEmpty || (task.isEmpty && !isRunning))
            }
            .padding()
        }
        .navigationTitle("Orchestration")
    }

    private func agentChip(_ agent: AgentEntity) -> some View {
        let isSelected = selectedAgentIDs.contains(agent.id)
        return Button {
            if isSelected { selectedAgentIDs.remove(agent.id) }
            else { selectedAgentIDs.insert(agent.id) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: agent.iconName ?? "person.circle")
                Text(agent.name)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : .secondary, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func eventView(_ event: AgentEvent) -> some View {
        switch event {
        case .started(let id):
            Label("Agent \(id.prefix(8)) started", systemImage: "play.circle")
                .font(.caption).foregroundStyle(.green)
        case .streaming(_, let text):
            Text(text).font(.callout)
        case .toolCall(_, let name):
            Label("Calling tool: \(name)", systemImage: "wrench")
                .font(.caption).foregroundStyle(.orange)
        case .toolResult(_, let name, _):
            Label("Tool \(name) completed", systemImage: "checkmark.circle")
                .font(.caption).foregroundStyle(.blue)
        case .completed(_, let result):
            VStack(alignment: .leading) {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
                Text(result).font(.callout)
            }
        case .error(_, let error):
            Label(error, systemImage: "exclamationmark.triangle")
                .font(.caption).foregroundStyle(.red)
        }
    }

    private func runOrchestration() {
        guard !isRunning else { return }
        let selectedAgents = agentEntities.filter { selectedAgentIDs.contains($0.id) }
        guard !selectedAgents.isEmpty else { return }

        let runtimes = selectedAgents.map { entity in
            AgentRuntime(config: AgentConfig(
                id: entity.id.uuidString,
                name: entity.name,
                systemPrompt: entity.systemPrompt,
                provider: LLMProvider(rawValue: entity.providerRawValue) ?? .anthropic,
                model: LLMModel.defaultModels(for: LLMProvider(rawValue: entity.providerRawValue) ?? .anthropic).first ?? .claudeSonnet
            ))
        }

        events = []
        isRunning = true
        let taskText = task
        task = ""

        Task {
            let stream: AsyncThrowingStream<AgentEvent, Error>
            switch strategy {
            case .sequential:
                stream = AgentOrchestrator.shared.runSequential(task: taskText, agents: runtimes)
            case .parallel:
                stream = AgentOrchestrator.shared.runParallel(task: taskText, agents: runtimes)
            case .supervisor:
                let supervisorConfig = AgentConfig(
                    name: "Supervisor",
                    systemPrompt: "You coordinate other agents to complete tasks.",
                    provider: .anthropic,
                    model: .claudeSonnet
                )
                stream = AgentOrchestrator.shared.runSupervisor(
                    task: taskText, supervisor: supervisorConfig, workers: runtimes
                )
            }

            do {
                for try await event in stream {
                    events.append(event)
                }
            } catch {
                events.append(.error(agentID: "orchestrator", error: error.localizedDescription))
            }
            isRunning = false
        }
    }
}
