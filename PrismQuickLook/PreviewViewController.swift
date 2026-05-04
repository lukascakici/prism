import Cocoa
import Quartz
import OSLog

/// QuickLook Preview Extension'ın principal class'ı.
///
/// Mimari: NSScrollView + NSTextView + NSAttributedString.
/// Sözdizimi vurgulaması native tokenizer (Tokenizers/) tarafından yapılır.
/// WKWebView/highlight.js bağımlılığı yok.
final class PreviewViewController: NSViewController, QLPreviewingController {

    // MARK: - Sabitler

    /// 5 MB üzeri dosyalar truncate edilir; QL XPC süreci bellek limitlidir.
    private static let maxRenderableBytes: Int = 5 * 1024 * 1024

    private let logger = Logger(subsystem: "com.prism.quicklook", category: "Preview")

    // MARK: - UI

    private let scrollView = NSScrollView()
    private let textView = NSTextView()
    private let bannerLabel = NSTextField(labelWithString: "")

    // MARK: - State

    /// preparePreview tamamlandığında saklanır; viewDidAppear flush eder.
    /// QL host view'ı handler(nil)'den sonra window'a koyduğu için iki aşamalı.
    private var pendingAttributedString: NSAttributedString?
    private var pendingBannerText: String?

    // MARK: - View Lifecycle

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        root.wantsLayer = true
        root.layer?.backgroundColor = SyntaxTheme.background.cgColor
        root.autoresizingMask = [.width, .height]
        self.view = root

        configureBanner()
        configureTextView()

        view.addSubview(bannerLabel)
        view.addSubview(scrollView)

        bannerLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bannerLabel.topAnchor.constraint(equalTo: view.topAnchor),
            bannerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bannerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: bannerLabel.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        flushPending()
    }

    // MARK: - UI Setup

    private func configureBanner() {
        bannerLabel.font = .systemFont(ofSize: 11, weight: .medium)
        bannerLabel.textColor = .secondaryLabelColor
        bannerLabel.backgroundColor = .clear
        bannerLabel.drawsBackground = false
        bannerLabel.isHidden = true
    }

    private func configureTextView() {
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        // Long-line desteği için horizontal scroll açık olmalı.
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = []
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.lineFragmentPadding = 12

        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsUndo = false
        textView.usesFindBar = true
        textView.backgroundColor = SyntaxTheme.background
        textView.textColor = SyntaxTheme.foreground
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)

        scrollView.documentView = textView
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL,
                              completionHandler handler: @escaping (Error?) -> Void) {

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let payload = try await self.loadAndPrepare(url: url)
                let tokenizer = TokenizerRegistry.tokenizer(for: payload.language)
                let attributed = SyntaxRenderer.render(source: payload.source, tokenizer: tokenizer)
                let banner = self.bannerText(for: payload)

                await MainActor.run {
                    self.pendingAttributedString = attributed
                    self.pendingBannerText = banner
                    self.flushPending()
                    handler(nil)
                }
            } catch {
                self.logger.error("Preview failed: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    self.pendingAttributedString = self.errorAttributedString(error: error)
                    self.pendingBannerText = nil
                    self.flushPending()
                    handler(nil)
                }
            }
        }
    }

    @MainActor
    private func flushPending() {
        if let attr = pendingAttributedString {
            textView.textStorage?.setAttributedString(attr)
            pendingAttributedString = nil
        }
        if let banner = pendingBannerText, !banner.isEmpty {
            bannerLabel.stringValue = "  ⚠️  " + banner
            bannerLabel.isHidden = false
            pendingBannerText = nil
        }
    }

    // MARK: - File Loading

    private func loadAndPrepare(url: URL) async throws -> RenderPayload {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .isReadableKey])
        guard resourceValues.isReadable == true else {
            throw PreviewError.notReadable(url)
        }
        let fileSize = resourceValues.fileSize ?? 0

        let (sourceText, didTruncate) = try FileReader.readBoundedUTF8(
            url: url,
            limit: Self.maxRenderableBytes,
            actualSize: fileSize
        )

        return RenderPayload(
            language: LanguageDetection.detect(for: url),
            source: sourceText,
            originalByteCount: fileSize,
            wasTruncated: didTruncate,
            displayName: url.lastPathComponent
        )
    }

    private func bannerText(for payload: RenderPayload) -> String? {
        guard payload.wasTruncated else { return nil }
        let original = ByteCountFormatter.string(
            fromByteCount: Int64(payload.originalByteCount), countStyle: .file
        )
        let limit = ByteCountFormatter.string(
            fromByteCount: Int64(Self.maxRenderableBytes), countStyle: .file
        )
        return "Dosya \(original) — önizleme ilk \(limit) ile sınırlandırıldı."
    }

    nonisolated private func errorAttributedString(error: Error) -> NSAttributedString {
        let message = "Önizleme oluşturulamadı:\n\n\(error.localizedDescription)"
        return NSAttributedString(string: message, attributes: [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.systemRed,
        ])
    }
}
