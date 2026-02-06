import SwiftUI

/// Represents a single trace on the circuit background
struct Trace: Identifiable {
    let id = UUID()
    var segments: [CGPoint]
    var opacity: Double
    var pulses: [Pulse]
    var growthProgress: Double // 0 to 1
    var creationTime: TimeInterval
    var lifetime: TimeInterval

    struct Pulse: Identifiable {
        let id = UUID()
        var position: Double // 0 to 1 along trace path
        var opacity: Double
        var speed: Double
    }

    var totalLength: CGFloat {
        guard segments.count > 1 else { return 0 }
        var length: CGFloat = 0
        for i in 1..<segments.count {
            length += segments[i - 1].distance(to: segments[i])
        }
        return length
    }

    func pointAt(progress: Double) -> CGPoint? {
        guard segments.count > 1 else { return segments.first }

        let total = totalLength
        guard total > 0 else { return segments.first }

        let targetDistance = total * CGFloat(progress)
        var accumulated: CGFloat = 0

        for i in 1..<segments.count {
            let segmentLength = segments[i - 1].distance(to: segments[i])
            if accumulated + segmentLength >= targetDistance {
                let remaining = targetDistance - accumulated
                let fraction = remaining / segmentLength
                return CGPoint(
                    x: segments[i - 1].x + (segments[i].x - segments[i - 1].x) * fraction,
                    y: segments[i - 1].y + (segments[i].y - segments[i - 1].y) * fraction
                )
            }
            accumulated += segmentLength
        }

        return segments.last
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        sqrt(pow(other.x - x, 2) + pow(other.y - y, 2))
    }
}

/// Animated circuit traces background with state-responsive behavior
struct CircuitTracesBackground: View {
    let state: BackgroundGameState

    @State private var traces: [Trace] = []
    @State private var startTime: TimeInterval = 0
    @State private var lastTraceTime: TimeInterval = 0
    @State private var lastUpdateTime: TimeInterval = 0
    @State private var currentPalette: BackgroundPalette
    @State private var viewSize: CGSize = .zero

    // Effect states
    @State private var shortCircuitIndex: Int = -1
    @State private var convergenceProgress: Double = 0
    @State private var particleBurst = false

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    init(state: BackgroundGameState) {
        self.state = state
        _currentPalette = State(initialValue: BackgroundPalette.forState(state))
    }

    private var traceCount: (min: Int, max: Int) {
        switch state {
        case .menu:
            return (8, 12)
        case .settings:
            return (4, 6)
        case let .game(ratio):
            let base = 15
            let extra = Int(ratio * 10)
            return (base, base + extra)
        case .win, .loss:
            return (10, 15)
        }
    }

    private var pulseSpeed: Double {
        switch state {
        case .menu:
            30
        case .settings:
            10
        case let .game(ratio):
            60 + ratio * 40
        case .win:
            100
        case .loss:
            20
        }
    }

    private var spawnInterval: TimeInterval {
        switch state {
        case .menu:
            3.0
        case .settings:
            6.0
        case let .game(ratio):
            2.0 - ratio * 1.0
        case .win, .loss:
            1.0
        }
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.1 : 1.0 / 60.0)) { timeline in
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                let relativeTime = startTime > 0 ? currentTime - startTime : 0

                Canvas { context, size in
                    // Draw all traces
                    for (index, trace) in traces.enumerated() {
                        CircuitTracesRenderer.drawTrace(
                            context: context,
                            trace: trace,
                            palette: currentPalette,
                            relativeTime: relativeTime,
                            isShortCircuiting: index == shortCircuitIndex
                        )
                    }

                    // Draw particle burst for win state
                    if particleBurst {
                        CircuitTracesRenderer.drawParticleBurst(
                            context: context,
                            size: size,
                            palette: currentPalette,
                            convergenceProgress: convergenceProgress
                        )
                    }
                }
                .onChange(of: currentTime) { newTime in
                    if startTime > 0 {
                        let relTime = newTime - startTime
                        updateTracesState(relativeTime: relTime, size: geometry.size)
                    }
                }
            }
            .onAppear {
                viewSize = geometry.size
                startTime = Date().timeIntervalSinceReferenceDate
                initializeTraces(size: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                viewSize = newSize
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

    // MARK: - Trace Management

    private func initializeTraces(size: CGSize) {
        let count = (traceCount.min + traceCount.max) / 2
        var newTraces: [Trace] = []

        for i in 0..<count {
            // Stagger creation times so traces appear at different growth stages
            let staggeredTime = Double(i) * -0.5
            newTraces.append(generateTrace(in: size, relativeTime: staggeredTime))
        }

        traces = newTraces
        lastTraceTime = 0
    }

    private func updateTracesState(relativeTime: TimeInterval, size: CGSize) {
        // Throttle updates to ~30fps for state changes
        guard relativeTime - lastUpdateTime > 0.033 else { return }
        lastUpdateTime = relativeTime

        // Spawn new traces
        if relativeTime - lastTraceTime > spawnInterval, traces.count < traceCount.max {
            traces.append(generateTrace(in: size, relativeTime: relativeTime))
            lastTraceTime = relativeTime
        }

        // Update traces
        traces = traces.compactMap { trace in
            var updated = trace
            let age = relativeTime - trace.creationTime

            // Update growth
            if updated.growthProgress < 1.0 {
                updated.growthProgress = min(1.0, max(0, age / 1.0)) // 1 second growth
            }

            // Update pulses
            updated.pulses = updated.pulses.compactMap { pulse in
                var updatedPulse = pulse
                let totalLen = max(1, trace.totalLength)
                updatedPulse.position += pulse.speed * 0.033 / Double(totalLen)
                updatedPulse.position = min(1.0, updatedPulse.position)

                // Fade out at end
                if updatedPulse.position > 0.8 {
                    updatedPulse.opacity = (1.0 - updatedPulse.position) / 0.2
                }

                return updatedPulse.position < 1.0 ? updatedPulse : nil
            }

            // Add new pulses randomly
            if updated.pulses.count < 3, updated.growthProgress > 0.3, Double.random(in: 0...1) < 0.03 {
                updated.pulses.append(Trace.Pulse(
                    position: 0,
                    opacity: 1.0,
                    speed: pulseSpeed
                ))
            }

            // Fade out old traces
            if age > trace.lifetime {
                updated.opacity -= 0.02
            }

            return updated.opacity > 0 ? updated : nil
        }
    }

    private func generateTrace(in size: CGSize, relativeTime: TimeInterval) -> Trace {
        var segments: [CGPoint] = []

        // Start from a random edge
        let edge = Int.random(in: 0..<4)
        let startPoint = switch edge {
        case 0: // Top
            CGPoint(x: CGFloat.random(in: 0...size.width), y: 0)
        case 1: // Right
            CGPoint(x: size.width, y: CGFloat.random(in: 0...size.height))
        case 2: // Bottom
            CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
        default: // Left
            CGPoint(x: 0, y: CGFloat.random(in: 0...size.height))
        }

        segments.append(startPoint)
        var currentPoint = startPoint
        var isHorizontal = edge == 0 || edge == 2 // Start horizontal if from top/bottom

        // Generate 3-7 segments
        let segmentCount = Int.random(in: 3...7)
        for _ in 0..<segmentCount {
            let length = CGFloat.random(in: 30...120)

            let nextPoint: CGPoint
            if isHorizontal {
                let direction: CGFloat = currentPoint.x < size.width / 2 ? 1 : -1
                nextPoint = CGPoint(
                    x: max(0, min(size.width, currentPoint.x + length * direction)),
                    y: currentPoint.y
                )
            } else {
                let direction: CGFloat = currentPoint.y < size.height / 2 ? 1 : -1
                nextPoint = CGPoint(
                    x: currentPoint.x,
                    y: max(0, min(size.height, currentPoint.y + length * direction))
                )
            }

            segments.append(nextPoint)
            currentPoint = nextPoint
            isHorizontal.toggle()
        }

        // Start with a pulse
        let initialPulse = Trace.Pulse(position: 0, opacity: 1.0, speed: pulseSpeed)

        return Trace(
            segments: segments,
            opacity: 0.6,
            pulses: [initialPulse],
            growthProgress: 0,
            creationTime: relativeTime,
            lifetime: 10.0
        )
    }

    // MARK: - Effects

    private func triggerWinEffect() {
        guard !reduceMotion else { return }

        // All traces illuminate
        for i in 0..<traces.count {
            traces[i].opacity = 1.0
        }

        // Pulses converge to center
        particleBurst = true
        withAnimation(.easeInOut(duration: 1.5)) {
            convergenceProgress = 1.0
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            particleBurst = false
            convergenceProgress = 0
        }
    }

    private func triggerLossEffect() {
        guard !reduceMotion else { return }

        // Short-circuit traces one by one
        for i in 0..<min(traces.count, 10) {
            let delay = Double(i) * 0.2

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                shortCircuitIndex = i

                // Dim after flash
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if traces.count > i {
                        traces[i].opacity = 0.2
                    }
                }
            }
        }

        // Reset short circuit index
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            shortCircuitIndex = -1
        }
    }
}

#Preview {
    VStack {
        CircuitTracesBackground(state: .menu)
            .frame(height: 200)
        CircuitTracesBackground(state: .game(bufferFillRatio: 0.5))
            .frame(height: 200)
    }
}
