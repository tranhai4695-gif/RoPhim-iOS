import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        if #available(iOS 15.4, *) {
            config.preferences.isElementFullscreenEnabled = true
        }
        // Cho phép window.open để web thấy popup "đã mở" (popup sẽ bị giấu và tự đóng)
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Chống trang phát hiện "AdBlock"
        config.userContentController.addUserScript(
            WKUserScript(source: AntiDetect.js, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.reload(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        context.coordinator.webView = webView

        if AppConfig.strictAdBlock {
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "AdBlock",
                encodedContentRuleList: Self.ruleListJSON
            ) { list, _ in
                if let list = list { webView.configuration.userContentController.add(list) }
                webView.load(URLRequest(url: url))
            }
        } else {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webView: WKWebView?
        private var hiddenPopups: [WKWebView] = []

        @objc func reload(_ sender: UIRefreshControl) {
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { sender.endRefreshing() }
        }

        private func isAllowed(_ url: URL?) -> Bool {
            guard let host = url?.host?.lowercased() else { return true }
            return AppConfig.allowedHostKeywords.contains { host.contains($0) }
        }

        private func isPopup(_ webView: WKWebView) -> Bool {
            hiddenPopups.contains { $0 === webView }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let url = action.request.url
            let scheme = url?.scheme?.lowercased() ?? ""

            // Không bao giờ cho mở app khác / App Store
            if !["http", "https", "about", "blob", "data", "javascript"].contains(scheme) {
                decisionHandler(.cancel); return
            }
            // Popup ngầm: cho tải (để web ghi nhận), người dùng không thấy
            if isPopup(webView) { decisionHandler(.allow); return }

            // Trang chính: chặn chuyển hướng sang trang quảng cáo
            if action.targetFrame?.isMainFrame ?? true, !isAllowed(url) {
                decisionHandler(.cancel); return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for action: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Link nội bộ mở bằng target=_blank: mở luôn trong app
            if let url = action.request.url, isAllowed(url), url.host != nil {
                webView.load(action.request)
                return nil
            }
            // Popup quảng cáo: tạo cửa sổ ẩn, không âm thanh, tự đóng sau 8 giây
            configuration.mediaTypesRequiringUserActionForPlayback = .all
            configuration.allowsInlineMediaPlayback = false
            let popup = WKWebView(frame: CGRect(x: -2000, y: -2000, width: 10, height: 10),
                                  configuration: configuration)
            popup.isHidden = true
            popup.isUserInteractionEnabled = false
            popup.navigationDelegate = self
            popup.uiDelegate = self
            webView.addSubview(popup)
            hiddenPopups.append(popup)
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self, weak popup] in
                guard let popup = popup else { return }
                popup.stopLoading()
                popup.removeFromSuperview()
                self?.hiddenPopups.removeAll { $0 === popup }
            }
            return popup
        }

        func webViewDidClose(_ webView: WKWebView) {
            if isPopup(webView) {
                webView.removeFromSuperview()
                hiddenPopups.removeAll { $0 === webView }
            }
        }

        // Không hiện hộp thoại alert/confirm từ quảng cáo
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            completionHandler()
        }
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            completionHandler(isPopup(webView) ? false : true)
        }
    }

    // MARK: - Bộ lọc (chỉ dùng khi strictAdBlock = true)

    static var ruleListJSON: String {
        let rules: [[String: Any]] = AppConfig.blockedDomains.map { domain in
            let escaped = NSRegularExpression.escapedPattern(for: domain)
            return ["trigger": ["url-filter": ".*\(escaped).*"],
                    "action": ["type": "block"]]
        }
        let data = try! JSONSerialization.data(withJSONObject: rules)
        return String(data: data, encoding: .utf8)!
    }
}
