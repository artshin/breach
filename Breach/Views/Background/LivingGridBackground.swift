import SwiftUI

/// Animated perspective grid background with state-responsive behavior
struct LivingGridBackground: View {
    let state: BackgroundGameState

    // Pre-computed geometry
    private let horizontalLineCount = 20
    private let verticalLineCount = 15

    /// State transition
    @State private var currentPalette: BackgroundPalette

    // Win/Loss effects
    @State private var flashIntensity: Double = 0
    @State private var rippleRadius: Double = 0
    @State private var fragmentOffset: [CGFloat] = []

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    init(state: BackgroundGameState) {
        self.state = state
        _currentPalette = State(initialValue: BackgroundPalette.forState(state))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.1 : 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                drawGrid(context: context, size: size, time: time)
            }
        }
        .background(currentPalette.primary)
        .onChange(of: state) { newState in
            withAnimation(.easeInOut(duration: 0.8)) {
                currentPalette = BackgroundPalette.forState(newState)
            }

            if case .win = newState {
                triggerWinEffect()
            } else if case .loss = newState {
                triggerLossEffect()
            }
        }
    }

    // MARK: - Grid Drawing

    private func drawGrid(
        context: GraphicsContext,
        size: CGSize,
        time: Double
    ) {
        let vanishingPoint = CGPoint(x: size.width / 2, y: size.height * 0.33)
        let horizon = vanishingPoint.y
        let gridHeight = size.height - horizon + 50

        // Glow pulse: smooth sine wave
        let period = state.animationPeriod
        let glowAmount = 0.3 + 0.5 * (0.5 + 0.5 * sin(time * .pi * 2.0 / period))

        // Scroll: continuous forward motion
        // scrollSpeed of 1.0 = one line spacing per second
        let lineSpacing = 1.0 / Double(horizontalLineCount)
        let scrollOffset = (time * state.scrollSpeed * 0.15).truncatingRemainder(dividingBy: 1.0)

        // Jitter for high-intensity states
        let jitter: CGFloat = state.hasJitter ? CGFloat.random(in: -2...2) : 0

        // Apply flash effect for win state
        var effectiveGlow = glowAmount
        if flashIntensity > 0 {
            effectiveGlow = min(1.0, glowAmount + flashIntensity)
        }

        // Apply flicker for loss state
        let flickerMultiplier = if case .loss = state {
            0.5 + 0.5 * sin(time * 15)
        } else {
            1.0
        }

        // Draw horizontal lines with perspective
        for i in 0..<horizontalLineCount {
            // Base position (0 to 1)
            var pos = Double(i) * lineSpacing + scrollOffset
            if pos >= 1.0 { pos -= 1.0 }

            // Perspective: lines near horizon are compressed
            let perspectivePos = pow(pos, 1.8)

            // Screen Y coordinate
            let y = horizon + gridHeight * perspectivePos

            // Opacity based on distance (closer = brighter)
            let lineOpacity = effectiveGlow * perspectivePos * flickerMultiplier

            // Fragment effect for loss state
            var lineJitter: CGFloat = 0
            if case .loss = state, i < fragmentOffset.count {
                lineJitter = fragmentOffset[i]
            }

            var path = Path()
            path.move(to: CGPoint(x: -50 + lineJitter + jitter, y: y))
            path.addLine(to: CGPoint(x: size.width + 50 + lineJitter + jitter, y: y))

            context.stroke(
                path,
                with: .color(currentPalette.accent.opacity(lineOpacity * currentPalette.accentOpacity)),
                lineWidth: max(0.5, 1.5 * perspectivePos)
            )
        }

        // Draw vertical lines converging to vanishing point
        let groundWidth = size.width * 1.5
        let startX = (size.width - groundWidth) / 2 // Center the spread

        for i in 0..<verticalLineCount {
            let normalizedIndex = Double(i) / Double(verticalLineCount - 1)
            let bottomX = startX + groundWidth * normalizedIndex

            let distanceFromCenter = abs(normalizedIndex - 0.5) * 2
            let lineOpacity = effectiveGlow * (1.0 - distanceFromCenter * 0.3) * flickerMultiplier

            var path = Path()
            path.move(to: vanishingPoint)
            path.addLine(to: CGPoint(x: bottomX + jitter, y: size.height + 50))

            context.stroke(
                path,
                with: .color(currentPalette.accent.opacity(lineOpacity * 0.6 * currentPalette.accentOpacity)),
                lineWidth: 0.8
            )
        }

        // Ripple effect for win state
        if rippleRadius > 0 {
            let ripplePath = Path(ellipseIn: CGRect(
                x: size.width / 2 - rippleRadius,
                y: size.height / 2 - rippleRadius,
                width: rippleRadius * 2,
                height: rippleRadius * 2
            ))
            let rippleOpacity = max(0, 1.0 - rippleRadius / max(size.width, size.height))
            context.stroke(ripplePath, with: .color(currentPalette.accent.opacity(rippleOpacity)), lineWidth: 3)
        }
    }

    // MARK: - Win Effect

    private func triggerWinEffect() {
        guard !reduceMotion else { return }

        withAnimation(.easeOut(duration: 0.2)) {
            flashIntensity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            flashIntensity = 0
        }

        rippleRadius = 0
        withAnimation(.easeOut(duration: 1.5)) {
            rippleRadius = 1000
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            rippleRadius = 0
        }
    }

    // MARK: - Loss Effect

    private func triggerLossEffect() {
        guard !reduceMotion else { return }

        fragmentOffset = (0..<horizontalLineCount).map { _ in CGFloat(0) }

        for i in 0..<horizontalLineCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if fragmentOffset.count > i {
                        fragmentOffset[i] = CGFloat.random(in: -30...30)
                    }
                }
            }
        }
    }
}

#Preview {
    LivingGridBackground(state: .menu)
}
