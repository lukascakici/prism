import Foundation

/// HTML render aşamasına geçilmeden önce tüm girdilerin toplandığı immutable container.
struct RenderPayload {
    let language: SourceLanguage
    let source: String
    let originalByteCount: Int
    let wasTruncated: Bool
    let displayName: String
}

/// Desteklenen kaynak dilleri ve highlight.js karşılıkları.
enum SourceLanguage {
    case json
    case python
    case swift
    case plain

    /// highlight.js'in `<code class="language-...">` üzerinden tanıdığı sınıf adı.
    var hljsClass: String {
        switch self {
        case .json:   return "language-json"
        case .python: return "language-python"
        case .swift:  return "language-swift"
        case .plain:  return "plaintext"
        }
    }
}
