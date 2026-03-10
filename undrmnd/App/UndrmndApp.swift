import SwiftUI

@main
struct UndrmndApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SupabaseService.shared)
        }
    }
}
