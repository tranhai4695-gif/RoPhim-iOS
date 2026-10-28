import Foundation

enum AppConfig {
    /// Trang mở khi bật app. Nếu web đổi tên miền, sửa ở đây rồi build lại.
    static let homeURL = URL(string: "https://rophim1.vip")!

    /// Chỉ cho phép trang chính chuyển tới các tên miền chứa những từ khóa này.
    /// Mọi chuyển hướng khác (thường là quảng cáo) sẽ bị chặn.
    static let allowedHostKeywords = ["rophim"]

    /// false (mặc định): chế độ nhẹ. Không chặn mạng quảng cáo để web không báo "Phát hiện AdBlock",
    ///   nhưng popup quảng cáo được mở ngầm rồi tự đóng, và chặn chuyển hướng sang trang lạ.
    /// true: chặn mạnh theo danh sách blockedDomains (web có thể phát hiện và khóa).
    static let strictAdBlock = false

    /// Các tên miền quảng cáo/theo dõi phổ biến bị chặn hoàn toàn.
    static let blockedDomains = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "google-analytics.com", "googletagmanager.com", "googletagservices.com",
        "adservice.google.com", "adnxs.com", "adsrvr.org", "amazon-adsystem.com",
        "popads.net", "popcash.net", "propellerads.com", "propellerclick.com",
        "exoclick.com", "exosrv.com", "juicyads.com", "trafficjunky.net",
        "adsterra.com", "adsterratech.com", "hilltopads.net", "hilltopads.com",
        "a-ads.com", "adcash.com", "onclickads.net", "onclkds.com",
        "clickadu.com", "mgid.com", "revcontent.com", "taboola.com",
        "outbrain.com", "zedo.com", "yllix.com", "ad-maven.com", "admaven.com",
        "richpush.co", "pushame.com", "monetag.com", "galaksion.com",
        "highperformanceformat.com", "highperformancecpm.com", "profitablecpmrate.com",
        "profitablegatecpm.com", "displaycontentnetwork.com", "bet365.com",
        "fun88", "w88", "m88", "188bet", "12bet", "fb88", "kubet", "jun88",
        "hi88", "new88", "f8bet", "shbet", "789bet", "8xbet", "okvip",
        "facebook.net", "connect.facebook.net", "scorecardresearch.com",
        "hotjar.com", "clarity.ms", "yandex.ru/metrika", "mc.yandex.ru",
    ]
}
