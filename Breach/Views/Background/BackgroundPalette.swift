import SwiftUI

/// State-based color palette for background animations
struct BackgroundPalette {
    let primary: Color      // Background base color
    let accent: Color       // Glow/highlight color
    let accentOpacity: Double

    static func forState(_ state: BackgroundGameState) -> BackgroundPalette {
        switch state {
        case .menu:
            return BackgroundPalette(
                primary: Color(hex: "0A0E1A"),
                accent: Color(hex: "00F0FF"),
                accentOpacity: 1.0
            )
        case .settings:
            return BackgroundPalette(
                primary: Color(hex: "0D1117"),
                accent: Color(hex: "00F0FF"),
                accentOpacity: 0.4
            )
        case .game:
            return BackgroundPalette(
                primary: Color(hex: "0C0C0C"),
                accent: Color(hex: "0066FF"),
                accentOpacity: 1.0
            )
        case .win:
            return BackgroundPalette(
                primary: Color(hex: "0A0E1A"),
                accent: Color(hex: "FFD700"),
                accentOpacity: 1.0
            )
        case .loss:
            return BackgroundPalette(
                primary: Color(hex: "050505"),
                accent: Color(hex: "FF1A1A"),
                accentOpacity: 1.0
            )
        }
    }
}

// MARK: - Color Interpolation

extension Color {
    /// Interpolates between two colors
    func interpolated(to other: Color, amount: Double) -> Color {
        let clampedAmount = max(0, min(1, amount))

        let fromComponents = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(other).cgColor.components ?? [0, 0, 0, 1]

        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * clampedAmount
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * clampedAmount
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * clampedAmount
        let a = fromComponents[3] + (toComponents[3] - fromComponents[3]) * clampedAmount

        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Animatable Palette

/// Wrapper for animatable color transitions
struct AnimatableBackgroundColors: Equatable {
    var primary: Color
    var accent: Color
    var accentOpacity: Double

    init(from palette: BackgroundPalette) {
        self.primary = palette.primary
        self.accent = palette.accent
        self.accentOpacity = palette.accentOpacity
    }

    func effectiveAccent() -> Color {
        accent.opacity(accentOpacity)
    }
}

// MARK: - State Transition Helpers

extension BackgroundGameState {
    /// Animation period for the background based on state
    var animationPeriod: Double {
        switch self {
        case .menu:
            return 4.0
        case .settings:
            return 6.0
        case .game(let ratio):
            // Faster as buffer fills: 2.0s down to 1.0s
            return 2.0 - ratio * 1.0
        case .win:
            return 1.5
        case .loss:
            return 2.0
        }
    }

    /// Scroll speed multiplier
    var scrollSpeed: Double {
        switch self {
        case .menu:
            return 1.0
        case .settings:
            return 0.0 // No scroll
        case .game(let ratio):
            // Faster as buffer fills
            return 1.5 + ratio * 1.5
        case .win:
            return 0.5
        case .loss:
            return 0.3
        }
    }

    /// Whether to apply jitter effect
    var hasJitter: Bool {
        switch self {
        case .game(let ratio):
            return ratio > 0.7
        case .loss:
            return true
        default:
            return false
        }
    }
}
