import SwiftUI

struct AppSidebarView: View {
    @Bindable var router: NavigationRouter

    var body: some View {
        NavigationSplitView {
            List(selection: $router.selectedTab) {
                ForEach(NavigationRouter.Tab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("MobileClaw")
        } detail: {
            switch router.selectedTab {
            case .chat:
                ConversationListView(router: router)
            case .agents:
                NavigationStack {
                    AgentListView()
                        .navigationDestination(for: UUID.self) { _ in
                            AgentOrchestrationView()
                        }
                }
            case .tools:
                NavigationStack {
                    MCPToolListView()
                }
            case .documents:
                NavigationStack {
                    DocumentBrowserView()
                }
            case .settings:
                SettingsView()
            }
        }
    }
}
