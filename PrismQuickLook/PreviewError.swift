import Foundation

/// Error types that can arise in the QuickLook preview pipeline.
/// Adopting `LocalizedError` lets us pass meaningful messages back to the host.
enum PreviewError: LocalizedError {
    case notReadable(URL)
    case bundleResourceMissing(String)
    case fileTooLargeToOpen(bytes: Int)
    case invalidEncoding(URL)

    var errorDescription: String? {
        switch self {
        case .notReadable(let url):
            return "Cannot read file: \(url.lastPathComponent). Check permissions."
        case .bundleResourceMissing(let name):
            return "Resource \(name) not found in extension bundle."
        case .fileTooLargeToOpen(let bytes):
            let str = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            return "File too large (\(str)). Preview could not be generated."
        case .invalidEncoding(let url):
            return "File could not be read as UTF-8: \(url.lastPathComponent)."
        }
    }
}
