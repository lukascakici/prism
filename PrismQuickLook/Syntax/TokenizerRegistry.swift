import Foundation

/// SourceLanguage → Tokenizer mapping.
/// To add a new language: add a case to SourceLanguage, write a Tokenizer, map it here.
enum TokenizerRegistry {

    static func tokenizer(for language: SourceLanguage) -> Tokenizer {
        switch language {
        case .json:   return JSONTokenizer()
        case .python: return PythonTokenizer()
        case .swift:  return SwiftTokenizer()
        case .plain:  return PlainTokenizer()
        }
    }
}

/// Emits no tokens — fallback for plain text.
struct PlainTokenizer: Tokenizer {
    func tokenize(_ source: String) -> [Token] { [] }
}
