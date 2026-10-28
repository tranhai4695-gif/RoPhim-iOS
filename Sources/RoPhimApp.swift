import SwiftUI

@main
struct RoPhimApp: App {
    var body: some Scene {
        WindowGroup {
            WebView(url: AppConfig.homeURL)
                .ignoresSafeArea(.container, edges: .bottom)
                .background(Color.black)
                .preferredColorScheme(.dark)
        }
    }
}
