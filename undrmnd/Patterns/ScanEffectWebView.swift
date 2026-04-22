import AVFoundation
import SwiftUI
import WebKit

/// Full-screen scan effect (video + Three.js). Posts `scanBackgroundReady` after video decode + buffer warm-up.
///
/// **Console noise:** Log lines such as slow GPU/WebContent process launch, sandbox extension, `CARenderServer`,
/// or WebPrivacy “query parameters” come from WebKit and the OS (often amplified on Simulator). They are not
/// actionable app defects; filter the Xcode console or verify on a physical device when diagnosing real issues.
///
/// Call once at launch so the same bundled file is in memory / decoded before `WKWebView` loads the intro page.
enum ScanEffectVideoPrewarmer {
    static func prewarmBundledVideo() {
        guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4", subdirectory: "ScanEffect") else {
            return
        }
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        asset.loadValuesAsynchronously(forKeys: ["playable", "tracks", "duration"]) {}
    }
}

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

        let coordinator = context.coordinator
        config.userContentController.add(coordinator, name: "scanBackgroundReady")
        coordinator.userContentController = config.userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.underPageBackgroundColor = .clear

        guard let indexURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "ScanEffect") else {
            return webView
        }
        let folderURL = indexURL.deletingLastPathComponent()
        guard let html = try? String(contentsOf: indexURL, encoding: .utf8) else {
            return webView
        }
        webView.loadHTMLString(html, baseURL: folderURL)
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
