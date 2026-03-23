import SwiftUI
import SwiftData
import MCCore
import MCPersistence

struct ConversationListView: View {
    @Bindable var router: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.serviceProvider) private var serviceProvider
    @Query(sort: \ConversationEntity.updatedAt, order: .reverse)
    private var conversations: [ConversationEntity]

    var body: some View {
        Group {
            if conversations.isEmpty {
                emptyState
            } else {
                conversationList
            }
        }
        .navigationTitle("Conversations")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: createConversation) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let conversation = conversations.first(where: { $0.id == id }) {
                ChatView(conversation: conversation)
            }
        }
    }

    private var conversationList: some View {
        List {
            ForEach(conversations) { conversation in
                NavigationLink(value: conversation.id) {
                    ConversationRowView(conversation: conversation)
                }
            }
            .onDelete(perform: deleteConversations)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Conversations", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Start a new conversation to chat with AI")
        } actions: {
            Button("New Chat", action: createConversation)
                .buttonStyle(.borderedProminent)
        }
    }

    private func createConversation() {
        let repo = ConversationRepository(modelContext: modelContext)
        let conversation = repo.create(
            title: "New Chat",
            provider: serviceProvider.currentProvider,
            modelID: serviceProvider.currentModel.id
        )
        try? repo.save()
        router.selectedConversationID = conversation.id
    }

    private func deleteConversations(at offsets: IndexSet) {
        let repo = ConversationRepository(modelContext: modelContext)
        for index in offsets {
            repo.delete(conversations[index])
        }
        try? repo.save()
    }
}
