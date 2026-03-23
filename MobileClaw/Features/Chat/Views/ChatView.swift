import SwiftUI
import SwiftData
import MCCore
import MCPersistence

struct ChatView: View {
    let conversation: ConversationEntity
    @Environment(\.modelContext) private var modelContext
    @Environment(\.serviceProvider) private var serviceProvider
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
            inputBar
        }
        .navigationTitle(conversation.title.isEmpty ? "New Chat" : conversation.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                modelBadge
            }
        }
        .onAppear {
            let repo = ConversationRepository(modelContext: modelContext)
            viewModel.setup(conversation: conversation, repository: repo, serviceProvider: serviceProvider)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isStreaming && !viewModel.streamingText.isEmpty {
                        StreamingMessageView(text: viewModel.streamingText)
                            .id("streaming")
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation {
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamingText) {
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused($isInputFocused)
                .onSubmit {
                    #if os(macOS)
                    send()
                    #endif
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if viewModel.isStreaming {
                Button(action: viewModel.stopStreaming) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            } else {
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.isEmpty ? Color.secondary : Color.accentColor)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var modelBadge: some View {
        Text(viewModel.currentModel.name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.fill.tertiary)
            .clipShape(Capsule())
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.sendMessage(text)
    }
}
