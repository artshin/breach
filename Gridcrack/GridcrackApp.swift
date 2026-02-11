import SwiftUI

@main
struct GridcrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        if ProcessInfo.processInfo.arguments.contains("-SCREENSHOT_MODE") {
            GameSettings.shared.loadScreenshotData()
            ScreenshotRouter.shared.isEnabled = true
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    ScreenshotRouter.shared.handle(url: url)
                }
        }
    }
}
