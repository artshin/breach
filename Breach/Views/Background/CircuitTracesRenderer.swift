import SwiftUI

/// Canvas drawing functions for CircuitTracesBackground
enum CircuitTracesRenderer {
    /// Draw a single trace with its path, pulses, and junction nodes
    static func drawTrace(
        context: GraphicsContext,
        trace: Trace,
        palette: BackgroundPalette,
        relativeTime: TimeInterval,
        isShortCircuiting: Bool
    ) {
        guard trace.segments.count > 1 else { return }

        let visibleSegmentCount = Int(Double(trace.segments.count) * trace.growthProgress)
        guard visibleSegmentCount > 0 else { return }

        let traceColor = isShortCircuiting
            ? Color(hex: "FF1A1A")
            : palette.accent

        // Draw trace path
        var path = Path()
        path.move(to: trace.segments[0])

        for i in 1..<min(visibleSegmentCount + 1, trace.segments.count) {
            path.addLine(to: trace.segments[i])
        }

        let traceOpacity = isShortCircuiting ? (0.5 + 0.5 * sin(relativeTime * 20)) : trace.opacity
        context.stroke(
            path,
            with: .color(traceColor.opacity(traceOpacity * palette.accentOpacity)),
            lineWidth: 1.5
        )

        // Draw pulses
        drawPulses(
            context: context,
            trace: trace,
            traceColor: traceColor,
            visibleSegmentCount: visibleSegmentCount
        )

        // Draw T-junction nodes
        drawNodes(
            context: context,
            trace: trace,
            traceColor: traceColor,
            visibleSegmentCount: visibleSegmentCount
        )
    }

    private static func drawPulses(
        context: GraphicsContext,
        trace: Trace,
        traceColor: Color,
        visibleSegmentCount _: Int
    ) {
        for pulse in trace.pulses {
            guard let point = trace.pointAt(progress: pulse.position) else { continue }

            // Draw pulse glow
            let glowRadius: CGFloat = 6
            let gradient = Gradient(colors: [
                traceColor.opacity(pulse.opacity * 0.8),
                traceColor.opacity(0)
            ])

            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - glowRadius,
                    y: point.y - glowRadius,
                    width: glowRadius * 2,
                    height: glowRadius * 2
                )),
                with: .radialGradient(
                    gradient,
                    center: point,
                    startRadius: 0,
                    endRadius: glowRadius
                )
            )

            // Draw pulse core
            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - 2,
                    y: point.y - 2,
                    width: 4,
                    height: 4
                )),
                with: .color(traceColor.opacity(pulse.opacity))
            )

            // Draw fading tail
            drawPulseTail(
                context: context,
                trace: trace,
                pulse: pulse,
                traceColor: traceColor
            )
        }
    }

    private static func drawPulseTail(
        context: GraphicsContext,
        trace: Trace,
        pulse: Trace.Pulse,
        traceColor: Color
    ) {
        let tailCount = 5
        for tailIndex in 1...tailCount {
            let tailProgress = pulse.position - Double(tailIndex) * 0.02
            guard tailProgress >= 0,
                  let tailPoint = trace.pointAt(progress: tailProgress) else { continue }

            let tailOpacity = pulse.opacity * (1.0 - Double(tailIndex) / Double(tailCount))
            context.fill(
                Path(ellipseIn: CGRect(
                    x: tailPoint.x - 1.5,
                    y: tailPoint.y - 1.5,
                    width: 3,
                    height: 3
                )),
                with: .color(traceColor.opacity(tailOpacity * 0.5))
            )
        }
    }

    private static func drawNodes(
        context: GraphicsContext,
        trace: Trace,
        traceColor: Color,
        visibleSegmentCount: Int
    ) {
        for segment in trace.segments.prefix(visibleSegmentCount + 1) {
            let nodeRadius: CGFloat = 2
            context.fill(
                Path(ellipseIn: CGRect(
                    x: segment.x - nodeRadius,
                    y: segment.y - nodeRadius,
                    width: nodeRadius * 2,
                    height: nodeRadius * 2
                )),
                with: .color(traceColor.opacity(trace.opacity * 0.5))
            )
        }
    }

    /// Draw converging particle burst for win state
    static func drawParticleBurst(
        context: GraphicsContext,
        size: CGSize,
        palette: BackgroundPalette,
        convergenceProgress: Double
    ) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let particleCount = 50

        for i in 0..<particleCount {
            let angle = Double(i) / Double(particleCount) * 2 * .pi
            let distance = (1.0 - convergenceProgress) * max(size.width, size.height)

            let x = center.x + cos(angle) * distance
            let y = center.y + sin(angle) * distance

            context.fill(
                Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                with: .color(palette.accent.opacity(convergenceProgress))
            )
        }
    }
}
