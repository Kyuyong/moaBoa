import SwiftUI

@main
struct MoaboaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 720, height: 860)
        .windowResizability(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
