import SwiftUI
import MCCore

struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .user {
                Spacer(minLength: 40)
            }

            if message.role == .assistant {
                avatar
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                ForEach(Array(message.content.enumerated()), id: \.offset) { _, block in
                    contentView(for: block)
                }

                if let model = message.modelID {
                    Text(model)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    @ViewBuilder
    private func contentView(for block: ContentBlock) -> some View {
        switch block {
        case .text(let text):
            Text(text)
                .textSelection(.enabled)
                .padding(12)
                .background(message.role == .user ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.regularMaterial))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

        case .toolUse(let toolUse):
            HStack(spacing: 6) {
                Image(systemName: "wrench")
                Text(toolUse.name)
                    .fontWeight(.medium)
            }
            .font(.caption)
            .padding(8)
            .background(.orange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .toolResult(let result):
            VStack(alignment: .leading, spacing: 4) {
                Text(result.isError ? "Error" : "Result")
                    .font(.caption)
                    .foregroundStyle(result.isError ? .red : .green)
                Text(result.content)
                    .font(.caption)
                    .lineLimit(5)
            }
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .thinking(let text):
            DisclosureGroup("Thinking...") {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(.purple.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .image:
            Image(systemName: "photo")
                .padding(8)
        }
    }

    private var avatar: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.2))
            .frame(width: 28, height: 28)
            .overlay {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
    }
}
