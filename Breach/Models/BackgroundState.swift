import Foundation

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
            return 0.5
        case .settings:
            return 0.2
        case .game(let ratio):
            return 0.5 + ratio * 0.5 // 0.5 to 1.0
        case .win:
            return 1.0
        case .loss:
            return 0.8
        }
    }
}

/// Available background animation styles
enum BackgroundStyle: String, CaseIterable, Identifiable, Codable {
    case livingGrid = "Living Grid"
    case circuitTraces = "Circuit Traces"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .livingGrid:
            return "Perspective grid with pulsing glow"
        case .circuitTraces:
            return "PCB-style traces with traveling pulses"
        }
    }

    var iconName: String {
        switch self {
        case .livingGrid:
            return "grid"
        case .circuitTraces:
            return "cpu"
        }
    }
}
