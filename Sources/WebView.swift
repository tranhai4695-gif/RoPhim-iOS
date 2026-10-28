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
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Ẩn các khung quảng cáo hay gặp + chặn window.open (popup)
        let script = WKUserScript(source: Self.cleanupJS,
                                  injectionTime: .atDocumentStart,
                                  forMainFrameOnly: false)
        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // Kéo xuống để tải lại
        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.reload(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        context.coordinator.webView = webView

        // Nạp bộ lọc chặn quảng cáo rồi mới mở trang
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "AdBlock",
            encodedContentRuleList: Self.ruleListJSON
        ) { list, error in
            if let list = list {
                webView.configuration.userContentController.add(list)
            } else if let error = error {
                print("AdBlock compile error: \(error)")
            }
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webView: WKWebView?

        @objc func reload(_ sender: UIRefreshControl) {
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { sender.endRefreshing() }
        }

        private func isAllowed(_ url: URL?) -> Bool {
            guard let host = url?.host?.lowercased() else { return true }
            return AppConfig.allowedHostKeywords.contains { host.contains($0) }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let url = action.request.url
            let scheme = url?.scheme?.lowercased() ?? ""

            // Chặn mở app khác / App Store / link lạ
            if !["http", "https", "about", "blob", "data", "javascript"].contains(scheme) {
                decisionHandler(.cancel); return
            }
            // Chỉ kiểm soát khung chính; iframe (player video) được phép tải
            if action.targetFrame?.isMainFrame ?? true, !isAllowed(url) {
                decisionHandler(.cancel); return
            }
            decisionHandler(.allow)
        }

        // Popup (target=_blank / window.open): nếu là link trong web thì mở tại chỗ, còn lại bỏ qua
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for action: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if isAllowed(action.request.url), action.request.url != nil {
                webView.load(action.request)
            }
            return nil
        }

        // Không hiện hộp thoại alert/confirm từ quảng cáo
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            completionHandler()
        }
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            completionHandler(false)
        }
    }

    // MARK: - Bộ lọc

    static var ruleListJSON: String {
        var rules: [[String: Any]] = AppConfig.blockedDomains.map { domain in
            let escaped = NSRegularExpression.escapedPattern(for: domain)
            return ["trigger": ["url-filter": ".*\(escaped).*"],
                    "action": ["type": "block"]]
        }
        // Ẩn phần tử quảng cáo phổ biến
        rules.append([
            "trigger": ["url-filter": ".*"],
            "action": ["type": "css-display-none",
                       "selector": "[id*='banner-ads'], [class*='banner-ads'], [id^='ads-'], [class^='ads-'], .ads, .ad-banner, .adsbygoogle, [id*='catfish'], [class*='catfish'], [id*='popup-ads'], [class*='popup-ads'], [class*='preload-ads'], [id*='preload-ads'], ins.adsbygoogle"]
        ])
        let data = try! JSONSerialization.data(withJSONObject: rules)
        return String(data: data, encoding: .utf8)!
    }

    static let cleanupJS = """
    (function() {
      try { window.open = function() { return null; }; } catch (e) {}
      function isFixedOverlay(el) {
        var s = getComputedStyle(el);
        if (s.position !== 'fixed') return false;
        if (el.querySelector('video, iframe[src*="player"], iframe[src*="embed"]')) return false;
        var z = parseInt(s.zIndex || '0', 10);
        var hasAdLink = el.querySelector('a[href^="http"]:not([href*="rophim"])');
        return z > 999 && !!hasAdLink;
      }
      function clean() {
        document.querySelectorAll('body > div, body > a, body > iframe').forEach(function(el) {
          try { if (isFixedOverlay(el)) el.remove(); } catch (e) {}
        });
      }
      document.addEventListener('DOMContentLoaded', clean);
      setInterval(clean, 1500);
    })();
    """
}
