import Observation
import SwiftUI

/// Represents the current game state for background animation purposes
enum BackgroundGameState: Equatable {
    case menu
    case settings
    case game(bufferFillRatio: Double) // 0.0 to 1.0 for intensity scaling
    case win
    case loss

    /// Animation intensity based on state
    var intensity: Double {
        switch self {
        case .menu:
            0.5
        case .settings:
            0.2
        case let .game(ratio):
            0.5 + ratio * 0.5 // 0.5 to 1.0
        case .win:
            1.0
        case .loss:
            0.8
        }
    }
}

/// Shared background state manager injected via EnvironmentObject.
/// Lives at the NavigationStack root so all pushed screens share the same animated background.
@Observable
class BackgroundStateManager {
    var state: BackgroundGameState = .menu
}

/// Available background animation styles
enum BackgroundStyle: String, CaseIterable, Identifiable, Codable {
    case livingGrid = "Living Grid"
    case circuitTraces = "Circuit Traces"

    var id: String {
        rawValue
    }

    var description: String {
        switch self {
        case .livingGrid:
            "Perspective grid with pulsing glow"
        case .circuitTraces:
            "PCB-style traces with traveling pulses"
        }
    }

    var iconName: String {
        switch self {
        case .livingGrid:
            "grid"
        case .circuitTraces:
            "cpu"
        }
    }
}
