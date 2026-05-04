import Foundation

/// Tokenizer for POSIX/Bash/Zsh shell scripts.
/// Highlights:
/// - # line comments
/// - "..." (interpolated) and '...' (literal) strings
/// - $var, ${var}, $1-$9, $@, $#, $*, $$, $!, $?
/// - Command substitution: $(...) and `...`
/// - Keywords: if/then/else/elif/fi, for/do/done, while/until, case/esac/in, function, return, break, continue, exit, source
/// - Numbers
/// - Operators and punctuation
struct ShellTokenizer: Tokenizer {

    private static let keywords: Set<String> = [
        "if", "then", "else", "elif", "fi",
        "for", "do", "done", "while", "until",
        "case", "esac", "in",
        "function", "return", "break", "continue", "exit",
        "select", "time", "coproc",
        "source", "export", "readonly", "declare", "local", "unset",
        "true", "false",
    ]

    private static let constants: Set<String> = ["true", "false"]

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)
        var pendingFunctionDef = false

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            if c.isWhitespace { s.advance(); continue }

            // Comment: # ... \n  (only when at start of word/line)
            if c == "#" {
                let start = s.index
                s.consume { $0 != "\n" }
                tokens.append(Token(range: start..<s.index, type: .comment))
                continue
            }

            // Strings
            if c == "\"" {
                tokens.append(scanDoubleQuoted(&s))
                continue
            }
            if c == "'" {
                tokens.append(scanSingleQuoted(&s))
                continue
            }

            // Backtick command substitution `...`
            if c == "`" {
                tokens.append(scanBackticks(&s))
                continue
            }

            // Variable / command substitution starting with $
            if c == "$" {
                if let token = scanDollar(&s) {
                    tokens.append(token)
                    continue
                }
            }

            // Number
            if c.isASCIIDigit {
                tokens.append(scanNumber(&s))
                continue
            }

            // Identifier / keyword
            if c.isIdentifierStart {
                let start = s.index
                s.consume { $0.isIdentifierPart || $0 == "-" }
                let word = String(source[start..<s.index])

                let type: TokenType
                if pendingFunctionDef {
                    pendingFunctionDef = false
                    type = .function
                } else if Self.constants.contains(word) {
                    type = .constant
                } else if Self.keywords.contains(word) {
                    if word == "function" { pendingFunctionDef = true }
                    type = .keyword
                } else {
                    type = .identifier
                }
                tokens.append(Token(range: start..<s.index, type: type))
                continue
            }

            // Punctuation
            if "(){};,".contains(c) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }

            // Operator
            if "|&<>=!+-*/%".contains(c) {
                let start = s.index
                s.consume { "|&<>=!+-*/%".contains($0) }
                tokens.append(Token(range: start..<s.index, type: .operator))
                continue
            }

            s.advance()
        }

        return tokens
    }

    // MARK: - Helpers

    private func scanSingleQuoted(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // '
        while let c = s.peek, c != "'" {
            s.advance()
        }
        if s.peek == "'" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanDoubleQuoted(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // "
        while let c = s.peek, c != "\"" {
            if c == "\\" {
                s.advance()
                if !s.isAtEnd { s.advance() }
            } else {
                s.advance()
            }
        }
        if s.peek == "\"" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanBackticks(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // `
        while let c = s.peek, c != "`" {
            if c == "\\" {
                s.advance()
                if !s.isAtEnd { s.advance() }
            } else {
                s.advance()
            }
        }
        if s.peek == "`" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanDollar(_ s: inout Scanner) -> Token? {
        let start = s.index
        s.advance() // $
        guard let next = s.peek else {
            return Token(range: start..<s.index, type: .identifier)
        }
        // ${...}
        if next == "{" {
            s.advance()
            var depth = 1
            while !s.isAtEnd && depth > 0 {
                if s.peek == "{" { depth += 1 }
                else if s.peek == "}" { depth -= 1; if depth == 0 { s.advance(); break } }
                s.advance()
            }
            return Token(range: start..<s.index, type: .attribute)
        }
        // $(...)
        if next == "(" {
            s.advance()
            var depth = 1
            while !s.isAtEnd && depth > 0 {
                if s.peek == "(" { depth += 1 }
                else if s.peek == ")" { depth -= 1; if depth == 0 { s.advance(); break } }
                s.advance()
            }
            return Token(range: start..<s.index, type: .attribute)
        }
        // $1..$9, $@, $#, $*, $$, $!, $?, $-, $0
        if next.isASCIIDigit || "@#*!?$-".contains(next) {
            s.advance()
            return Token(range: start..<s.index, type: .attribute)
        }
        // $name
        if next.isIdentifierStart {
            s.consume { $0.isIdentifierPart }
            return Token(range: start..<s.index, type: .attribute)
        }
        // Lone $
        return Token(range: start..<s.index, type: .identifier)
    }

    private func scanNumber(_ s: inout Scanner) -> Token {
        let start = s.index
        if s.peek == "0", let next = s.peek(offset: 1), "xX".contains(next) {
            s.advance(); s.advance()
            s.consume { $0.isHexDigit }
            return Token(range: start..<s.index, type: .number)
        }
        s.consume { $0.isASCIIDigit }
        if s.peek == "." {
            s.advance()
            s.consume { $0.isASCIIDigit }
        }
        return Token(range: start..<s.index, type: .number)
    }
}

private extension Character {
    var isHexDigit: Bool { hexDigitValue != nil }
}
