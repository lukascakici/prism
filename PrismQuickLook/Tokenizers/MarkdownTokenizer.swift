import Foundation

/// Tokenizer for Markdown (CommonMark-flavored, lightweight).
/// Highlights:
/// - ATX headers (# ## ### …) — entire line
/// - Fenced code blocks (``` and ~~~) — entire block
/// - Inline code (`...`)
/// - Bold (**...**, __...__) and italic (*...*, _..._) — emphasis markers + content
/// - Links [text](url) and images ![alt](src)
/// - Blockquotes (> at start of line)
/// - List markers (-, *, +, 1.)
/// - Horizontal rules (---, ***, ___)
struct MarkdownTokenizer: Tokenizer {

    func tokenize(_ source: String) -> [Token] {
        var tokens: [Token] = []
        var s = Scanner(source)

        while !s.isAtEnd {
            let atLineStart = isAtLineStart(s, source: source)

            if atLineStart {
                // Skip leading spaces (up to 3) without consuming them as a separate token.
                var spaceCount = 0
                while s.peek == " " && spaceCount < 3 { s.advance(); spaceCount += 1 }

                // Fenced code block: ``` or ~~~
                if s.startsWith("```") || s.startsWith("~~~") {
                    tokens.append(scanFencedCodeBlock(&s))
                    continue
                }

                // ATX header: # to ###### followed by space
                if s.peek == "#" {
                    if let header = scanHeader(&s) {
                        tokens.append(header)
                        continue
                    }
                }

                // Blockquote: > at start of line — color the whole line as a comment.
                if s.peek == ">" {
                    let start = s.index
                    s.consume { $0 != "\n" }
                    tokens.append(Token(range: start..<s.index, type: .comment))
                    continue
                }

                // Horizontal rule: --- *** ___ alone on a line (3+ chars)
                if let hr = scanHorizontalRule(&s) {
                    tokens.append(hr)
                    continue
                }

                // List marker: -, *, + followed by space, or digits followed by . and space
                if let marker = scanListMarker(&s) {
                    tokens.append(marker)
                    continue
                }
            }

            guard let c = s.peek else { break }

            // Inline code: `...`
            if c == "`" {
                tokens.append(scanInlineCode(&s))
                continue
            }

            // Bold: ** or __ (greedy — try double-marker first)
            if (c == "*" || c == "_") && s.peek(offset: 1) == c {
                if let bold = scanEmphasis(&s, marker: c, doubled: true) {
                    tokens.append(bold)
                    continue
                }
            }

            // Italic: * or _
            if c == "*" || c == "_" {
                if let italic = scanEmphasis(&s, marker: c, doubled: false) {
                    tokens.append(italic)
                    continue
                }
            }

            // Image: ![alt](src) — leading ! then link
            if c == "!" && s.peek(offset: 1) == "[" {
                if let image = scanLink(&s, isImage: true) {
                    tokens.append(contentsOf: image)
                    continue
                }
            }

            // Link: [text](url)
            if c == "[" {
                if let link = scanLink(&s, isImage: false) {
                    tokens.append(contentsOf: link)
                    continue
                }
            }

            s.advance()
        }

        return tokens
    }

    // MARK: - Helpers

    private func isAtLineStart(_ s: Scanner, source: String) -> Bool {
        if s.index == source.startIndex { return true }
        let prev = source.index(before: s.index)
        return source[prev] == "\n"
    }

    private func scanHeader(_ s: inout Scanner) -> Token? {
        let bookmark = s.mark()
        var hashes = 0
        while s.peek == "#" && hashes < 6 { s.advance(); hashes += 1 }
        // Header requires either end-of-line right after, or a space.
        if s.peek == " " || s.peek == "\t" || s.peek == "\n" || s.isAtEnd {
            s.consume { $0 != "\n" }
            return Token(range: bookmark..<s.index, type: .keyword)
        }
        s.restore(bookmark)
        return nil
    }

    private func scanFencedCodeBlock(_ s: inout Scanner) -> Token {
        let start = s.index
        let fence = s.peek == "`" ? "```" : "~~~"
        s.match(fence)
        // Consume info string up to newline (kept inside the code block token).
        s.consume { $0 != "\n" }
        if s.peek == "\n" { s.advance() }

        // Read lines until a closing fence at the start of a line, or EOF.
        while !s.isAtEnd {
            // Check if the current line starts with the closing fence (allow up to 3 leading spaces).
            let lineStart = s.mark()
            var spaces = 0
            while s.peek == " " && spaces < 3 { s.advance(); spaces += 1 }
            if s.startsWith(fence) {
                s.match(fence)
                s.consume { $0 != "\n" }
                if s.peek == "\n" { s.advance() }
                return Token(range: start..<s.index, type: .string)
            }
            s.restore(lineStart)
            s.consume { $0 != "\n" }
            if s.peek == "\n" { s.advance() }
        }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanInlineCode(_ s: inout Scanner) -> Token {
        let start = s.index
        // Count opening backticks — closing must match the same run length.
        var openCount = 0
        while s.peek == "`" { s.advance(); openCount += 1 }
        while !s.isAtEnd {
            if s.peek == "`" {
                var closeCount = 0
                let runStart = s.mark()
                while s.peek == "`" { s.advance(); closeCount += 1 }
                if closeCount == openCount { break }
                if closeCount > openCount {
                    // Overshot — back up so the extras stay in source.
                    s.restore(runStart)
                    s.advance()
                }
            } else if s.peek == "\n" {
                // Inline code shouldn't span more than two newlines; keep it simple — stop at first.
                break
            } else {
                s.advance()
            }
        }
        return Token(range: start..<s.index, type: .string)
    }

    private func scanEmphasis(_ s: inout Scanner, marker: Character, doubled: Bool) -> Token? {
        let bookmark = s.mark()
        let openCount = doubled ? 2 : 1
        for _ in 0..<openCount { s.advance() }

        // Don't allow whitespace right after the opening marker (CommonMark rule, simplified).
        if s.peek == nil || s.peek == " " || s.peek == "\n" {
            s.restore(bookmark)
            return nil
        }

        while !s.isAtEnd {
            if s.peek == "\n" {
                // Single line only — abort.
                s.restore(bookmark)
                return nil
            }
            if s.peek == marker {
                if doubled && s.peek(offset: 1) == marker {
                    s.advance(); s.advance()
                    return Token(range: bookmark..<s.index, type: doubled ? .constant : .type)
                }
                if !doubled {
                    s.advance()
                    return Token(range: bookmark..<s.index, type: .type)
                }
            }
            s.advance()
        }
        s.restore(bookmark)
        return nil
    }

    /// Returns multiple tokens because we color brackets and url separately.
    private func scanLink(_ s: inout Scanner, isImage: Bool) -> [Token]? {
        let bookmark = s.mark()
        if isImage { s.advance() } // !
        guard s.peek == "[" else { s.restore(bookmark); return nil }
        s.advance() // [

        // Find matching ]
        var depth = 1
        while !s.isAtEnd && depth > 0 {
            if s.peek == "\n" { s.restore(bookmark); return nil }
            if s.peek == "[" { depth += 1 }
            if s.peek == "]" { depth -= 1; if depth == 0 { break } }
            s.advance()
        }
        guard s.peek == "]" else { s.restore(bookmark); return nil }
        s.advance() // ]

        // Must be followed by ( for inline link.
        guard s.peek == "(" else { s.restore(bookmark); return nil }
        let urlStart = s.mark()
        s.advance() // (
        var pdepth = 1
        while !s.isAtEnd && pdepth > 0 {
            if s.peek == "\n" { s.restore(bookmark); return nil }
            if s.peek == "(" { pdepth += 1 }
            if s.peek == ")" { pdepth -= 1; if pdepth == 0 { break } }
            s.advance()
        }
        guard s.peek == ")" else { s.restore(bookmark); return nil }
        s.advance() // )

        // Two tokens: bracket span as keyword (text + brackets), paren span as string (url + parens).
        let textEnd = urlStart
        return [
            Token(range: bookmark..<textEnd, type: .keyword),
            Token(range: textEnd..<s.index, type: .string),
        ]
    }

    private func scanHorizontalRule(_ s: inout Scanner) -> Token? {
        let bookmark = s.mark()
        guard let first = s.peek, first == "-" || first == "*" || first == "_" else { return nil }
        var count = 0
        while s.peek == first || s.peek == " " {
            if s.peek == first { count += 1 }
            s.advance()
        }
        if count >= 3 && (s.peek == "\n" || s.isAtEnd) {
            return Token(range: bookmark..<s.index, type: .punctuation)
        }
        s.restore(bookmark)
        return nil
    }

    private func scanListMarker(_ s: inout Scanner) -> Token? {
        let bookmark = s.mark()
        if let c = s.peek, c == "-" || c == "*" || c == "+" {
            s.advance()
            if s.peek == " " || s.peek == "\t" {
                return Token(range: bookmark..<s.index, type: .keyword)
            }
            s.restore(bookmark)
            return nil
        }
        // Ordered list: digits followed by . or )
        if let c = s.peek, c.isASCIIDigit {
            while let c = s.peek, c.isASCIIDigit { s.advance() }
            if s.peek == "." || s.peek == ")" {
                s.advance()
                if s.peek == " " || s.peek == "\t" {
                    return Token(range: bookmark..<s.index, type: .keyword)
                }
            }
            s.restore(bookmark)
            return nil
        }
        return nil
    }
}
