import SwiftUI

// MARK: - Pixel Cell

struct PixelCell {
    let row: Int
    let col: Int
    let threshold: Double
}

// MARK: - Pixelate Canvas

/// Reusable canvas that draws a solid background normally and dissolves
/// into a pixel grid when `isPressed` is true. Drop into any `.background {}`.
struct PixelateCanvas: View {
    let isPressed: Bool
    let color: Color
    var fillColor: Color = BreachColors.surfacePrimary
    var fillOpacity = 0.9
    var tintOpacity = 0.1

    @State private var cells: [PixelCell] = []
    @State private var transitionStart: Date = .distantPast
    @State private var isDissolving = false
    @State private var snapshot: Double = 0

    private let cols = 20
    private let rows = 6
    private let dissolveDur = 0.3
    private let reformDur = 0.2
    private let maxGap: CGFloat = 2

    var body: some View {
        TimelineView(.animation) { timeline in
            let progress = progress(at: timeline.date)
            Canvas { ctx, size in
                if progress < 0.001 {
                    drawSolid(context: &ctx, size: size)
                } else {
                    drawCells(context: &ctx, size: size, progress: CGFloat(progress))
                }
            }
        }
        .onAppear { buildCells() }
        .onChange(of: isPressed) { _, pressed in
            snapshot = progress(at: .now)
            transitionStart = .now
            isDissolving = pressed
            if pressed { buildCells() }
        }
    }
}

// MARK: - Animation

extension PixelateCanvas {
    func progress(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(transitionStart)
        let raw: Double

        if isDissolving {
            let frac = min(elapsed / dissolveDur, 1)
            raw = snapshot + (1 - snapshot) * frac
        } else {
            let frac = min(elapsed / reformDur, 1)
            raw = snapshot * (1 - frac)
        }

        return min(max(raw, 0), 1)
    }
}

// MARK: - Drawing

extension PixelateCanvas {
    func drawSolid(context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .color(fillColor.opacity(fillOpacity)))
        if tintOpacity > 0 {
            context.fill(Path(rect), with: .color(color.opacity(tintOpacity)))
        }
    }

    func drawCells(
        context: inout GraphicsContext,
        size: CGSize,
        progress: CGFloat
    ) {
        let cellW = size.width / CGFloat(cols)
        let cellH = size.height / CGFloat(rows)
        let gap = maxGap * progress

        for cell in cells {
            drawSingleCell(
                context: &context,
                cell: cell,
                cellW: cellW,
                cellH: cellH,
                gap: gap,
                progress: progress
            )
        }
    }

    func drawSingleCell(
        context: inout GraphicsContext,
        cell: PixelCell,
        cellW: CGFloat,
        cellH: CGFloat,
        gap: CGFloat,
        progress: CGFloat
    ) {
        let opacity = cellOpacity(threshold: cell.threshold, progress: progress)
        guard opacity > 0.01 else { return }

        let rect = cellRect(cell: cell, cellW: cellW, cellH: cellH, gap: gap)
        guard rect.width > 0, rect.height > 0 else { return }

        context.fill(Path(rect), with: .color(fillColor.opacity(fillOpacity * opacity)))
        if tintOpacity > 0 {
            context.fill(Path(rect), with: .color(color.opacity(tintOpacity * opacity)))
        }
        drawEdgeGlow(context: &context, rect: rect, cell: cell, progress: progress)
    }
}

// MARK: - Cell Helpers

extension PixelateCanvas {
    func cellRect(
        cell: PixelCell,
        cellW: CGFloat,
        cellH: CGFloat,
        gap: CGFloat
    ) -> CGRect {
        CGRect(
            x: CGFloat(cell.col) * cellW + gap / 2,
            y: CGFloat(cell.row) * cellH + gap / 2,
            width: cellW - gap,
            height: cellH - gap
        )
    }

    func cellOpacity(threshold: Double, progress: CGFloat) -> CGFloat {
        let start = CGFloat(threshold)
        let fadeWindow: CGFloat = 0.2
        if progress < start { return 1 }
        return max(1 - (progress - start) / fadeWindow, 0)
    }

    func drawEdgeGlow(
        context: inout GraphicsContext,
        rect: CGRect,
        cell: PixelCell,
        progress: CGFloat
    ) {
        let dist = abs(progress - CGFloat(cell.threshold))
        guard dist < 0.1 else { return }

        let glow = (1 - dist / 0.1) * 0.5
        context.stroke(
            Path(rect),
            with: .color(color.opacity(glow)),
            lineWidth: 1
        )
    }
}

// MARK: - Cell Generation

extension PixelateCanvas {
    func buildCells() {
        let midC = Double(cols) / 2
        let midR = Double(rows) / 2
        let maxDist = sqrt(midC * midC + midR * midR)

        cells = (0..<rows).flatMap { row in
            (0..<cols).map { col in
                let dx = Double(col) - midC + 0.5
                let dy = Double(row) - midR + 0.5
                let dist = sqrt(dx * dx + dy * dy) / maxDist
                let threshold = dist * 0.65 + Double.random(in: 0...0.3)

                return PixelCell(row: row, col: col, threshold: min(threshold, 0.95))
            }
        }
    }
}

// MARK: - Pixel Press Style

/// ButtonStyle that replaces the background with a PixelateCanvas.
/// Use on buttons that define their own chrome (border, gradient, etc.)
/// in the label — this style only adds the pixelated background + scale.
struct PixelPressStyle: ButtonStyle {
    var color: Color = BreachColors.accent
    var fillOpacity = 0.9
    var tintOpacity = 0.1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                PixelateCanvas(
                    isPressed: configuration.isPressed,
                    color: color,
                    fillOpacity: fillOpacity,
                    tintOpacity: tintOpacity
                )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Standalone Pixelate Button Style

/// Complete button style with pixelated background + border.
/// For buttons that don't have their own chrome.
struct PixelateButtonStyle: ButtonStyle {
    var color: Color = BreachColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                PixelateCanvas(
                    isPressed: configuration.isPressed,
                    color: color
                )
            }
            .overlay {
                Rectangle()
                    .stroke(color.opacity(0.2), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func pixelateButtonStyle(color: Color = BreachColors.accent) -> some View {
        buttonStyle(PixelateButtonStyle(color: color))
    }

    func pixelPressStyle(
        color: Color = BreachColors.accent,
        fillOpacity: Double = 0.9,
        tintOpacity: Double = 0.1
    ) -> some View {
        buttonStyle(PixelPressStyle(
            color: color,
            fillOpacity: fillOpacity,
            tintOpacity: tintOpacity
        ))
    }
}
