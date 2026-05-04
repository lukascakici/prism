import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Prism Quick Look")
                .font(.title2.weight(.semibold))

            Text("Syntax-highlighted previews for JSON, Python, and Swift files.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Label("Select a .json / .py / .swift file in Finder", systemImage: "1.circle")
                Label("Press the Space key", systemImage: "2.circle")
                Label("Enjoy the colored preview", systemImage: "3.circle")
            }
            .font(.callout)
            .padding(.top, 8)
        }
        .padding(32)
    }
}

#Preview {
    ContentView()
}
