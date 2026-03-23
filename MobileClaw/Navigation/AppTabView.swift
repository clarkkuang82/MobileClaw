import SwiftUI

struct AppTabView: View {
    @Bindable var router: NavigationRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ConversationListView(router: router)
                .tabItem {
                    Label(NavigationRouter.Tab.chat.title, systemImage: NavigationRouter.Tab.chat.icon)
                }
                .tag(NavigationRouter.Tab.chat)

            NavigationStack {
                AgentListView()
                    .navigationDestination(for: UUID.self) { _ in
                        AgentOrchestrationView()
                    }
            }
            .tabItem {
                Label(NavigationRouter.Tab.agents.title, systemImage: NavigationRouter.Tab.agents.icon)
            }
            .tag(NavigationRouter.Tab.agents)

            NavigationStack {
                MCPToolListView()
            }
            .tabItem {
                Label(NavigationRouter.Tab.tools.title, systemImage: NavigationRouter.Tab.tools.icon)
            }
            .tag(NavigationRouter.Tab.tools)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(NavigationRouter.Tab.settings.title, systemImage: NavigationRouter.Tab.settings.icon)
            }
            .tag(NavigationRouter.Tab.settings)
        }
    }
}
