import SwiftUI

// MARK: - Colors

enum BreachColors {
    // Primary cyberpunk palette
    static let cyan = Color(hex: "00D4FF")
    static let yellow = Color(hex: "FFD700")
    static let pink = Color(hex: "FF6B9D")
    static let green = Color(hex: "00FF88")
    static let red = Color(hex: "FF4444")
    static let orange = Color(hex: "FF8C00")

    // Backgrounds
    static let background = Color.black
    static let cardBackground = Color(hex: "0A0A0A")
    static let panelBackground = Color(hex: "111111")

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "888888")
    static let textMuted = Color(hex: "555555")

    // Borders
    static let borderPrimary = cyan.opacity(0.5)
    static let borderSecondary = cyan.opacity(0.3)
    static let borderMuted = cyan.opacity(0.15)
}

// MARK: - Typography

enum BreachTypography {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    static func body(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    static func code(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

// MARK: - Spacing

enum BreachSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius

enum BreachRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
}

// MARK: - Animation Utilities

extension Animation {
    /// Returns nil if reduce motion is enabled, otherwise returns the animation
    static func accessibleAnimation(_ animation: Animation) -> Animation? {
        if UIAccessibility.isReduceMotionEnabled {
            return nil
        }
        return animation
    }
}

extension View {
    /// Applies animation only if reduce motion is not enabled
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            return self.animation(nil, value: value)
        }
        return self.animation(animation, value: value)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
