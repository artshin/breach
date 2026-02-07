import SwiftUI

// MARK: - Colors

enum BreachColors {
    // MARK: Backgrounds

    static let background = Color(hex: "080C16")
    static let surfacePrimary = Color(hex: "101828")

    // MARK: Accents

    static let accent = Color(hex: "3B9EFF")
    static let accentSecondary = Color(hex: "E040FB")
    static let accentHighlight = Color(hex: "80D4FF")

    // MARK: Text

    static let textPrimary = Color(hex: "C8D6E5")
    static let textSecondary = Color(hex: "6B7C8F")
    static let textMuted = Color(hex: "3A4A5C")

    // MARK: Borders

    static let borderPrimary = accent.opacity(0.5)
    static let borderSecondary = accent.opacity(0.3)
    static let borderMuted = accent.opacity(0.15)

    // MARK: Semantic states

    static let danger = Color(hex: "FF4057")
    static let dangerGlow = Color(hex: "FF6B7A")
    static let success = Color(hex: "3B9EFF")
    static let successBright = Color(hex: "80D4FF")
    static let successFlash = Color(hex: "E0F2FE")
    static let warning = Color(hex: "FF8A40")

    // MARK: Grid cells

    static let cellValid = Color(hex: "3B9EFF")
    static let cellAdvancing = Color(hex: "80D4FF")
    static let cellSelected = Color(hex: "3A4A5C")
    static let cellBlocked = Color(hex: "FF4057")
    static let cellWildcard = Color(hex: "E040FB")
    static let cellDecay = Color(hex: "FF8A40")
    static let cellHighlight = accent.opacity(0.08)

    // MARK: Buffer

    static let bufferEmpty = accent.opacity(0.3)
    static let bufferFilled = Color(hex: "80D4FF")

    // MARK: Sequences

    static let sequenceMatched = Color(hex: "3B9EFF")
    static let sequenceNext = Color(hex: "80D4FF")
    static let sequenceRemaining = Color(hex: "E040FB")
    static let sequenceComplete = Color(hex: "80D4FF")
    static let sequenceFailed = Color(hex: "FF4057")

    // MARK: Difficulty tiers

    static let tierEasy = Color(hex: "3B9EFF")
    static let tierMedium = Color(hex: "E040FB")
    static let tierHard = Color(hex: "FF8A40")
    static let tierExpert = Color(hex: "FF4057")

    // MARK: Timer urgency

    static let timerSafe = Color(hex: "3B9EFF")
    static let timerWarning = Color(hex: "FF8A40")
    static let timerCritical = Color(hex: "FF4057")

    // MARK: Stars / results

    static let starFilled = Color(hex: "80D4FF")
    static let starEmpty = Color(hex: "3A4A5C")
    static let resultOptimal = Color(hex: "80D4FF")
    static let resultGood = Color(hex: "3B9EFF")
    static let resultPartial = Color(hex: "FF8A40")
    static let resultFailed = Color(hex: "FF4057")
}

// MARK: - Typography

enum BreachTypography {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }

    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func body(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .bold, design: .default)
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
    static let sm: CGFloat = 0
    static let md: CGFloat = 0
    static let lg: CGFloat = 0
}

// MARK: - Bevel Modifier

struct BevelModifier: ViewModifier {
    var color: Color = BreachColors.accent
    var intensity = 1.0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                color.opacity(0.25 * intensity).frame(height: 1)
            }
            .overlay(alignment: .leading) {
                color.opacity(0.12 * intensity).frame(width: 1)
            }
            .overlay(alignment: .bottom) {
                Color.black.opacity(0.5 * intensity).frame(height: 1)
            }
            .overlay(alignment: .trailing) {
                Color.black.opacity(0.25 * intensity).frame(width: 1)
            }
    }
}

extension View {
    func breachBevel(color: Color = BreachColors.accent, intensity: Double = 1.0) -> some View {
        modifier(BevelModifier(color: color, intensity: intensity))
    }
}

// MARK: - Glass Modifier

struct GlassModifier: ViewModifier {
    var tint: Color = BreachColors.accent
    var tintOpacity = 0.1

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(tint.opacity(tintOpacity))
    }
}

extension View {
    func breachGlass(tint: Color = BreachColors.accent, opacity: Double = 0.1) -> some View {
        modifier(GlassModifier(tint: tint, tintOpacity: opacity))
    }
}

// MARK: - Navigation Helpers

private struct NavigationHelper: UIViewControllerRepresentable {
    let swipeBack: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        NavigationHelperController(swipeBack: swipeBack)
    }

    func updateUIViewController(_: UIViewController, context: Context) {}
}

private class NavigationHelperController: UIViewController {
    let swipeBack: Bool

    init(swipeBack: Bool) {
        self.swipeBack = swipeBack
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.view.backgroundColor = .clear
        parent?.view.backgroundColor = .clear
        if swipeBack {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

extension View {
    func clearNavigationBackground() -> some View {
        background(NavigationHelper(swipeBack: false))
    }

    func enableSwipeBack() -> some View {
        background(NavigationHelper(swipeBack: true))
    }
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
    func accessibleAnimation(_ animation: Animation?, value: some Equatable) -> some View {
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
        let alpha, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
