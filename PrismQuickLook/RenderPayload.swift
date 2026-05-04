import Foundation

/// Immutable container that gathers all inputs before the HTML render stage.
struct RenderPayload {
    let language: SourceLanguage
    let source: String
    let originalByteCount: Int
    let wasTruncated: Bool
    let displayName: String
}

/// Supported source languages and their highlight.js counterparts.
enum SourceLanguage {
    case json
    case python
    case swift
    case plain

    /// Class name highlight.js recognizes via `<code class="language-...">`.
    var hljsClass: String {
        switch self {
        case .json:   return "language-json"
        case .python: return "language-python"
        case .swift:  return "language-swift"
        case .plain:  return "plaintext"
        }
    }
}
