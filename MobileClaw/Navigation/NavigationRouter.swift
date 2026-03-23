import SwiftUI
import Foundation

@Observable
@MainActor
final class NavigationRouter {
    var selectedTab: Tab = .chat
    var selectedConversationID: UUID?

    enum Tab: String, CaseIterable, Identifiable {
        case chat
        case agents
        case tools
        case documents
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .chat: "Chat"
            case .agents: "Agents"
            case .tools: "Tools"
            case .documents: "Docs"
            case .settings: "Settings"
            }
        }

        var icon: String {
            switch self {
            case .chat: "bubble.left.and.bubble.right"
            case .agents: "person.3"
            case .tools: "wrench.and.screwdriver"
            case .documents: "doc.on.doc"
            case .settings: "gearshape"
            }
        }
    }
}
