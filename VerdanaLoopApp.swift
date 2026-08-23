import SwiftUI

@main
struct VerdanaLoopApp: App {
    @StateObject private var store = LoopStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
