import SwiftUI
import MCPersistence

struct ConversationRowView: View {
    let conversation: ConversationEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title.isEmpty ? "New Chat" : conversation.title)
                .font(.headline)
                .lineLimit(1)

            HStack {
                Text(conversation.providerRawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.fill.tertiary)
                    .clipShape(Capsule())

                Spacer()

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
