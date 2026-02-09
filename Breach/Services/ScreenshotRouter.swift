import Foundation
import Observation

/// Routes deep links to specific screens for automated screenshot capture.
/// Only active when the app is launched with `-SCREENSHOT_MODE`.
enum ScreenshotRoute: String, Equatable {
    case home
    case gameplay
    case gridRush = "grid-rush"
    case difficulty
    case stats
}

@MainActor @Observable
class ScreenshotRouter {
    static let shared = ScreenshotRouter()
    private init() {}

    var pendingRoute: ScreenshotRoute?

    /// Whether screenshot routing is active (set at launch).
    var isEnabled = false

    func handle(url: URL) {
        guard isEnabled,
              url.scheme == "breach",
              let host = url.host,
              let route = ScreenshotRoute(rawValue: host)
        else { return }

        pendingRoute = route
    }
}
