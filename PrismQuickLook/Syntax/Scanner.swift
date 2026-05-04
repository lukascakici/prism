import Foundation

/// Tokenizer'ların kullandığı düşük seviyeli karakter cursor'u.
/// String.Index üzerinde çalışır — Unicode-safe.
struct Scanner {
    let source: String
    var index: String.Index

    init(_ source: String) {
        self.source = source
        self.index = source.startIndex
    }

    /// Bookmark al — sonra `restore(_:)` ile geri dönebilirsin.
    func mark() -> String.Index { index }

    /// Önceden alınmış bookmark'a geri sar.
    mutating func restore(_ bookmark: String.Index) { index = bookmark }

    var isAtEnd: Bool { index >= source.endIndex }

    /// Cursor'daki karakter — advance etmez.
    var peek: Character? {
        isAtEnd ? nil : source[index]
    }

    /// Cursor'dan `offset` ileri bakar.
    func peek(offset: Int) -> Character? {
        guard let i = source.index(index, offsetBy: offset, limitedBy: source.endIndex),
              i < source.endIndex else { return nil }
        return source[i]
    }

    /// Cursor'ı bir karakter ileri al ve eski karakteri döndür.
    @discardableResult
    mutating func advance() -> Character? {
        guard !isAtEnd else { return nil }
        let c = source[index]
        index = source.index(after: index)
        return c
    }

    /// Predicate doğru olduğu sürece advance et. start..<end aralığı döner.
    @discardableResult
    mutating func consume(while predicate: (Character) -> Bool) -> Range<String.Index> {
        let start = index
        while let c = peek, predicate(c) { advance() }
        return start..<index
    }

    /// Verilen karakter cursor'da ise advance et ve true dön.
    @discardableResult
    mutating func match(_ char: Character) -> Bool {
        guard peek == char else { return false }
        advance()
        return true
    }

    /// Verilen string cursor'dan başlıyorsa advance et ve true dön.
    @discardableResult
    mutating func match(_ str: String) -> Bool {
        guard let end = source.index(index, offsetBy: str.count, limitedBy: source.endIndex),
              source[index..<end] == str else { return false }
        index = end
        return true
    }

    /// Cursor'daki string source'da `prefix` ile mi başlıyor?
    func startsWith(_ prefix: String) -> Bool {
        guard let end = source.index(index, offsetBy: prefix.count, limitedBy: source.endIndex)
        else { return false }
        return source[index..<end] == prefix
    }
}

extension Character {
    var isASCIILetter: Bool { isLetter && isASCII }
    var isASCIIDigit: Bool { isNumber && isASCII }
    /// Identifier başlangıcı: harf veya alt çizgi.
    var isIdentifierStart: Bool { isASCIILetter || self == "_" }
    /// Identifier devamı: harf, rakam veya alt çizgi.
    var isIdentifierPart: Bool { isASCIILetter || isASCIIDigit || self == "_" }
}
