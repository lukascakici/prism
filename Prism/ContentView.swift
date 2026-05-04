import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Prism Quick Look")
                .font(.title2.weight(.semibold))

            Text("JSON, Python ve Swift dosyaları için sözdizimi vurgulamalı önizleme.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Label("Finder'da bir .json / .py / .swift dosyası seçin", systemImage: "1.circle")
                Label("Space tuşuna basın", systemImage: "2.circle")
                Label("Renkli önizlemenin tadını çıkarın", systemImage: "3.circle")
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
