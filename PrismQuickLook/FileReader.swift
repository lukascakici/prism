import Foundation

/// Bellek-disiplinli dosya okuyucu.
///
/// `Data(contentsOf:)` tüm dosyayı tek seferde belleğe alır ve büyük dosyalarda
/// QL eklentisinin jetsam limitini aşmasına yol açar. Burada `FileHandle` ile
/// `limit` byte'a kadar okuyup geri kalanı bilinçli olarak atıyoruz.
enum FileReader {

    /// - Parameters:
    ///   - url: Okunacak dosya.
    ///   - limit: Bellek tavanı (byte).
    ///   - actualSize: Önceden bilinen dosya boyutu (resourceValues'dan).
    /// - Returns: (decoded UTF-8 metin, truncated mi?)
    static func readBoundedUTF8(url: URL,
                                limit: Int,
                                actualSize: Int) throws -> (String, Bool) {

        let willTruncate = actualSize > limit
        let bytesToRead = min(actualSize, limit)

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        // macOS 12+ API. `read(upToCount:)` istenen miktardan az dönebilir;
        // bu yüzden tek çağrıyla bitiremezsek loop yapıyoruz.
        var collected = Data()
        collected.reserveCapacity(bytesToRead)

        while collected.count < bytesToRead {
            let remaining = bytesToRead - collected.count
            guard let chunk = try handle.read(upToCount: remaining), !chunk.isEmpty else {
                break // EOF beklenenden erken geldi — sorun değil, elimizdekini döneriz.
            }
            collected.append(chunk)
        }

        // UTF-8 dene; başarısız olursa permissive Latin-1 fallback (binary garbage'ı
        // bile gösterir; önizlemede crash etmek istemiyoruz).
        if let utf8 = String(data: collected, encoding: .utf8) {
            return (utf8, willTruncate)
        }
        if let latin = String(data: collected, encoding: .isoLatin1) {
            return (latin, willTruncate)
        }
        throw PreviewError.invalidEncoding(url)
    }
}

/// HTML escape yardımcısı — `String` extension yerine namespace'lemek ad çakışmasını önler.
enum HTMLEscaper {
    static func escape(_ input: String) -> String {
        var out = ""
        out.reserveCapacity(input.count)
        for ch in input {
            switch ch {
            case "&":  out.append("&amp;")
            case "<":  out.append("&lt;")
            case ">":  out.append("&gt;")
            case "\"": out.append("&quot;")
            case "'":  out.append("&#39;")
            default:   out.append(ch)
            }
        }
        return out
    }
}
