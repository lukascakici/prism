import Foundation

/// Tokenizer protocol for a source language.
/// Adding a new language = write a new struct that adopts this protocol + register it.
protocol Tokenizer {
    /// Splits the given source text into tokens.
    /// Tokens are returned in source order; their ranges do not overlap.
    func tokenize(_ source: String) -> [Token]
}
