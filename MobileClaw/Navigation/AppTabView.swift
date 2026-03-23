import SwiftUI

struct AppTabView: View {
    @Bindable var router: NavigationRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                ConversationListView(router: router)
            }
            .tabItem {
                Label(NavigationRouter.Tab.chat.title, systemImage: NavigationRouter.Tab.chat.icon)
            }
            .tag(NavigationRouter.Tab.chat)

            NavigationStack {
                AgentPlaceholderView()
            }
            .tabItem {
                Label(NavigationRouter.Tab.agents.title, systemImage: NavigationRouter.Tab.agents.icon)
            }
            .tag(NavigationRouter.Tab.agents)

            NavigationStack {
                ToolsPlaceholderView()
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

struct AgentPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("Agents", systemImage: "person.3", description: Text("Multi-agent orchestration coming in Phase 4"))
    }
}

struct ToolsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("MCP Tools", systemImage: "wrench.and.screwdriver", description: Text("MCP tool integration coming in Phase 3"))
    }
}
