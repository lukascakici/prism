import Foundation

/// Low-level character cursor used by tokenizers.
/// Operates on String.Index — Unicode-safe.
struct Scanner {
    let source: String
    var index: String.Index

    init(_ source: String) {
        self.source = source
        self.index = source.startIndex
    }

    /// Take a bookmark — you can later return to it with `restore(_:)`.
    func mark() -> String.Index { index }

    /// Rewind to a previously taken bookmark.
    mutating func restore(_ bookmark: String.Index) { index = bookmark }

    var isAtEnd: Bool { index >= source.endIndex }

    /// Character at the cursor — does not advance.
    var peek: Character? {
        isAtEnd ? nil : source[index]
    }

    /// Looks `offset` characters ahead of the cursor.
    func peek(offset: Int) -> Character? {
        guard let i = source.index(index, offsetBy: offset, limitedBy: source.endIndex),
              i < source.endIndex else { return nil }
        return source[i]
    }

    /// Advance the cursor by one character and return the previous character.
    @discardableResult
    mutating func advance() -> Character? {
        guard !isAtEnd else { return nil }
        let c = source[index]
        index = source.index(after: index)
        return c
    }

    /// Advance while the predicate holds. Returns the start..<end range.
    @discardableResult
    mutating func consume(while predicate: (Character) -> Bool) -> Range<String.Index> {
        let start = index
        while let c = peek, predicate(c) { advance() }
        return start..<index
    }

    /// If the given character is at the cursor, advance and return true.
    @discardableResult
    mutating func match(_ char: Character) -> Bool {
        guard peek == char else { return false }
        advance()
        return true
    }

    /// If the source starts with the given string at the cursor, advance and return true.
    @discardableResult
    mutating func match(_ str: String) -> Bool {
        guard let end = source.index(index, offsetBy: str.count, limitedBy: source.endIndex),
              source[index..<end] == str else { return false }
        index = end
        return true
    }

    /// Does the source at the cursor start with `prefix`?
    func startsWith(_ prefix: String) -> Bool {
        guard let end = source.index(index, offsetBy: prefix.count, limitedBy: source.endIndex)
        else { return false }
        return source[index..<end] == prefix
    }
}

extension Character {
    var isASCIILetter: Bool { isLetter && isASCII }
    var isASCIIDigit: Bool { isNumber && isASCII }
    /// Identifier start: letter or underscore.
    var isIdentifierStart: Bool { isASCIILetter || self == "_" }
    /// Identifier continuation: letter, digit, or underscore.
    var isIdentifierPart: Bool { isASCIILetter || isASCIIDigit || self == "_" }
}
