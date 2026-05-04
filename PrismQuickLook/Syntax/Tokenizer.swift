import Foundation

/// Bir kaynak dilinin tokenizer protokolü.
/// Yeni dil eklemek = bu protokolü adopte eden yeni bir struct yaz + registry'e kaydet.
protocol Tokenizer {
    /// Verilen kaynak metni token'larına ayırır.
    /// Token'lar source içindeki sıraya göre döner; aralıklar üst üste binmez.
    func tokenize(_ source: String) -> [Token]
}
