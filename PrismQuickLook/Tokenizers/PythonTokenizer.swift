import Foundation

/// Python 3 için tokenizer.
/// Destekledikleri:
/// - # line comments
/// - String literals: '...', "...", '''...''', """..."""  (raw/byte/f prefix'leri dahil)
/// - Number: int, float, hex (0x), oct (0o), bin (0b)
/// - Keywords (PEP 8 listesi)
/// - Builtins: True, False, None
/// - Decorator: @\w+
/// - Function/class def isimleri
struct PythonTokenizer: Tokenizer {

    private static let keywords: Set<String> = [
        "False", "None", "True", "and", "as", "assert", "async", "await",
        "break", "class", "continue", "def", "del", "elif", "else", "except",
        "finally", "for", "from", "global", "if", "import", "in", "is",
        "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try",
        "while", "with", "yield", "match", "case",
    ]

    private static let constants: Set<String> = ["True", "False", "None"]

    /// String prefix'leri: r, b, u, f ve kombinasyonları (rb, br, fr, rf…). Case-insensitive.
    private static let stringPrefixes: Set<String> = [
        "r", "R", "b", "B", "u", "U", "f", "F",
        "rb", "Rb", "rB", "RB", "br", "bR", "Br", "BR",
        "fr", "Fr", "fR", "FR", "rf", "rF", "Rf", "RF",
    ]

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)
        // `def`/`class`'tan sonra gelen identifier'ı function/type olarak işaretlemek için.
        var pendingFunctionDef = false
        var pendingTypeDef = false

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            // Whitespace
            if c.isWhitespace { s.advance(); continue }

            // Comment: # ... \n
            if c == "#" {
                let start = s.index
                s.consume { $0 != "\n" }
                tokens.append(Token(range: start..<s.index, type: .comment))
                continue
            }

            // Decorator: @identifier
            if c == "@" {
                let start = s.index
                s.advance()
                s.consume { $0.isIdentifierPart }
                tokens.append(Token(range: start..<s.index, type: .attribute))
                continue
            }

            // String prefix? (r"...", f"...", rb'...' vs.)
            if c.isIdentifierStart, let token = tryScanPrefixedString(&s) {
                tokens.append(token)
                continue
            }

            // Plain string '...' "..." '''...''' """..."""
            if c == "\"" || c == "'" {
                tokens.append(scanString(&s))
                continue
            }

            // Number
            if c.isASCIIDigit {
                tokens.append(scanNumber(&s))
                continue
            }

            // Identifier / keyword / constant
            if c.isIdentifierStart {
                let start = s.index
                s.consume { $0.isIdentifierPart }
                let word = String(source[start..<s.index])

                let type: TokenType
                if pendingFunctionDef {
                    pendingFunctionDef = false
                    type = .function
                } else if pendingTypeDef {
                    pendingTypeDef = false
                    type = .type
                } else if Self.constants.contains(word) {
                    type = .constant
                } else if Self.keywords.contains(word) {
                    if word == "def"   { pendingFunctionDef = true }
                    if word == "class" { pendingTypeDef = true }
                    type = .keyword
                } else {
                    type = .identifier
                }
                tokens.append(Token(range: start..<s.index, type: type))
                continue
            }

            // Operator / punctuation tek karakter pasajı.
            // (Detaylı operator çakışmaları syntax highlight için önemli değil.)
            if "(){}[],:;".contains(c) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }
            if "+-*/%=<>!&|^~".contains(c) {
                let start = s.index
                s.consume { "+-*/%=<>!&|^~".contains($0) }
                tokens.append(Token(range: start..<s.index, type: .operator))
                continue
            }

            // Bilinmeyen — atla.
            s.advance()
        }

        return tokens
    }

    // MARK: - Helpers

    private func scanString(_ s: inout Scanner) -> Token {
        let start = s.index
        guard let quote = s.peek else { return Token(range: start..<s.index, type: .string) }

        // Triple-quoted mı?
        let triple = String(repeating: String(quote), count: 3)
        if s.startsWith(triple) {
            s.match(triple) // open
            while !s.isAtEnd && !s.startsWith(triple) {
                if s.peek == "\\" { s.advance(); if !s.isAtEnd { s.advance() } }
                else { s.advance() }
            }
            s.match(triple) // close (eksikse boş bırak)
            return Token(range: start..<s.index, type: .string)
        }

        // Single-line string
        s.advance() // open quote
        while let c = s.peek, c != quote, c != "\n" {
            if c == "\\" { s.advance(); if !s.isAtEnd { s.advance() } }
            else { s.advance() }
        }
        if s.peek == quote { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    /// r"...", f'...', rb"...", BR'...' gibi prefix'li string'leri tarar.
    /// Eşleşme yoksa scanner'ı geri sarar ve nil döner.
    private func tryScanPrefixedString(_ s: inout Scanner) -> Token? {
        let bookmark = s.mark()

        // En fazla 2 karakterlik prefix'i topla.
        var prefix = ""
        for _ in 0..<2 {
            if let c = s.peek, c.isASCIILetter {
                prefix.append(c)
                s.advance()
            }
        }

        let next = s.peek
        if (next == "\"" || next == "'") && Self.stringPrefixes.contains(prefix) {
            // String başlıyor — prefix'i de string aralığına dahil et.
            let stringContent = scanString(&s)
            return Token(range: bookmark..<stringContent.range.upperBound, type: .string)
        }

        // Match yok — geri sar.
        s.restore(bookmark)
        return nil
    }

    private func scanNumber(_ s: inout Scanner) -> Token {
        let start = s.index
        // Hex / Oct / Bin literal: 0x... 0o... 0b...
        if s.peek == "0", let next = s.peek(offset: 1),
           "xXoObB".contains(next) {
            s.advance(); s.advance()
            s.consume { $0.isHexDigit || $0 == "_" }
            return Token(range: start..<s.index, type: .number)
        }
        s.consume { $0.isASCIIDigit || $0 == "_" }
        if s.peek == "." {
            s.advance()
            s.consume { $0.isASCIIDigit || $0 == "_" }
        }
        if s.peek == "e" || s.peek == "E" {
            s.advance()
            if s.peek == "+" || s.peek == "-" { s.advance() }
            s.consume { $0.isASCIIDigit }
        }
        // Complex number suffix: 3j
        if s.peek == "j" || s.peek == "J" { s.advance() }
        return Token(range: start..<s.index, type: .number)
    }
}

private extension Character {
    var isHexDigit: Bool { hexDigitValue != nil }
}
