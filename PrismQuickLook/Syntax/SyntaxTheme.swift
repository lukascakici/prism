import AppKit

/// TokenType → NSColor mapping.
///
/// Thanks to the `NSColor(name:dynamicProvider:)` API, every color is resolved
/// at runtime based on Light/Dark appearance — if the user changes System
/// settings the preview updates live, no need to re-render the attributed string.
///
/// The color palette is based on GitHub's light/dark theme.
enum SyntaxTheme {

    static func color(for type: TokenType) -> NSColor {
        switch type {
        case .plain, .identifier, .punctuation:
            return .labelColor
        case .keyword, .operator:
            return dynamic(light: 0xd73a49, dark: 0xff7b72)
        case .string:
            return dynamic(light: 0x032f62, dark: 0xa5d6ff)
        case .number, .constant:
            return dynamic(light: 0x005cc5, dark: 0x79c0ff)
        case .comment:
            return dynamic(light: 0x6a737d, dark: 0x8b949e)
        case .type:
            return dynamic(light: 0x6f42c1, dark: 0xffa657)
        case .function, .attribute:
            return dynamic(light: 0x6f42c1, dark: 0xd2a8ff)
        }
    }

    /// Render comment tokens in italic (aesthetic preference).
    static func isItalic(_ type: TokenType) -> Bool {
        type == .comment
    }

    static var background: NSColor {
        // .textBackgroundColor → Light: white, Dark: ~#1e1e1e (system editor bg).
        .textBackgroundColor
    }

    static var foreground: NSColor {
        .labelColor
    }

    // MARK: - Helpers

    private static func dynamic(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark]) != nil
            return color(hex: isDark ? dark : light)
        }
    }

    private static func color(hex: UInt32) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xff) / 255.0,
            green:   CGFloat((hex >>  8) & 0xff) / 255.0,
            blue:    CGFloat( hex        & 0xff) / 255.0,
            alpha: 1.0
        )
    }
}
