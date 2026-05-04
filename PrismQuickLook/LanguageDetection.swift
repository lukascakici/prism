import Foundation
import UniformTypeIdentifiers

/// Dosya URL'sinden kaynak dilini tespit eden yardımcı.
///
/// Önce UTI üzerinden, çözümlenemezse uzantıya düşerek belirler.
/// UTI tabanlı yaklaşım filename'siz veya tuhaf uzantılı dosyalarda da çalışır.
enum LanguageDetection {

    static func detect(for url: URL) -> SourceLanguage {

        // 1) UTI ile dene (macOS 11+'da UTType API'si tercih ediliyor).
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            if type.conforms(to: .json) { return .json }
            if type.conforms(to: .pythonScript) { return .python }
            if type.conforms(to: .swiftSource) { return .swift }
        }

        // 2) Fallback: uzantı.
        switch url.pathExtension.lowercased() {
        case "json":         return .json
        case "py", "pyw":    return .python
        case "swift":        return .swift
        default:             return .plain
        }
    }
}

private extension UTType {
    // SDK'da hazır gelmeyebilen UTI'leri identifier üzerinden tanımlıyoruz.
    static var pythonScript: UTType {
        UTType("public.python-script") ?? .sourceCode
    }
    static var swiftSource: UTType {
        UTType("public.swift-source") ?? .sourceCode
    }
}
