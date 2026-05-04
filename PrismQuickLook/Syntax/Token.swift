import Foundation

/// The type of a token. Theme colors are mapped from here.
/// If you add a new type, add it to SyntaxTheme as well.
enum TokenType {
    case plain          // No color applied (default text color)
    case keyword        // if, for, def, func, class…
    case identifier     // variable/function names (usually left uncolored)
    case type           // Capitalized type names
    case string         // "..." '...' """..."""
    case number         // 42, 3.14, 0xff, 0b101
    case comment        // // # /* */
    case `operator`     // + - * / = ==
    case punctuation    // { } [ ] ( ) , ; :
    case attribute      // @decorator @available
    case constant       // true, false, null, nil, None
    case function       // name in a function definition
}

/// A token range in the source text.
struct Token {
    let range: Range<String.Index>
    let type: TokenType
}
