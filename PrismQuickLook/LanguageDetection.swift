import Foundation
import UniformTypeIdentifiers

/// Helper that detects the source language from a file URL.
///
/// Resolves via UTI first, falling back to the file extension if that fails.
/// The UTI-based approach also works for files without filenames or with unusual extensions.
enum LanguageDetection {

    static func detect(for url: URL) -> SourceLanguage {

        // 1) Try UTI first (the UTType API is preferred on macOS 11+).
        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            if type.conforms(to: .json) { return .json }
            if type.conforms(to: .pythonScript) { return .python }
            if type.conforms(to: .swiftSource) { return .swift }
        }

        // 2) Fallback: file extension.
        switch url.pathExtension.lowercased() {
        case "json":         return .json
        case "py", "pyw":    return .python
        case "swift":        return .swift
        default:             return .plain
        }
    }
}

private extension UTType {
    // Define UTIs by identifier since they may not be available out-of-the-box in the SDK.
    static var pythonScript: UTType {
        UTType("public.python-script") ?? .sourceCode
    }
    static var swiftSource: UTType {
        UTType("public.swift-source") ?? .sourceCode
    }
}
