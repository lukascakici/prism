# Prism — macOS Quick Look Syntax Highlighter

Syntax-highlighted Quick Look previews for JSON, Python, and Swift files.
Uses a `WKWebView` + bundled `highlight.js` architecture; sandbox-friendly, no external network access required.

## Quick start

### Option A — XcodeGen (recommended)

```bash
brew install xcodegen
xcodegen generate
open Prism.xcodeproj
```

Once Xcode is open:

1. From the Team field at the top, select your own developer account (for both targets).
2. Run the host app once with Cmd+R — this registers the extension with the system.
3. In Finder, hit Space on a `.json` / `.py` / `.swift` file.

### Option B — Manual Xcode setup

1. Create a new macOS App project (`Prism`).
2. Add **File → New → Target → macOS → Quick Look Preview Extension** (`PrismQuickLook`).
3. Add the files from this repo to the matching targets:
   - `Prism/` → host app target
   - `PrismQuickLook/*.swift` → extension target (Compile Sources)
   - `PrismQuickLook/Resources/` → extension target (Copy Bundle Resources, add as a folder reference)
4. Replace both targets' `Info.plist` and `*.entitlements` settings with the ones in this repo.
5. Build & Run.

## Architecture

| Layer | Responsibility |
|---|---|
| `PreviewViewController` | `QLPreviewingController` adapter, `WKWebView` host |
| `FileReader` | Memory-disciplined (5MB cap) UTF-8 reader |
| `LanguageDetection` | UTI → `SourceLanguage` mapping |
| `RenderPayload` | Immutable view-model |
| `Resources/preview.html` | Template; `{{LANG}}`, `{{CODE}}`, `{{BANNER}}`, `{{TITLE}}` placeholders |
| `Resources/highlight.min.js` | highlight.js core (v11.9.0) |

## Performance notes

- **5 MB cap**: `FileReader.readBoundedUTF8` reads the file in chunks via `FileHandle`,
  showing a truncate banner if the limit is exceeded.
- **Cold-start**: programmatic view instead of `.xib`; `WKWebView` warm-up is ~80–150 ms.
- **Theme**: CSS `prefers-color-scheme` media query — no extra code on the Swift side.
- **Memory**: WebContent process runs in a separate XPC; the extension process stays around ~15 MB.

## Sandbox & Security

- All assets live inside the bundle — the `network.client` entitlement is **not added**.
- The navigation policy rejects everything except `file://` / `about:` / `data:`.
- Security-scoped resource access is managed via the `start/stop` defer pattern.

## Test

```bash
# Quick manual test:
qlmanage -p ~/Desktop/test.json -g $(pwd)/build/Build/Products/Debug/PrismQuickLook.appex
```
