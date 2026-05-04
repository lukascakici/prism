import Foundation

/// Tokenizer for CSS (also serviceable for SCSS/Less at a glance).
/// Highlights:
/// - /* ... */ comments
/// - @rules (@media, @import, @keyframes, …)
/// - Selectors: type, .class, #id, :pseudo, ::pseudo, [attr]
/// - Property names (before `:`)
/// - Values: keywords, numbers with units, hex colors, "..." / '...' strings, function-like (url(), rgb(), var())
/// - Custom properties (--name)
/// - Punctuation: { } ; , : ( )
struct CSSTokenizer: Tokenizer {

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)
        var inDeclaration = false

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            // Whitespace
            if c.isWhitespace { s.advance(); continue }

            // Block comment
            if c == "/" && s.peek(offset: 1) == "*" {
                tokens.append(scanBlockComment(&s))
                continue
            }

            // Strings
            if c == "\"" || c == "'" {
                tokens.append(scanString(&s, quote: c))
                continue
            }

            // @rule
            if c == "@" {
                let start = s.index
                s.advance()
                s.consume { $0.isASCIILetter || $0 == "-" }
                tokens.append(Token(range: start..<s.index, type: .keyword))
                continue
            }

            // Brace open / close — toggles declaration mode
            if c == "{" {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                inDeclaration = true
                continue
            }
            if c == "}" {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                inDeclaration = false
                continue
            }

            if c == ";" {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }
            if c == "," || c == "(" || c == ")" {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // Hex color: #abc / #aabbcc / #aabbccdd
            if c == "#" {
                if let token = tryScanHexColor(&s) {
                    tokens.append(token)
                    continue
                }
                // Otherwise: id selector
                let start = s.index
                s.advance()
                s.consume { $0.isIdentifierPart || $0 == "-" }
                tokens.append(Token(range: start..<s.index, type: .type))
                continue
            }

            // Class selector .name
            if c == "." && (s.peek(offset: 1)?.isASCIILetter == true || s.peek(offset: 1) == "_" || s.peek(offset: 1) == "-") {
                let start = s.index
                s.advance()
                s.consume { $0.isIdentifierPart || $0 == "-" }
                tokens.append(Token(range: start..<s.index, type: .type))
                continue
            }

            // Pseudo-class / pseudo-element: : or ::
            if c == ":" && !inDeclaration {
                let start = s.index
                s.advance()
                if s.peek == ":" { s.advance() }
                s.consume { $0.isASCIILetter || $0 == "-" }
                tokens.append(Token(range: start..<s.index, type: .keyword))
                continue
            }
            if c == ":" && inDeclaration {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // Attribute selector [attr...]
            if c == "[" {
                let start = s.index
                while let cc = s.peek, cc != "]", cc != "\n" { s.advance() }
                if s.peek == "]" { s.advance() }
                tokens.append(Token(range: start..<s.index, type: .type))
                continue
            }

            // Custom property --name (only meaningful before colon, but cheap to color anywhere)
            if c == "-" && s.peek(offset: 1) == "-" {
                let start = s.index
                s.advance(); s.advance()
                s.consume { $0.isIdentifierPart || $0 == "-" }
                tokens.append(Token(range: start..<s.index, type: .attribute))
                continue
            }

            // Number with optional unit (e.g. 12px, 1.5rem, 50%, -3em)
            if c.isASCIIDigit || (c == "-" && s.peek(offset: 1)?.isASCIIDigit == true) || (c == "." && s.peek(offset: 1)?.isASCIIDigit == true) {
                tokens.append(scanNumber(&s))
                continue
            }

            // Identifier — property name (before :) or value keyword.
            if c.isASCIILetter || c == "_" {
                let start = s.index
                s.consume { $0.isIdentifierPart || $0 == "-" }

                // Look-ahead for `(` → function call (e.g. url(), rgb(), calc()).
                if s.peek == "(" {
                    tokens.append(Token(range: start..<s.index, type: .function))
                    continue
                }

                if inDeclaration {
                    // Look ahead for ':' → property name.
                    let bookmark = s.mark()
                    while s.peek == " " { s.advance() }
                    if s.peek == ":" {
                        s.restore(bookmark)
                        tokens.append(Token(range: start..<s.index, type: .attribute))
                        continue
                    }
                    s.restore(bookmark)
                }
                // Otherwise: selector type or a value keyword.
                tokens.append(Token(range: start..<s.index, type: inDeclaration ? .constant : .keyword))
                continue
            }

            s.advance()
        }

        return tokens
    }

    // MARK: - Helpers

    private func scanBlockComment(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance(); s.advance() // /*
        while !s.isAtEnd {
            if s.peek == "*" && s.peek(offset: 1) == "/" {
                s.advance(); s.advance(); break
            }
            s.advance()
        }
        return Token(range: start..<s.index, type: .comment)
    }

    private func scanString(_ s: inout Scanner, quote: Character) -> Token {
        let start = s.index
        s.advance() // open
        while let c = s.peek, c != quote, c != "\n" {
            if c == "\\" {
                s.advance()
                if !s.isAtEnd { s.advance() }
            } else {
                s.advance()
            }
        }
        if s.peek == quote { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func tryScanHexColor(_ s: inout Scanner) -> Token? {
        let bookmark = s.mark()
        s.advance() // #
        var hexLen = 0
        while let c = s.peek, c.isHexDigitChar {
            s.advance(); hexLen += 1
            if hexLen > 8 { break }
        }
        // Valid hex color lengths: 3, 4, 6, 8.
        if [3, 4, 6, 8].contains(hexLen) {
            // Make sure the next char isn't an identifier continuation.
            if let next = s.peek, next.isASCIILetter {
                s.restore(bookmark)
                return nil
            }
            return Token(range: bookmark..<s.index, type: .number)
        }
        s.restore(bookmark)
        return nil
    }

    private func scanNumber(_ s: inout Scanner) -> Token {
        let start = s.index
        if s.peek == "-" { s.advance() }
        s.consume { $0.isASCIIDigit }
        if s.peek == "." {
            s.advance()
            s.consume { $0.isASCIIDigit }
        }
        // Unit: identifier letters (e.g. px, em, rem, vh) or %
        if s.peek == "%" {
            s.advance()
        } else {
            s.consume { $0.isASCIILetter }
        }
        return Token(range: start..<s.index, type: .number)
    }
}

private extension Character {
    var isHexDigitChar: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return CharacterSet(charactersIn: "0123456789abcdefABCDEF").contains(scalar)
    }
}
