import SwiftUI

// MARK: - Transition Overlay

struct TransitionOverlay: View {
    @EnvironmentObject private var manager: TransitionManager

    var body: some View {
        if manager.isActive {
            dissolveOverlay
        }
    }

    private var dissolveOverlay: some View {
        TimelineView(.animation) { timeline in
            let prog = manager.progress(at: timeline.date)
            Canvas { context, size in
                drawDissolve(context: &context, size: size, progress: prog)
            }
            .overlay {
                if manager.phase == .covered,
                   manager.style == .breachInitiated {
                    breachText(progress: prog)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }

    // MARK: - Dissolve Drawing

    private func drawDissolve(
        context: inout GraphicsContext,
        size: CGSize,
        progress: Double
    ) {
        let cellWidth = size.width / CGFloat(manager.gridCols)
        let cellHeight = size.height / CGFloat(manager.gridRows)
        let prog = CGFloat(progress)

        switch manager.phase {
        case .idle:
            break

        case .covering:
            drawCoveringCells(
                context: &context,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                progress: prog
            )

        case .covered:
            let fullRect = CGRect(origin: .zero, size: size)
            context.fill(Path(fullRect), with: .color(BreachColors.background))

        case .revealing:
            drawRevealingCells(
                context: &context,
                size: size,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                progress: prog
            )
        }
    }

    // MARK: - Covering Phase

    private func drawCoveringCells(
        context: inout GraphicsContext,
        cellWidth: CGFloat,
        cellHeight: CGFloat,
        progress: CGFloat
    ) {
        for cell in manager.cells {
            guard progress >= cell.threshold else { continue }

            let xPos = CGFloat(cell.col) * cellWidth
            let yPos = CGFloat(cell.row) * cellHeight
            let rect = CGRect(x: xPos, y: yPos, width: cellWidth, height: cellHeight)

            context.fill(Path(rect), with: .color(BreachColors.background))

            // Leading edge glow
            let edgeDist = abs(progress - cell.threshold)
            if edgeDist < 0.08 {
                let glowOpacity = (1.0 - edgeDist / 0.08) * 0.4
                context.stroke(
                    Path(rect),
                    with: .color(BreachColors.accent.opacity(glowOpacity)),
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Revealing Phase

    private func drawRevealingCells(
        context: inout GraphicsContext,
        size: CGSize,
        cellWidth: CGFloat,
        cellHeight: CGFloat,
        progress: CGFloat
    ) {
        // Start with full dark, then remove cells
        let fullRect = CGRect(origin: .zero, size: size)
        context.fill(Path(fullRect), with: .color(BreachColors.background))

        for cell in manager.cells {
            // Invert threshold so reveal goes edges→center (reverse of cover)
            let revealThreshold = 1.0 - cell.threshold
            guard progress >= revealThreshold else { continue }

            let xPos = CGFloat(cell.col) * cellWidth
            let yPos = CGFloat(cell.row) * cellHeight
            let rect = CGRect(x: xPos, y: yPos, width: cellWidth + 0.5, height: cellHeight + 0.5)

            // Clear this cell by drawing it with .clear blendMode
            context.blendMode = .clear
            context.fill(Path(rect), with: .color(.white))
            context.blendMode = .normal

            // Leading edge glow
            let edgeDist = abs(progress - revealThreshold)
            if edgeDist < 0.08 {
                let glowOpacity = (1.0 - edgeDist / 0.08) * 0.4
                context.stroke(
                    Path(rect),
                    with: .color(BreachColors.accent.opacity(glowOpacity)),
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Breach Text

    private func breachText(progress: Double) -> some View {
        let pulseOpacity = 0.7 + 0.3 * sin(progress * .pi * 4)

        return Text("INITIATING BREACH...")
            .font(.system(size: 18, weight: .bold, design: .monospaced))
            .foregroundColor(BreachColors.accent)
            .opacity(pulseOpacity)
            .shadow(color: BreachColors.accent.opacity(0.6), radius: 12)
            .shadow(color: BreachColors.accent.opacity(0.3), radius: 24)
    }
}
