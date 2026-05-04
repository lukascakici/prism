import SwiftUI

/// Quick Look Preview Extension'ları kendi başlarına dağıtılamaz; bir host
/// uygulaması içinde paketlenir. Bu app, eklentinin sisteme tanıtılması için
/// gerekli minimal taşıyıcıdır. Kullanıcı uygulamayı en az bir kez açtığında
/// macOS extension'ı kayda alır ve Finder/Spotlight kullanmaya başlar.
@main
struct PrismApp: App {
    var body: some Scene {
        WindowGroup("Prism") {
            ContentView()
                .frame(minWidth: 480, minHeight: 320)
        }
    }
}
