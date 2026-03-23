import SwiftUI

struct StreamingMessageView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "brain")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Generating...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
