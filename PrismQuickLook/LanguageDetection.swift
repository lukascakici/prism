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
            if type.conforms(to: .shellScript) { return .shell }
            if type.conforms(to: .markdown) { return .markdown }
            if type.conforms(to: .yamlSource) { return .yaml }
            if type.conforms(to: .cssSource) { return .css }
            if type.conforms(to: .objectiveCPlusPlusSource) { return .objectiveC }
            if type.conforms(to: .objectiveCSource) { return .objectiveC }
            if type.conforms(to: .cPlusPlusSource) { return .cpp }
            if type.conforms(to: .cPlusPlusHeader) { return .cpp }
            if type.conforms(to: .cSource) { return .c }
            if type.conforms(to: .cHeader) { return .c }
            if type.conforms(to: .javaSource) { return .java }
            if type.conforms(to: .javascriptSource) { return .javascript }
            if type.conforms(to: .typescriptSource) { return .typescript }
            if type.conforms(to: .rustSource) { return .rust }
            if type.conforms(to: .goSource) { return .go }
            if type.conforms(to: .kotlinSource) { return .kotlin }
            if type.conforms(to: .csharpSource) { return .csharp }
        }

        // 2) Fallback: file extension.
        switch url.pathExtension.lowercased() {
        case "json":                                     return .json
        case "py", "pyw", "pyi":                         return .python
        case "swift":                                    return .swift
        case "md", "markdown", "mdown", "mkd":           return .markdown
        case "yml", "yaml":                              return .yaml
        case "sh", "bash", "zsh", "ksh", "command":     return .shell
        case "css":                                      return .css
        case "js", "mjs", "cjs", "jsx":                  return .javascript
        case "ts", "mts", "cts", "tsx":                  return .typescript
        case "c":                                        return .c
        case "h":                                        return .c
        case "cc", "cpp", "cxx", "c++", "hh", "hpp",
             "hxx", "h++", "ipp", "tpp":                 return .cpp
        case "m":                                        return .objectiveC
        case "mm":                                       return .objectiveC
        case "java":                                     return .java
        case "kt", "kts":                                return .kotlin
        case "go":                                       return .go
        case "rs":                                       return .rust
        case "cs", "csx":                                return .csharp
        default:                                         return .plain
        }
    }
}

private extension UTType {
    // System-defined UTIs — fall back to .sourceCode if missing on this OS.
    static var pythonScript: UTType {
        UTType("public.python-script") ?? .sourceCode
    }
    static var swiftSource: UTType {
        UTType("public.swift-source") ?? .sourceCode
    }
    static var shellScript: UTType {
        UTType("public.shell-script") ?? .sourceCode
    }
    static var cSource: UTType {
        UTType("public.c-source") ?? .sourceCode
    }
    static var cHeader: UTType {
        UTType("public.c-header") ?? .sourceCode
    }
    static var cPlusPlusSource: UTType {
        UTType("public.c-plus-plus-source") ?? .sourceCode
    }
    static var cPlusPlusHeader: UTType {
        UTType("public.c-plus-plus-header") ?? .sourceCode
    }
    static var objectiveCSource: UTType {
        UTType("public.objective-c-source") ?? .sourceCode
    }
    static var objectiveCPlusPlusSource: UTType {
        UTType("public.objective-c-plus-plus-source") ?? .sourceCode
    }
    static var javaSource: UTType {
        UTType("com.sun.java-source") ?? .sourceCode
    }

    // Imported / non-system UTIs — declared in our Info.plist.
    static var markdown: UTType {
        UTType("net.daringfireball.markdown") ?? .plainText
    }
    static var yamlSource: UTType {
        UTType("public.yaml") ?? .plainText
    }
    static var cssSource: UTType {
        UTType("public.css") ?? .plainText
    }
    static var javascriptSource: UTType {
        UTType("com.netscape.javascript-source") ?? .sourceCode
    }
    static var typescriptSource: UTType {
        UTType("com.prism.host.typescript-source") ?? .sourceCode
    }
    static var rustSource: UTType {
        UTType("com.prism.host.rust-source") ?? .sourceCode
    }
    static var goSource: UTType {
        UTType("com.prism.host.go-source") ?? .sourceCode
    }
    static var kotlinSource: UTType {
        UTType("com.prism.host.kotlin-source") ?? .sourceCode
    }
    static var csharpSource: UTType {
        UTType("com.prism.host.csharp-source") ?? .sourceCode
    }
}
