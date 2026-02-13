import AppLogService
import SwiftUI

@main
struct GridcrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let config = LoggerConfiguration(
            serverURL: URL(string: "http://192.168.1.70:9006")!,
            source: "gridcrack"
        )
        Logger.shared.configure(config)
        Logger.shared.info("Hello world")

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
