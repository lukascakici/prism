# Prism — macOS Quick Look Syntax Highlighter

Syntax-highlighted Quick Look previews for JSON, Python, and Swift files.
Pure native rendering — `NSTextView` + `NSAttributedString` driven by hand-written tokenizers. Sandbox-friendly, no external assets, no network access.

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
   - `PrismQuickLook/*.swift` (including `Tokenizers/` and `Syntax/`) → extension target (Compile Sources)
4. Replace both targets' `Info.plist` and `*.entitlements` settings with the ones in this repo.
5. Build & Run.

## Architecture

| Layer | Responsibility |
|---|---|
| `PreviewViewController` | `QLPreviewingController` adapter; hosts an `NSScrollView` + `NSTextView` |
| `FileReader` | Memory-disciplined (5 MB cap) UTF-8 reader with Latin-1 fallback |
| `LanguageDetection` | UTI → `SourceLanguage` mapping, with file-extension fallback |
| `RenderPayload` | Immutable view-model passed from loader to renderer |
| `Syntax/Scanner` | Unicode-safe character cursor used by every tokenizer |
| `Syntax/Tokenizer` | Protocol; one implementation per language |
| `Syntax/SyntaxRenderer` | Source + Tokenizer → `NSAttributedString` |
| `Syntax/SyntaxTheme` | `TokenType` → dynamic light/dark `NSColor` (GitHub palette) |
| `Tokenizers/{JSON,Python,Swift}Tokenizer` | Per-language tokenizers |

## Performance notes

- **5 MB cap**: `FileReader.readBoundedUTF8` reads the file in chunks via `FileHandle`,
  showing a truncate banner if the limit is exceeded.
- **Cold-start**: programmatic view, no `.xib` loading; rendering is a single `NSAttributedString` build, no web engine warm-up.
- **Theme**: `NSColor(name:dynamicProvider:)` resolves Light/Dark at render time — switching the system appearance updates the preview live without re-rendering.
- **Memory**: extension process stays small; no separate WebContent process is spawned.

## Sandbox & Security

- App-sandboxed (`com.apple.security.app-sandbox`); only `files.user-selected.read-only` is granted.
- The `network.client` entitlement is **not added** — there is no remote asset loading and no WebView, so no navigation policy is required.
- Security-scoped resource access uses the `start/stop` defer pattern.

## Test

```bash
# Quick manual test:
qlmanage -p ~/Desktop/test.json -g $(pwd)/build/Build/Products/Debug/PrismQuickLook.appex
```
