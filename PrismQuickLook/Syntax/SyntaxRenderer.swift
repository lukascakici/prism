import AppKit

/// Source string + Tokenizer → NSAttributedString.
/// Drop-in for NSTextView.
enum SyntaxRenderer {

    static func render(source: String,
                       tokenizer: Tokenizer,
                       font: NSFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    ) -> NSAttributedString {

        // Base attributes — applied to the entire text; tokens override them.
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: SyntaxTheme.foreground,
        ]
        let result = NSMutableAttributedString(string: source, attributes: baseAttrs)

        // Tokens don't overlap, so we set their ranges directly.
        let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)

        for token in tokenizer.tokenize(source) {
            let nsRange = NSRange(token.range, in: source)
            guard nsRange.location != NSNotFound else { continue }

            result.addAttribute(.foregroundColor,
                                value: SyntaxTheme.color(for: token.type),
                                range: nsRange)

            if SyntaxTheme.isItalic(token.type) {
                result.addAttribute(.font, value: italicFont, range: nsRange)
            }
        }

        return result
    }
}
