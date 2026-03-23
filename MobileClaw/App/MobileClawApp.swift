import SwiftUI
import SwiftData
import MCPersistence

@main
struct MobileClawApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainerSetup.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
