import Foundation

/// SourceLanguage → Tokenizer mapping.
/// To add a new language: add a case to SourceLanguage, write a Tokenizer, map it here.
enum TokenizerRegistry {

    static func tokenizer(for language: SourceLanguage) -> Tokenizer {
        switch language {
        case .json:       return JSONTokenizer()
        case .python:     return PythonTokenizer()
        case .swift:      return SwiftTokenizer()
        case .markdown:   return MarkdownTokenizer()
        case .yaml:       return YAMLTokenizer()
        case .shell:      return ShellTokenizer()
        case .css:        return CSSTokenizer()
        case .javascript: return CFamilyTokenizer(config: .javascript)
        case .typescript: return CFamilyTokenizer(config: .typescript)
        case .c:          return CFamilyTokenizer(config: .c)
        case .cpp:        return CFamilyTokenizer(config: .cpp)
        case .objectiveC: return CFamilyTokenizer(config: .objectiveC)
        case .java:       return CFamilyTokenizer(config: .java)
        case .kotlin:     return CFamilyTokenizer(config: .kotlin)
        case .go:         return CFamilyTokenizer(config: .go)
        case .rust:       return CFamilyTokenizer(config: .rust)
        case .csharp:     return CFamilyTokenizer(config: .csharp)
        case .plain:      return PlainTokenizer()
        }
    }
}

/// Emits no tokens — fallback for plain text.
struct PlainTokenizer: Tokenizer {
    func tokenize(_ source: String) -> [Token] { [] }
}
