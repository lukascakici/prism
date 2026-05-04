import Foundation

/// JSON için tokenizer.
/// RFC 8259 grameri: object, array, string, number, true|false|null.
/// JSON'da yorum yoktur (JSON5/JSONC için ayrı tokenizer gerekir).
struct JSONTokenizer: Tokenizer {

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            // Whitespace skip — token üretmiyoruz.
            if c.isWhitespace { s.advance(); continue }

            // String "..."
            if c == "\"" {
                tokens.append(scanString(&s))
                continue
            }

            // Number — opsiyonel '-', sonrası rakam.
            if c == "-" || c.isASCIIDigit {
                tokens.append(scanNumber(&s))
                continue
            }

            // Constants: true | false | null
            if c.isASCIILetter {
                if let token = scanConstant(&s) {
                    tokens.append(token)
                    continue
                }
            }

            // Punctuation: { } [ ] : ,
            if "{}[]:,".contains(c) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // Bilinmeyen — sessizce skip et (bozuk JSON'da crash etme).
            s.advance()
        }

        return tokens
    }

    // MARK: - Token scanners

    private func scanString(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // opening "
        while let c = s.peek, c != "\"" {
            if c == "\\" {
                s.advance() // backslash
                if !s.isAtEnd { s.advance() } // escaped char
            } else {
                s.advance()
            }
        }
        if s.peek == "\"" { s.advance() } // closing "
        return Token(range: start..<s.index, type: .string)
    }

    private func scanNumber(_ s: inout Scanner) -> Token {
        let start = s.index
        if s.peek == "-" { s.advance() }
        s.consume { $0.isASCIIDigit }
        if s.peek == "." {
            s.advance()
            s.consume { $0.isASCIIDigit }
        }
        if s.peek == "e" || s.peek == "E" {
            s.advance()
            if s.peek == "+" || s.peek == "-" { s.advance() }
            s.consume { $0.isASCIIDigit }
        }
        return Token(range: start..<s.index, type: .number)
    }

    private func scanConstant(_ s: inout Scanner) -> Token? {
        let start = s.index
        for keyword in ["true", "false", "null"] {
            if s.match(keyword) {
                return Token(range: start..<s.index, type: .constant)
            }
        }
        // Eşleşme yok — başka bir şey, identifier-benzeri ama JSON spec'te yok.
        return nil
    }
}
