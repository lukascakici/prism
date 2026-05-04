import Foundation

/// Parametric tokenizer for the broad C/Java/JS/Rust family of languages.
///
/// Handles the syntactic features they share (line + block comments, string
/// literals, numeric literals, identifier classification) and toggles
/// language-specific flourishes (nested block comments, template literals,
/// raw strings, attribute syntaxes) via `Config`.
struct CFamilyTokenizer: Tokenizer {

    struct Config {
        let keywords: Set<String>
        let constants: Set<String>
        /// Whether `'x'` is a single-quoted string (JS/TS). When false, `'x'`
        /// is a char literal — closed at the next `'` even across multiple chars.
        let allowSingleQuoteStrings: Bool
        /// Whether `` `…` `` is a string literal (JS/TS template, Go raw, Kotlin).
        let allowBacktickStrings: Bool
        /// Whether block comments can nest (Rust, Kotlin).
        let allowNestedBlockComments: Bool
        /// Whether `r"…"` and `r#"…"#` are recognized (Rust).
        let allowRustRawStrings: Bool
        /// Whether `@identifier` is treated as an attribute/decorator.
        let allowAtAttributes: Bool
        /// `@`-prefixed words treated as keywords (Obj-C: @interface, @end, …).
        let atKeywords: Set<String>
        /// Whether `#[…]` / `#![…]` are Rust attributes.
        let allowHashAttributes: Bool
        /// Whether `#…` to end-of-line is a preprocessor directive (C/C++/Obj-C/C#).
        let allowHashPreprocessor: Bool
        /// Whether `'a` is a Rust lifetime instead of a char literal.
        let allowRustLifetimes: Bool
        /// Whether `name!(…)` is a Rust macro invocation.
        let allowRustMacros: Bool
        /// Keywords that introduce a function definition — next identifier is colored .function.
        let funcDefKeywords: Set<String>
        /// Keywords that introduce a type definition — next identifier is colored .type.
        let typeDefKeywords: Set<String>
    }

    let config: Config

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)
        var pendingFunc = false
        var pendingType = false

        while !s.isAtEnd {
            guard let c = s.peek else { break }

            if c.isWhitespace { s.advance(); continue }

            // Line comment
            if c == "/" && s.peek(offset: 1) == "/" {
                let start = s.index
                s.consume { $0 != "\n" }
                tokens.append(Token(range: start..<s.index, type: .comment))
                continue
            }

            // Block comment (with optional nesting)
            if c == "/" && s.peek(offset: 1) == "*" {
                tokens.append(scanBlockComment(&s))
                continue
            }

            // Double-quoted strings
            if c == "\"" {
                tokens.append(scanDoubleQuoted(&s))
                continue
            }

            // Single quote: lifetime, char literal, or single-quoted string
            if c == "'" {
                if config.allowRustLifetimes,
                   let next = s.peek(offset: 1),
                   (next.isASCIILetter || next == "_") {
                    // Distinguish 'a (lifetime) from 'x' (char). A lifetime has no
                    // closing quote within ~2 characters.
                    let bookmark = s.mark()
                    s.advance()
                    s.consume { $0.isIdentifierPart }
                    if s.peek != "'" {
                        tokens.append(Token(range: bookmark..<s.index, type: .attribute))
                        continue
                    }
                    s.restore(bookmark)
                }
                if config.allowSingleQuoteStrings {
                    tokens.append(scanSingleQuotedString(&s))
                } else {
                    tokens.append(scanCharLiteral(&s))
                }
                continue
            }

            // Backtick strings (JS template literals, Go raw, Kotlin backticked ident)
            if config.allowBacktickStrings && c == "`" {
                tokens.append(scanBacktickString(&s))
                continue
            }

            // Rust raw strings: r"…" / r#"…"#
            if config.allowRustRawStrings && c == "r" {
                let bookmark = s.mark()
                s.advance() // r
                var hashes = 0
                while s.peek == "#" { s.advance(); hashes += 1 }
                if s.peek == "\"" {
                    tokens.append(scanRustRawString(&s, start: bookmark, hashes: hashes))
                    continue
                }
                s.restore(bookmark)
            }

            // Rust byte strings: b"…" / b'…'
            if config.allowRustRawStrings && c == "b",
               let next = s.peek(offset: 1), next == "\"" || next == "'" {
                let start = s.index
                s.advance() // b
                let inner = (next == "\"") ? scanDoubleQuoted(&s) : scanCharLiteral(&s)
                tokens.append(Token(range: start..<inner.range.upperBound, type: .string))
                continue
            }

            // Rust hash attributes: #[…] / #![…]
            if config.allowHashAttributes && c == "#" {
                let bookmark = s.mark()
                s.advance()
                if s.peek == "!" { s.advance() }
                if s.peek == "[" {
                    var depth = 0
                    while !s.isAtEnd {
                        if s.peek == "[" { depth += 1 }
                        else if s.peek == "]" { depth -= 1; if depth == 0 { s.advance(); break } }
                        s.advance()
                    }
                    tokens.append(Token(range: bookmark..<s.index, type: .attribute))
                    continue
                }
                s.restore(bookmark)
            }

            // Hash preprocessor (C/C++/Obj-C/C#)
            if config.allowHashPreprocessor && c == "#" {
                let start = s.index
                s.consume { $0 != "\n" }
                tokens.append(Token(range: start..<s.index, type: .keyword))
                continue
            }

            // @-prefixed (decorator / Obj-C @-keyword)
            if config.allowAtAttributes && c == "@" {
                let start = s.index
                s.advance()
                s.consume { $0.isIdentifierPart }
                let word = String(source[start..<s.index])
                let type: TokenType = config.atKeywords.contains(word) ? .keyword : .attribute
                tokens.append(Token(range: start..<s.index, type: type))
                continue
            }

            // Numbers
            if c.isASCIIDigit {
                tokens.append(scanNumber(&s))
                continue
            }
            if c == "." && (s.peek(offset: 1)?.isASCIIDigit == true) {
                tokens.append(scanNumber(&s))
                continue
            }

            // Identifier / keyword / type / constant / function / macro
            if c.isIdentifierStart {
                let start = s.index
                s.consume { $0.isIdentifierPart }
                var endIndex = s.index
                let word = String(source[start..<endIndex])

                // Rust macro: name!(…) / name![…] / name!{…}
                if config.allowRustMacros, s.peek == "!",
                   let after = s.peek(offset: 1), "([{".contains(after) {
                    s.advance()
                    endIndex = s.index
                    tokens.append(Token(range: start..<endIndex, type: .function))
                    continue
                }

                let type: TokenType
                if pendingFunc {
                    pendingFunc = false
                    type = .function
                } else if pendingType {
                    pendingType = false
                    type = .type
                } else if config.constants.contains(word) {
                    type = .constant
                } else if config.keywords.contains(word) {
                    if config.funcDefKeywords.contains(word) { pendingFunc = true }
                    if config.typeDefKeywords.contains(word) { pendingType = true }
                    type = .keyword
                } else if let first = word.first, first.isUppercase, word.count > 1 {
                    // PascalCase heuristic → type
                    type = .type
                } else {
                    type = .identifier
                }
                tokens.append(Token(range: start..<endIndex, type: type))
                continue
            }

            // Punctuation
            if "(){}[],;:".contains(c) {
                let start = s.index
                s.advance()
                tokens.append(Token(range: start..<s.index, type: .punctuation))
                continue
            }
            // Operators
            if "+-*/%=<>!&|^~?.".contains(c) {
                let start = s.index
                s.consume { "+-*/%=<>!&|^~?.".contains($0) }
                tokens.append(Token(range: start..<s.index, type: .operator))
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
        var depth = 1
        while !s.isAtEnd && depth > 0 {
            if config.allowNestedBlockComments,
               s.peek == "/", s.peek(offset: 1) == "*" {
                s.advance(); s.advance(); depth += 1
            } else if s.peek == "*", s.peek(offset: 1) == "/" {
                s.advance(); s.advance(); depth -= 1
            } else {
                s.advance()
            }
        }
        return Token(range: start..<s.index, type: .comment)
    }

    private func scanDoubleQuoted(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // "
        while let c = s.peek, c != "\"" {
            if c == "\\" {
                s.advance()
                if !s.isAtEnd { s.advance() }
            } else if c == "\n" {
                break
            } else {
                s.advance()
            }
        }
        if s.peek == "\"" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanSingleQuotedString(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // '
        while let c = s.peek, c != "'" {
            if c == "\\" {
                s.advance()
                if !s.isAtEnd { s.advance() }
            } else if c == "\n" {
                break
            } else {
                s.advance()
            }
        }
        if s.peek == "'" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanCharLiteral(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // '
        if s.peek == "\\" {
            s.advance()
            // Escape can span several chars (\xNN, \u{...}, \uNNNN); read until next '.
            while let c = s.peek, c != "'" && c != "\n" { s.advance() }
        } else if let c = s.peek, c != "'" && c != "\n" {
            s.advance()
            while let cc = s.peek, cc != "'" && cc != "\n" { s.advance() }
        }
        if s.peek == "'" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanBacktickString(_ s: inout Scanner) -> Token {
        let start = s.index
        s.advance() // `
        while let c = s.peek, c != "`" {
            if c == "\\" {
                s.advance()
                if !s.isAtEnd { s.advance() }
            } else if c == "$", s.peek(offset: 1) == "{" {
                // ${…} interpolation — keep whole thing as string for simplicity.
                s.advance(); s.advance()
                var depth = 1
                while !s.isAtEnd && depth > 0 {
                    if s.peek == "{" { depth += 1 }
                    else if s.peek == "}" { depth -= 1; if depth == 0 { s.advance(); break } }
                    s.advance()
                }
            } else {
                s.advance()
            }
        }
        if s.peek == "`" { s.advance() }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanRustRawString(_ s: inout Scanner, start: String.Index, hashes: Int) -> Token {
        s.advance() // opening "
        let closing = String(repeating: "#", count: hashes)
        while !s.isAtEnd {
            if s.peek == "\"" {
                let bookmark = s.mark()
                s.advance()
                if hashes == 0 || s.match(closing) {
                    return Token(range: start..<s.index, type: .string)
                }
                s.restore(bookmark)
                s.advance()
            } else {
                s.advance()
            }
        }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanNumber(_ s: inout Scanner) -> Token {
        let start = s.index
        if s.peek == "0", let next = s.peek(offset: 1), "xXoObB".contains(next) {
            s.advance(); s.advance()
            s.consume { $0.isHexDigit || $0 == "_" }
            // Trailing type suffix (Rust: i32/u64; JS: n)
            s.consume { $0.isASCIILetter || $0.isASCIIDigit || $0 == "_" }
            return Token(range: start..<s.index, type: .number)
        }
        s.consume { $0.isASCIIDigit || $0 == "_" }
        if s.peek == ".", let next = s.peek(offset: 1), next.isASCIIDigit {
            s.advance()
            s.consume { $0.isASCIIDigit || $0 == "_" }
        }
        if s.peek == "e" || s.peek == "E" {
            s.advance()
            if s.peek == "+" || s.peek == "-" { s.advance() }
            s.consume { $0.isASCIIDigit }
        }
        // Type suffix (L, U, F, D, M, n, i32, u64, f64…)
        s.consume { $0.isASCIILetter || $0.isASCIIDigit || $0 == "_" }
        return Token(range: start..<s.index, type: .number)
    }
}

// MARK: - Per-language configurations

extension CFamilyTokenizer.Config {

    static let javascript = CFamilyTokenizer.Config(
        keywords: [
            "break", "case", "catch", "class", "const", "continue", "debugger",
            "default", "delete", "do", "else", "export", "extends", "finally",
            "for", "function", "if", "import", "in", "instanceof", "let", "new",
            "of", "from", "as", "return", "super", "switch", "this", "throw",
            "try", "typeof", "var", "void", "while", "with", "yield",
            "async", "await", "static", "get", "set",
        ],
        constants: ["true", "false", "null", "undefined", "NaN", "Infinity", "globalThis"],
        allowSingleQuoteStrings: true,
        allowBacktickStrings: true,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: true,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: false,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: ["function"],
        typeDefKeywords: ["class"]
    )

    static let typescript = CFamilyTokenizer.Config(
        keywords: javascript.keywords.union([
            "abstract", "any", "asserts", "bigint", "boolean", "declare", "enum",
            "implements", "infer", "interface", "is", "keyof", "module",
            "namespace", "never", "number", "object", "override", "private",
            "protected", "public", "readonly", "satisfies", "string", "symbol",
            "type", "unknown",
        ]),
        constants: javascript.constants,
        allowSingleQuoteStrings: true,
        allowBacktickStrings: true,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: true,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: false,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: ["function"],
        typeDefKeywords: ["class", "interface", "enum", "type", "namespace"]
    )

    static let c = CFamilyTokenizer.Config(
        keywords: [
            "auto", "break", "case", "char", "const", "continue", "default",
            "do", "double", "else", "enum", "extern", "float", "for", "goto",
            "if", "inline", "int", "long", "register", "restrict", "return",
            "short", "signed", "sizeof", "static", "struct", "switch", "typedef",
            "union", "unsigned", "void", "volatile", "while",
            "_Bool", "_Atomic", "_Generic", "_Alignas", "_Alignof", "_Noreturn",
            "_Static_assert", "_Thread_local",
        ],
        constants: ["NULL", "true", "false"],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: false,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: false,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: true,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: [],
        typeDefKeywords: ["struct", "union", "enum", "typedef"]
    )

    static let cpp = CFamilyTokenizer.Config(
        keywords: [
            "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor",
            "bool", "break", "case", "catch", "char", "char8_t", "char16_t",
            "char32_t", "class", "compl", "concept", "const", "consteval",
            "constexpr", "constinit", "const_cast", "continue", "co_await",
            "co_return", "co_yield", "decltype", "default", "delete", "do",
            "double", "dynamic_cast", "else", "enum", "explicit", "export",
            "extern", "final", "float", "for", "friend", "goto", "if", "inline",
            "int", "long", "module", "mutable", "namespace", "new", "noexcept",
            "not", "not_eq", "operator", "or", "or_eq", "override", "private",
            "protected", "public", "register", "reinterpret_cast", "requires",
            "return", "short", "signed", "sizeof", "static", "static_assert",
            "static_cast", "struct", "switch", "template", "this", "thread_local",
            "throw", "try", "typedef", "typeid", "typename", "union", "unsigned",
            "using", "virtual", "void", "volatile", "wchar_t", "while", "xor",
            "xor_eq",
        ],
        constants: ["nullptr", "NULL", "true", "false"],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: false,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: false,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: true,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: [],
        typeDefKeywords: ["class", "struct", "union", "enum", "typedef", "namespace"]
    )

    static let objectiveC = CFamilyTokenizer.Config(
        keywords: c.keywords.union([
            "id", "Class", "SEL", "IMP", "BOOL", "instancetype",
            // Obj-C++ inclusions
            "class", "namespace", "template", "typename", "this", "new", "delete",
            "public", "private", "protected", "operator",
        ]),
        constants: ["YES", "NO", "nil", "Nil", "NULL", "true", "false"],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: false,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: true,
        atKeywords: [
            "@interface", "@implementation", "@protocol", "@end", "@class",
            "@property", "@synthesize", "@dynamic", "@selector", "@encode",
            "@autoreleasepool", "@synchronized", "@try", "@catch", "@finally",
            "@throw", "@public", "@private", "@protected", "@package",
            "@optional", "@required", "@import", "@available",
        ],
        allowHashAttributes: false,
        allowHashPreprocessor: true,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: [],
        typeDefKeywords: ["struct", "union", "enum", "typedef", "class"]
    )

    static let java = CFamilyTokenizer.Config(
        keywords: [
            "abstract", "assert", "boolean", "break", "byte", "case", "catch",
            "char", "class", "const", "continue", "default", "do", "double",
            "else", "enum", "extends", "final", "finally", "float", "for",
            "goto", "if", "implements", "import", "instanceof", "int", "interface",
            "long", "native", "new", "package", "permits", "private", "protected",
            "public", "record", "return", "sealed", "short", "static", "strictfp",
            "super", "switch", "synchronized", "this", "throw", "throws",
            "transient", "try", "var", "void", "volatile", "while", "yield",
        ],
        constants: ["true", "false", "null"],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: false,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: true,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: false,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: [],
        typeDefKeywords: ["class", "interface", "enum", "record"]
    )

    static let kotlin = CFamilyTokenizer.Config(
        keywords: [
            "as", "break", "by", "class", "companion", "const", "constructor",
            "continue", "crossinline", "data", "do", "else", "enum", "field",
            "file", "final", "finally", "for", "fun", "get", "if", "import",
            "in", "infix", "init", "inline", "inner", "interface", "internal",
            "is", "lateinit", "noinline", "object", "open", "operator", "out",
            "override", "package", "param", "private", "property", "protected",
            "public", "receiver", "reified", "return", "sealed", "set",
            "setparam", "super", "suspend", "tailrec", "this", "throw", "try",
            "typealias", "typeof", "val", "value", "var", "vararg", "when",
            "where", "while", "delegate", "dynamic", "expect", "actual",
        ],
        constants: ["true", "false", "null"],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: true,
        allowNestedBlockComments: true,
        allowRustRawStrings: false,
        allowAtAttributes: true,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: false,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: ["fun"],
        typeDefKeywords: ["class", "interface", "enum", "object", "typealias"]
    )

    static let go = CFamilyTokenizer.Config(
        keywords: [
            "break", "case", "chan", "const", "continue", "default", "defer",
            "else", "fallthrough", "for", "func", "go", "goto", "if", "import",
            "interface", "map", "package", "range", "return", "select", "struct",
            "switch", "type", "var",
        ],
        constants: [
            "true", "false", "nil", "iota",
            "append", "cap", "close", "complex", "copy", "delete", "imag", "len",
            "make", "new", "panic", "print", "println", "real", "recover",
        ],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: true,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: false,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: false,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: ["func"],
        typeDefKeywords: ["struct", "interface", "type"]
    )

    static let rust = CFamilyTokenizer.Config(
        keywords: [
            "as", "async", "await", "break", "const", "continue", "crate", "dyn",
            "else", "enum", "extern", "fn", "for", "if", "impl", "in", "let",
            "loop", "match", "mod", "move", "mut", "pub", "ref", "return", "Self",
            "self", "static", "struct", "super", "trait", "type", "unsafe", "use",
            "where", "while", "abstract", "become", "box", "do", "final", "macro",
            "override", "priv", "typeof", "unsized", "virtual", "yield", "try",
            "union",
        ],
        constants: ["true", "false", "None", "Some", "Ok", "Err"],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: false,
        allowNestedBlockComments: true,
        allowRustRawStrings: true,
        allowAtAttributes: false,
        atKeywords: [],
        allowHashAttributes: true,
        allowHashPreprocessor: false,
        allowRustLifetimes: true,
        allowRustMacros: true,
        funcDefKeywords: ["fn"],
        typeDefKeywords: ["struct", "enum", "trait", "type", "union", "mod"]
    )

    static let csharp = CFamilyTokenizer.Config(
        keywords: [
            "abstract", "as", "base", "bool", "break", "byte", "case", "catch",
            "char", "checked", "class", "const", "continue", "decimal", "default",
            "delegate", "do", "double", "else", "enum", "event", "explicit",
            "extern", "finally", "fixed", "float", "for", "foreach", "goto", "if",
            "implicit", "in", "int", "interface", "internal", "is", "lock",
            "long", "namespace", "new", "object", "operator", "out", "override",
            "params", "private", "protected", "public", "readonly", "ref",
            "return", "sbyte", "sealed", "short", "sizeof", "stackalloc",
            "static", "string", "struct", "switch", "this", "throw", "try",
            "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using",
            "virtual", "void", "volatile", "while", "async", "await", "var",
            "dynamic", "yield", "partial", "where", "get", "set", "value", "init",
            "record", "with", "global", "nameof",
        ],
        constants: ["true", "false", "null"],
        allowSingleQuoteStrings: false,
        allowBacktickStrings: false,
        allowNestedBlockComments: false,
        allowRustRawStrings: false,
        allowAtAttributes: false,
        atKeywords: [],
        allowHashAttributes: false,
        allowHashPreprocessor: true,
        allowRustLifetimes: false,
        allowRustMacros: false,
        funcDefKeywords: [],
        typeDefKeywords: ["class", "struct", "interface", "enum", "record", "namespace"]
    )
}

private extension Character {
    var isHexDigit: Bool { hexDigitValue != nil }
}
