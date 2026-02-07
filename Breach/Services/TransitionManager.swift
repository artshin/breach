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

@MainActor
final class TransitionManager: ObservableObject {
    @Published private(set) var phase: TransitionPhase = .idle
    @Published private(set) var style: TransitionStyle = .hexDissolve

    let gridCols = 20
    let gridRows = 36

    private(set) var cells: [DissolveCell] = []
    private var phaseStart: Date = .distantPast

    var isActive: Bool {
        phase != .idle
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
        cells = Self.generateCells(cols: gridCols, rows: gridRows)

        HapticsManager.shared.lightImpact()
        beginPhase(.covering)

        let coverTime = phaseDuration(.covering)
        let midTime = phaseDuration(.covered)
        let revealTime = phaseDuration(.revealing)

        DispatchQueue.main.asyncAfter(deadline: .now() + coverTime) { [weak self] in
            guard let self else { return }
            beginPhase(.covered)

            // Disable UIKit animations for the entire covered phase so
            // NavigationStack's push/pop slide never plays.
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

    // MARK: - Private

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

    private static func generateCells(cols: Int, rows: Int) -> [DissolveCell] {
        let centerCol = CGFloat(cols) / 2.0
        let centerRow = CGFloat(rows) / 2.0
        let maxDist = sqrt(centerCol * centerCol + centerRow * centerRow)

        var result: [DissolveCell] = []
        result.reserveCapacity(cols * rows)

        for row in 0..<rows {
            for col in 0..<cols {
                let dx = CGFloat(col) - centerCol
                let dy = CGFloat(row) - centerRow
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
