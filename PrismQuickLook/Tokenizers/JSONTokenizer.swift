import Foundation

/// Tokenizer for JSON.
/// RFC 8259 grammar: object, array, string, number, true|false|null.
/// JSON has no comments (a separate tokenizer is needed for JSON5/JSONC).
struct JSONTokenizer: Tokenizer {

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            // Skip whitespace — we don't emit tokens for it.
            if c.isWhitespace { s.advance(); continue }

            // String "..."
            if c == "\"" {
                tokens.append(scanString(&s))
                continue
            }

            // Number — optional '-', followed by digits.
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

            // Unknown — silently skip (don't crash on malformed JSON).
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
        // No match — something else, identifier-like but not in the JSON spec.
        return nil
    }
}
