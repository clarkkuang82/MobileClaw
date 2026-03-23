import SwiftUI

struct ContentView: View {
    @State private var router = NavigationRouter()

    var body: some View {
        #if os(iOS)
        AppTabView(router: router)
        #else
        AppSidebarView(router: router)
        #endif
    }
}

#Preview {
    ContentView()
}
