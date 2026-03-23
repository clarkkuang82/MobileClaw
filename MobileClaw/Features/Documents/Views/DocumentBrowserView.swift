import SwiftUI
import UniformTypeIdentifiers

struct DocumentBrowserView: View {
    @State private var documents: [DocumentItem] = []
    @State private var showingFilePicker = false
    @State private var selectedDocument: DocumentItem?

    var body: some View {
        List {
            ForEach(documents) { doc in
                Button {
                    selectedDocument = doc
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: doc.icon)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.name)
                                .fontWeight(.medium)
                            Text(doc.sizeFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(doc.addedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { indices in
                documents.remove(atOffsets: indices)
            }
        }
        .overlay {
            if documents.isEmpty {
                ContentUnavailableView {
                    Label("No Documents", systemImage: "doc")
                } description: {
                    Text("Add documents to use as context in conversations")
                } actions: {
                    Button("Add Document") { showingFilePicker = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Documents")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingFilePicker = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .pdf, .json, .data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let size = attrs[.size] as? Int {
                        documents.append(DocumentItem(
                            name: url.lastPathComponent,
                            url: url,
                            size: size,
                            addedAt: Date()
                        ))
                    }
                }
            case .failure:
                break
            }
        }
        .sheet(item: $selectedDocument) { doc in
            DocumentPreviewSheet(document: doc)
        }
    }
}

struct DocumentItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let size: Int
    let addedAt: Date

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var icon: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "json": return "curlybraces"
        case "txt", "md": return "doc.text"
        default: return "doc"
        }
    }
}

struct DocumentPreviewSheet: View {
    let document: DocumentItem
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle(document.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                guard document.url.startAccessingSecurityScopedResource() else { return }
                defer { document.url.stopAccessingSecurityScopedResource() }
                content = (try? String(contentsOf: document.url, encoding: .utf8)) ?? "(Unable to read file)"
            }
        }
    }
}
