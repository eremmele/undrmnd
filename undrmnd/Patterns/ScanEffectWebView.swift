import SwiftUI
import WebKit

/// Full‑screen Quantum Nebula **Torus** (bundled Three.js). Posts native `scanBackgroundReady` after warm‑up.
///
/// **Console noise:** Log lines such as slow GPU/WebContent process launch, sandbox extension, `CARenderServer`,
/// or WebPrivacy “query parameters” come from WebKit and the OS (often amplified on Simulator). They are not
/// actionable app defects; filter the Xcode console or verify on a physical device when diagnosing real issues.

struct ScanEffectWebView: UIViewRepresentable {
    @Binding var isBackgroundReady: Bool

    init(isBackgroundReady: Binding<Bool> = .constant(false)) {
        _isBackgroundReady = isBackgroundReady
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isBackgroundReady: $isBackgroundReady)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        /// Matches intro e‑reader parchment (`ScanEffect/index.html`); avoids WK flashing white behind the torus layer.
        let paintPaperBackdrop = WKUserScript(
            source: "document.documentElement.style.backgroundColor='#ebe7de';",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(paintPaperBackdrop)

        let coordinator = context.coordinator
        config.userContentController.add(coordinator, name: "scanBackgroundReady")
        coordinator.userContentController = config.userContentController

        let parchment = UIColor(red: 235 / 255, green: 231 / 255, blue: 222 / 255, alpha: 1)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = true
        webView.backgroundColor = parchment
        webView.scrollView.backgroundColor = parchment
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.underPageBackgroundColor = parchment

        guard let indexURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "ScanEffect") else {
            return webView
        }
        guard let html = try? String(contentsOf: indexURL, encoding: .utf8) else {
            return webView
        }
        let bundleRoot = Bundle.main.bundleURL
        webView.loadHTMLString(html, baseURL: bundleRoot)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var isBackgroundReady: Binding<Bool>
        weak var userContentController: WKUserContentController?

        init(isBackgroundReady: Binding<Bool>) {
            self.isBackgroundReady = isBackgroundReady
        }

        func detach() {
            userContentController?.removeScriptMessageHandler(forName: "scanBackgroundReady")
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "scanBackgroundReady" else { return }
            DispatchQueue.main.async {
                self.isBackgroundReady.wrappedValue = true
            }
        }
    }
}
