import Foundation

/// SourceLanguage → Tokenizer eşlemesi.
/// Yeni dil eklerken: SourceLanguage'a case ekle, Tokenizer yaz, burada map'le.
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

/// Hiç token üretmez — düz metin için fallback.
struct PlainTokenizer: Tokenizer {
    func tokenize(_ source: String) -> [Token] { [] }
}
