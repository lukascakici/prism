import Foundation

/// Memory-disciplined file reader.
///
/// `Data(contentsOf:)` loads the whole file into memory at once and, for large files,
/// can push the QL extension over its jetsam limit. Here we use `FileHandle` to read
/// up to `limit` bytes and intentionally drop the rest.
enum FileReader {

    /// - Parameters:
    ///   - url: File to read.
    ///   - limit: Memory cap (bytes).
    ///   - actualSize: Pre-known file size (from resourceValues).
    /// - Returns: (decoded UTF-8 text, was it truncated?)
    static func readBoundedUTF8(url: URL,
                                limit: Int,
                                actualSize: Int) throws -> (String, Bool) {

        let willTruncate = actualSize > limit
        let bytesToRead = min(actualSize, limit)

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        // macOS 12+ API. `read(upToCount:)` may return less than requested,
        // so we loop if a single call doesn't finish the read.
        var collected = Data()
        collected.reserveCapacity(bytesToRead)

        while collected.count < bytesToRead {
            let remaining = bytesToRead - collected.count
            guard let chunk = try handle.read(upToCount: remaining), !chunk.isEmpty else {
                break // EOF arrived earlier than expected — fine, return what we have.
            }
            collected.append(chunk)
        }

        // Try UTF-8; on failure fall back to permissive Latin-1 (will even render
        // binary garbage — we don't want the preview to crash).
        if let utf8 = String(data: collected, encoding: .utf8) {
            return (utf8, willTruncate)
        }
        if let latin = String(data: collected, encoding: .isoLatin1) {
            return (latin, willTruncate)
        }
        throw PreviewError.invalidEncoding(url)
    }
}

/// HTML escape helper — namespacing instead of a `String` extension avoids name collisions.
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
