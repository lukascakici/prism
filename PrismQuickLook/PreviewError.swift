import Foundation

/// QuickLook preview pipeline'ında oluşabilecek hata türleri.
/// `LocalizedError` adoptasyonu sayesinde host'a anlamlı mesajlar iletiyoruz.
enum PreviewError: LocalizedError {
    case notReadable(URL)
    case bundleResourceMissing(String)
    case fileTooLargeToOpen(bytes: Int)
    case invalidEncoding(URL)

    var errorDescription: String? {
        switch self {
        case .notReadable(let url):
            return "Dosya okunamıyor: \(url.lastPathComponent). Yetkiler kontrol edilmeli."
        case .bundleResourceMissing(let name):
            return "Eklenti bundle'ında \(name) kaynağı bulunamadı."
        case .fileTooLargeToOpen(let bytes):
            let str = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            return "Dosya çok büyük (\(str)). Önizleme oluşturulamadı."
        case .invalidEncoding(let url):
            return "Dosya UTF-8 olarak okunamadı: \(url.lastPathComponent)."
        }
    }
}
