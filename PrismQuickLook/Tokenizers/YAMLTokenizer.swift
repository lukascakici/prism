import Foundation

/// Tokenizer for YAML (1.1/1.2 lightweight subset).
/// Highlights:
/// - # comments
/// - "..." / '...' strings (single-line)
/// - Block scalars: | and > markers
/// - Mapping keys (identifier ending with `:`)
/// - Constants: true/false/null/yes/no/on/off (and YAML aliases)
/// - Numbers (int, float)
/// - Anchors (&name), aliases (*name), tags (!name, !!type)
/// - Document markers: --- and ...
/// - List bullets (- at start of line / after spaces)
struct YAMLTokenizer: Tokenizer {

    private static let constants: Set<String> = [
        "true", "false", "null", "True", "False", "Null", "TRUE", "FALSE", "NULL",
        "yes", "no", "Yes", "No", "YES", "NO",
        "on", "off", "On", "Off", "ON", "OFF",
        "~",
    ]

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            // Skip whitespace (do not emit).
            if c == " " || c == "\t" {
                s.advance()
                continue
            }

            // Newline — just advance.
            if c == "\n" {
                s.advance()
                continue
            }

            // Comment: # to end of line
            if c == "#" {
                let start = s.index
                s.consume { $0 != "\n" }
                tokens.append(Token(range: start..<s.index, type: .comment))
                continue
            }

            // Document marker: --- or ... (must be on its own line, but be lenient)
            if (c == "-" || c == ".") && s.peek(offset: 1) == c && s.peek(offset: 2) == c {
                let start = s.index
                s.advance(); s.advance(); s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // List bullet: "- " at the cursor.
            if c == "-" && (s.peek(offset: 1) == " " || s.peek(offset: 1) == "\n" || s.peek(offset: 1) == nil) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // Block scalar markers: | or > immediately followed by space/newline
            if (c == "|" || c == ">") && (s.peek(offset: 1) == " " || s.peek(offset: 1) == "\n" || s.peek(offset: 1) == nil) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // Anchors / aliases / tags: &name, *name, !name, !!type
            if c == "&" || c == "*" || c == "!" {
                let start = s.index
                s.advance()
                if s.peek == "!" { s.advance() } // !!type
                s.consume { $0.isIdentifierPart || $0 == "-" || $0 == "/" }
                tokens.append(Token(range: start..<s.index, type: .attribute))
                continue
            }

            // Quoted strings
            if c == "\"" || c == "'" {
                tokens.append(scanQuotedString(&s, quote: c))
                continue
            }

            // Numbers (must come before identifier)
            if c == "-" || c == "+" || c.isASCIIDigit {
                if let token = tryScanNumber(&s) {
                    tokens.append(token)
                    continue
                }
            }

            // Word: could be a key (ends with :) or a scalar/constant.
            if c.isASCIILetter || c == "_" {
                tokens.append(scanWord(&s))
                continue
            }

            // Punctuation: { } [ ] , : ?
            if "{}[],:?".contains(c) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // Anything else — skip.
            s.advance()
        }

        return tokens
    }

    // MARK: - Helpers

    private func scanQuotedString(_ s: inout Scanner, quote: Character) -> Token {
        let start = s.index
        s.advance() // open
        while let c = s.peek, c != quote {
            if c == "\\" && quote == "\"" {
                s.advance()
                if !s.isAtEnd { s.advance() }
            } else if c == "\n" {
                break
            } else {
                s.advance()
            }
        }
        if s.peek == quote { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func tryScanNumber(_ s: inout Scanner) -> Token? {
        let bookmark = s.mark()
        if s.peek == "-" || s.peek == "+" { s.advance() }
        guard let c = s.peek, c.isASCIIDigit else {
            s.restore(bookmark)
            return nil
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
        // If a number is immediately followed by a letter, it's not a number — bail.
        if let next = s.peek, next.isASCIILetter {
            s.restore(bookmark)
            return nil
        }
        return Token(range: bookmark..<s.index, type: .number)
    }

    private func scanWord(_ s: inout Scanner) -> Token {
        let start = s.index
        s.consume { $0.isIdentifierPart || $0 == "-" || $0 == "." }
        let word = wordSlice(from: start, to: s.index, in: s)

        // Look ahead — if followed (after optional spaces) by ':', this is a mapping key.
        let bookmark = s.mark()
        while s.peek == " " { s.advance() }
        if s.peek == ":" && (s.peek(offset: 1) == " " || s.peek(offset: 1) == "\n" || s.peek(offset: 1) == nil) {
            s.restore(bookmark)
            return Token(range: start..<s.index, type: .attribute)
        }
        s.restore(bookmark)

        if Self.constants.contains(word) {
            return Token(range: start..<s.index, type: .constant)
        }
        return Token(range: start..<s.index, type: .identifier)
    }

    private func wordSlice(from start: String.Index, to end: String.Index, in s: Scanner) -> String {
        String(s.source[start..<end])
    }
}
