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
    case plain
}
