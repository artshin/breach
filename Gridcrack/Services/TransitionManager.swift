import Observation
import SwiftUI

// MARK: - Transition Style

enum TransitionStyle {
    case hexDissolve
    case breachInitiated
}

// MARK: - Transition Phase

enum TransitionPhase {
    case idle
    case covering
    case covered
    case revealing
}

// MARK: - Dissolve Cell

struct DissolveCell {
    let col: Int
    let row: Int
    let threshold: CGFloat
}

// MARK: - Transition Manager

@MainActor @Observable
final class TransitionManager {
    private(set) var phase: TransitionPhase = .idle
    private(set) var style: TransitionStyle = .hexDissolve

    let gridCols = 20
    let gridRows = 36

    private(set) var cells: [DissolveCell] = []
    private var phaseStart: Date = .distantPast
    private var tapScreenPoint: CGPoint?
    private var touchTracker: TouchTracker?

    var isActive: Bool {
        phase != .idle
    }

    // MARK: - Touch Tracking

    func installTouchTracker() {
        guard touchTracker == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first
        else { return }
        let tracker = TouchTracker { [weak self] point in
            self?.tapScreenPoint = point
        }
        window.addGestureRecognizer(tracker)
        touchTracker = tracker
    }

    // MARK: - Progress

    func progress(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(phaseStart)
        let duration = phaseDuration(phase)
        guard duration > 0 else { return 1.0 }
        return min(max(elapsed / duration, 0), 1.0)
    }

    // MARK: - Transition Entry Point

    func transition(
        style: TransitionStyle = .hexDissolve,
        action: @escaping () -> Void
    ) {
        guard phase == .idle else { return }

        if UIAccessibility.isReduceMotionEnabled {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
            return
        }

        self.style = style
        let origin = normalizedOrigin()
        cells = Self.generateCells(cols: gridCols, rows: gridRows, origin: origin)

        HapticsManager.shared.lightImpact()
        SoundManager.shared.playTransitionWhoosh()
        beginPhase(.covering)

        schedulePhaseCascade(action: action)
    }

    // MARK: - Private

    private func normalizedOrigin() -> CGPoint {
        guard let point = tapScreenPoint else {
            return CGPoint(x: 0.5, y: 0.5)
        }
        let screen = UIScreen.main.bounds.size
        return CGPoint(
            x: point.x / screen.width,
            y: point.y / screen.height
        )
    }

    private func schedulePhaseCascade(action: @escaping () -> Void) {
        let coverTime = phaseDuration(.covering)
        let midTime = phaseDuration(.covered)
        let revealTime = phaseDuration(.revealing)

        DispatchQueue.main.asyncAfter(deadline: .now() + coverTime) { [weak self] in
            guard let self else { return }
            beginPhase(.covered)
            UIView.setAnimationsEnabled(false)
            action()

            DispatchQueue.main.asyncAfter(deadline: .now() + midTime) { [weak self] in
                guard let self else { return }
                UIView.setAnimationsEnabled(true)
                beginPhase(.revealing)

                DispatchQueue.main.asyncAfter(deadline: .now() + revealTime) { [weak self] in
                    guard let self else { return }
                    phase = .idle
                }
            }
        }
    }

    private func beginPhase(_ newPhase: TransitionPhase) {
        phaseStart = Date()
        phase = newPhase
    }

    private func phaseDuration(_ targetPhase: TransitionPhase) -> TimeInterval {
        switch targetPhase {
        case .idle: 0
        case .covering: 0.25
        case .covered:
            style == .breachInitiated ? 0.35 : 0.06
        case .revealing: 0.25
        }
    }

    // MARK: - Cell Generation

    private static func generateCells(
        cols: Int,
        rows: Int,
        origin: CGPoint
    ) -> [DissolveCell] {
        let originCol = origin.x * CGFloat(cols)
        let originRow = origin.y * CGFloat(rows)

        // Max distance is to the farthest corner from origin
        let corners: [CGPoint] = [
            .zero, CGPoint(x: CGFloat(cols), y: 0),
            CGPoint(x: 0, y: CGFloat(rows)), CGPoint(x: CGFloat(cols), y: CGFloat(rows))
        ]
        let maxDist = corners
            .map { corner in
                let dx = corner.x - originCol
                let dy = corner.y - originRow
                return sqrt(dx * dx + dy * dy)
            }
            .max() ?? 1.0

        var result: [DissolveCell] = []
        result.reserveCapacity(cols * rows)

        for row in 0..<rows {
            for col in 0..<cols {
                let dx = CGFloat(col) - originCol
                let dy = CGFloat(row) - originRow
                let dist = sqrt(dx * dx + dy * dy)
                let normalized = dist / maxDist
                let jitter = CGFloat.random(in: -0.05...0.05)
                let threshold = min(max(normalized + jitter, 0), 1)
                result.append(DissolveCell(col: col, row: row, threshold: threshold))
            }
        }
        return result
    }
}

// MARK: - Touch Tracker

private class TouchTracker: UIGestureRecognizer {
    private let onTouch: (CGPoint) -> Void

    init(onTouch: @escaping (CGPoint) -> Void) {
        self.onTouch = onTouch
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first {
            onTouch(touch.location(in: view))
        }
        state = .failed
    }
}
