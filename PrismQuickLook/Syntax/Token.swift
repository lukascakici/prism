import Foundation

/// Bir token'ın tipi. Tema renkleri buradan eşlenir.
/// Yeni bir tip eklemek istiyorsan SyntaxTheme'a da ekle.
enum TokenType {
    case plain          // Renk verilmez (default text color)
    case keyword        // if, for, def, func, class…
    case identifier     // değişken/fonksiyon isimleri (renksiz tutulur genelde)
    case type           // Capitalized type names
    case string         // "..." '...' """..."""
    case number         // 42, 3.14, 0xff, 0b101
    case comment        // // # /* */
    case `operator`     // + - * / = ==
    case punctuation    // { } [ ] ( ) , ; :
    case attribute      // @decorator @available
    case constant       // true, false, null, nil, None
    case function       // function tanımındaki isim
}

/// Kaynak metindeki bir token aralığı.
struct Token {
    let range: Range<String.Index>
    let type: TokenType
}
