import Foundation

/// Immutable container that gathers all inputs for the syntax-highlighted render.
struct RenderPayload {
    let language: SourceLanguage
    let source: String
    let originalByteCount: Int
    let wasTruncated: Bool
}

/// Supported source languages.
enum SourceLanguage {
    case json
    case python
    case swift
    case markdown
    case yaml
    case shell
    case css
    case javascript
    case typescript
    case c
    case cpp
    case objectiveC
    case java
    case kotlin
    case go
    case rust
    case csharp
    case plain
}
