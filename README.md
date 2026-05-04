# Prism — macOS Quick Look Syntax Highlighter

JSON, Python ve Swift dosyaları için sözdizimi vurgulamalı Quick Look önizlemesi.
`WKWebView` + bundled `highlight.js` mimarisi kullanır; sandbox dostu, dış ağ erişimi gerektirmez.

## Hızlı başlangıç

### Seçenek A — XcodeGen (önerilen)

```bash
brew install xcodegen
xcodegen generate
open Prism.xcodeproj
```

Xcode açıldıktan sonra:

1. Üstteki Team alanından kendi geliştirici hesabını seç (her iki target için).
2. Cmd+R ile host app'i bir kez çalıştır — bu, extension'ı sisteme kaydeder.
3. Finder'da bir `.json` / `.py` / `.swift` dosyasına Space bas.

### Seçenek B — Manuel Xcode kurulumu

1. Yeni bir macOS App projesi oluştur (`Prism`).
2. **File → New → Target → macOS → Quick Look Preview Extension** ekle (`PrismQuickLook`).
3. Bu repodaki dosyaları ilgili target'lara ekle:
   - `Prism/` → host app target
   - `PrismQuickLook/*.swift` → extension target (Compile Sources)
   - `PrismQuickLook/Resources/` → extension target (Copy Bundle Resources, klasör referansı olarak ekle)
4. Her iki target'ın `Info.plist` ve `*.entitlements` ayarlarını bu repodakilerle değiştir.
5. Build & Run.

## Mimari

| Katman | Sorumluluk |
|---|---|
| `PreviewViewController` | `QLPreviewingController` adaptörü, `WKWebView` host'u |
| `FileReader` | Bellek-disiplinli (5MB tavanlı) UTF-8 okuma |
| `LanguageDetection` | UTI → `SourceLanguage` eşleme |
| `RenderPayload` | Immutable view-model |
| `Resources/preview.html` | Template; `{{LANG}}`, `{{CODE}}`, `{{BANNER}}`, `{{TITLE}}` placeholder'lar |
| `Resources/highlight.min.js` | highlight.js core (v11.9.0) |

## Performans notları

- **5 MB tavan**: `FileReader.readBoundedUTF8` dosyayı `FileHandle` ile parçalı okur,
  limit aşılırsa truncate banner'ı gösterilir.
- **Cold-start**: `.xib` yerine programatik view; `WKWebView` ısınma süresi ~80–150 ms.
- **Tema**: CSS `prefers-color-scheme` media query — Swift tarafında ek kod yok.
- **Bellek**: WebContent process ayrı XPC'de; eklenti süreci ~15 MB civarında.

## Sandbox & Güvenlik

- Tüm asset'ler bundle içinde — `network.client` entitlement'ı **eklenmemiştir**.
- Navigation policy `file://` / `about:` / `data:` dışında her şeyi reddeder.
- Security-scoped resource erişimi `start/stop` defer pattern'i ile yönetilir.

## Test

```bash
# Hızlı manuel test:
qlmanage -p ~/Desktop/test.json -g $(pwd)/build/Build/Products/Debug/PrismQuickLook.appex
```
