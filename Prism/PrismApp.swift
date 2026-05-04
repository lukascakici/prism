import SwiftUI

/// Quick Look Preview Extensions cannot be distributed on their own; they are
/// packaged inside a host application. This app is the minimal carrier needed to
/// register the extension with the system. Once the user opens the app at least
/// once, macOS registers the extension and Finder/Spotlight start using it.
@main
struct PrismApp: App {
    var body: some Scene {
        WindowGroup("Prism") {
            ContentView()
                .frame(minWidth: 480, minHeight: 320)
        }
    }
}
