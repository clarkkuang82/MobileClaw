import SwiftUI
import Foundation

@Observable
final class NavigationRouter {
    var selectedTab: Tab = .chat
    var selectedConversationID: UUID?

    enum Tab: String, CaseIterable, Identifiable {
        case chat
        case agents
        case tools
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .chat: "Chat"
            case .agents: "Agents"
            case .tools: "Tools"
            case .settings: "Settings"
            }
        }

        var icon: String {
            switch self {
            case .chat: "bubble.left.and.bubble.right"
            case .agents: "person.3"
            case .tools: "wrench.and.screwdriver"
            case .settings: "gearshape"
            }
        }
    }
}
