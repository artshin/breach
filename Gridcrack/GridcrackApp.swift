import AppLogService
import SwiftUI

@main
struct GridcrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let log = Logger.shared

    init() {
        let config = LoggerConfiguration(
            serverURL: URL(string: "http://192.168.1.70:9006")!,
            source: "gridcrack"
        )
        Logger.shared.configure(config)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        Logger.shared.info(
            "App launched",
            metadata: ["version": version, "build": build],
            tags: ["navigation"]
        )

        if ProcessInfo.processInfo.arguments.contains("-SCREENSHOT_MODE") {
            GameSettings.shared.loadScreenshotData()
            ScreenshotRouter.shared.isEnabled = true
            Logger.shared.info("Screenshot mode activated", tags: ["navigation"])
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
