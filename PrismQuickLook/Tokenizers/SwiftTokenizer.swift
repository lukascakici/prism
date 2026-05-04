import Foundation

/// Tokenizer for Swift 5+.
/// Supports:
/// - // line comments, /* ... */ block comments (nested!)
/// - String: "...", """...""", #"..."# (raw)
/// - String interpolation \(…) — kept simple (colored as string)
/// - Number: int, float, 0x hex, 0b bin, 0o oct
/// - Keywords (Swift Lang Reference 5.9 list)
/// - Constants: true, false, nil
/// - Type identifier: Capitalized (heuristic)
/// - Function definition names
/// - Attributes: @available, @objc, @propertyWrapper…
struct SwiftTokenizer: Tokenizer {

    private static let keywords: Set<String> = [
        // Declaration
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
        "func", "import", "init", "inout", "internal", "let", "open", "operator",
        "private", "precedencegroup", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var",
        // Statement
        "break", "case", "catch", "continue", "default", "defer", "do", "else",
        "fallthrough", "for", "guard", "if", "in", "repeat", "return", "throw",
        "switch", "where", "while",
        // Expression / type
        "Any", "as", "catch", "false", "is", "nil", "rethrows", "self", "Self",
        "super", "throws", "true", "try",
        // Concurrency / modern
        "async", "await", "actor", "isolated", "nonisolated", "distributed",
        "some", "any", "consume", "borrowing", "consuming",
        // Pattern
        "_",
        // Modifiers
        "final", "lazy", "optional", "override", "required", "weak", "unowned",
        "convenience", "dynamic", "indirect", "mutating", "nonmutating", "prefix",
        "postfix", "infix", "associativity", "left", "right", "none",
    ]

    private static let constants: Set<String> = ["true", "false", "nil"]

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)
        var pendingFunctionDef = false
        var pendingTypeDef = false

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            if c.isWhitespace { s.advance(); continue }

            // Line comment: // ...
            if c == "/" && s.peek(offset: 1) == "/" {
                let start = s.index
                s.consume { $0 != "\n" }
                tokens.append(Token(range: start..<s.index, type: .comment))
                continue
            }

            // Block comment: /* ... */ (nested)
            if c == "/" && s.peek(offset: 1) == "*" {
                tokens.append(scanBlockComment(&s))
                continue
            }

            // Raw string: #"..."# (must match n leading and trailing #)
            if c == "#" {
                let mark = s.index
                var hashes = 0
                while s.peek == "#" { s.advance(); hashes += 1 }
                if s.peek == "\"" {
                    tokens.append(scanRawString(&s, start: mark, hashes: hashes))
                    continue
                }
                // Starts with # but isn't a string: directive (#if, #file…) — color as keyword.
                s.consume { $0.isIdentifierPart }
                tokens.append(Token(range: mark..<s.index, type: .keyword))
                continue
            }

            // Attribute: @identifier
            if c == "@" {
                let start = s.index
                s.advance()
                s.consume { $0.isIdentifierPart }
                tokens.append(Token(range: start..<s.index, type: .attribute))
                continue
            }

            // String "..." or """..."""
            if c == "\"" {
                tokens.append(scanString(&s))
                continue
            }

            // Number
            if c.isASCIIDigit {
                tokens.append(scanNumber(&s))
                continue
            }

            // Identifier / keyword / type / constant
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
                    if word == "func" { pendingFunctionDef = true }
                    if ["class","struct","enum","protocol","actor","extension","typealias","associatedtype"].contains(word) {
                        pendingTypeDef = true
                    }
                    type = .keyword
                } else if word.first?.isUppercase == true {
                    // Heuristic: PascalCase → type.
                    type = .type
                } else {
                    type = .identifier
                }
                tokens.append(Token(range: start..<s.index, type: type))
                continue
            }

            // Punctuation
            if "(){}[],;:".contains(c) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }
            // Operators (rich set in Swift; collect simply)
            if "+-*/%=<>!&|^~?.".contains(c) {
                let start = s.index
                s.consume { "+-*/%=<>!&|^~?.".contains($0) }
                tokens.append(Token(range: start..<s.index, type: .operator))
                continue
            }

            // Unknown
            s.advance()
        }
        return tokens
    }

    // MARK: - Helpers

    private func scanBlockComment(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance(); s.advance() // /*
        var depth = 1
        while !s.isAtEnd && depth > 0 {
            if s.peek == "/" && s.peek(offset: 1) == "*" {
                s.advance(); s.advance(); depth += 1
            } else if s.peek == "*" && s.peek(offset: 1) == "/" {
                s.advance(); s.advance(); depth -= 1
            } else {
                s.advance()
            }
        }
        return Token(range: start..<s.index, type: .comment)
    }

    private func scanString(_ s: inout Scanner) -> Token {
        let start = s.index

        // Triple """..."""
        if s.startsWith("\"\"\"") {
            s.match("\"\"\"")
            while !s.isAtEnd && !s.startsWith("\"\"\"") {
                if s.peek == "\\" { s.advance(); if !s.isAtEnd { s.advance() } }
                else { s.advance() }
            }
            s.match("\"\"\"")
            return Token(range: start..<s.index, type: .string)
        }

        // Single-line "..."
        s.advance() // opening "
        while let c = s.peek, c != "\"", c != "\n" {
            if c == "\\" { s.advance(); if !s.isAtEnd { s.advance() } }
            else { s.advance() }
        }
        if s.peek == "\"" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    /// Raw string: ##"..."## (starts with n hashes, ends with the same number).
    private func scanRawString(_ s: inout Scanner, start: String.Index, hashes: Int) -> Token {
        s.advance() // opening "
        let closingHashes = String(repeating: "#", count: hashes)
        while !s.isAtEnd {
            if s.peek == "\"" {
                let bookmark = s.mark()
                s.advance()
                if s.match(closingHashes) { break }
                else { s.restore(bookmark); s.advance() }
            } else {
                s.advance()
            }
        }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanNumber(_ s: inout Scanner) -> Token {
        let start = s.index
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
        return Token(range: start..<s.index, type: .number)
    }
}

private extension Character {
    var isHexDigit: Bool { hexDigitValue != nil }
}
