import SwiftUI

struct MatrixGridView<VM: GamePlayable>: View {
    @ObservedObject var viewModel: VM
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private let spacing: CGFloat = 4
    private let padding: CGFloat = 8

    private func cellSize(for availableWidth: CGFloat) -> CGFloat {
        let gridSize = viewModel.grid.count
        guard gridSize > 0 else { return 50 }
        let totalSpacing = spacing * CGFloat(gridSize - 1) + (padding * 2)
        let calculatedSize = (availableWidth - totalSpacing) / CGFloat(gridSize)

        let minSize: CGFloat = 44
        let maxSize: CGFloat = horizontalSizeClass == .regular ? 80 : 60

        return min(max(calculatedSize, minSize), maxSize)
    }

    var body: some View {
        let advancingPositions = viewModel.advancingPositions()

        GeometryReader { geo in
            let size = cellSize(for: geo.size.width)
            let gridCount = viewModel.grid.count
            let gridWidth = CGFloat(gridCount) * size
                + CGFloat(max(0, gridCount - 1)) * spacing + padding * 2

            VStack(spacing: spacing) {
                ForEach(0..<viewModel.grid.count, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(viewModel.grid[row]) { cell in
                            CellView(
                                cell: cell,
                                cellSize: size,
                                isValid: viewModel.isValidSelection(cell: cell),
                                advancesSequence: advancingPositions.contains(cell.position),
                                isHighlightedRow: viewModel.getHighlightedRow() == cell.row,
                                isHighlightedCol: viewModel.getHighlightedColumn() == cell.col,
                                onTap: {
                                    viewModel.selectCell(cell)
                                }
                            )
                        }
                    }
                }
            }
            .padding(padding)
            .background(
                Rectangle()
                    .stroke(BreachColors.borderSecondary, lineWidth: 1)
            )
            .frame(width: gridWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

// MARK: - Cell View

struct CellView: View {
    let cell: Cell
    let cellSize: CGFloat
    let isValid: Bool
    let advancesSequence: Bool
    let isHighlightedRow: Bool
    let isHighlightedCol: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            guard !cell.isBlocked else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            onTap()
        } label: {
            ZStack {
                if cell.isBlocked {
                    Image(systemName: "xmark")
                        .font(.system(size: cellSize > 50 ? 20 : 16, weight: .bold))
                        .foregroundColor(BreachColors.cellBlocked.opacity(0.7))
                } else if cell.isWildcard {
                    Text("??")
                        .font(.system(size: cellSize > 50 ? 18 : 16, weight: .bold, design: .monospaced))
                        .foregroundColor(BreachColors.cellWildcard)
                } else if let decayMoves = cell.decayMovesRemaining {
                    VStack(spacing: 0) {
                        Text(cell.code)
                            .font(.system(
                                size: cellSize > 50 ? 14 : 12,
                                weight: .bold,
                                design: .monospaced
                            ))
                            .foregroundColor(textColor)
                        Text("\(decayMoves)")
                            .font(.system(
                                size: cellSize > 50 ? 10 : 8,
                                weight: .bold,
                                design: .monospaced
                            ))
                            .foregroundColor(BreachColors.cellDecay)
                    }
                } else {
                    Text(cell.displayCode)
                        .font(.system(
                            size: cellSize > 50 ? 18 : 16,
                            weight: .bold,
                            design: .monospaced
                        ))
                        .foregroundColor(textColor)
                }
            }
            .frame(width: cellSize, height: cellSize)
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .opacity(cell.isSelected ? 0.5 : (cell.isBlocked ? 0.6 : 1.0))
        .animation(.easeInOut(duration: 0.2), value: cell.isSelected)
        .disabled(cell.isSelected || !isValid || cell.isBlocked)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityLabel: String {
        if cell.isBlocked {
            return "Blocked cell, row \(cell.row + 1), column \(cell.col + 1)"
        }
        if cell.isWildcard {
            return "Wildcard cell, row \(cell.row + 1), column \(cell.col + 1)"
        }
        var label = "Code \(cell.code), row \(cell.row + 1), column \(cell.col + 1)"
        if cell.isSelected {
            label += ", already selected"
        }
        if let decayMoves = cell.decayMovesRemaining {
            label += ", decays in \(decayMoves) moves"
        }
        return label
    }

    private var accessibilityHint: String {
        if cell.isBlocked {
            return "This cell is blocked and cannot be selected"
        }
        if cell.isSelected {
            return "This cell has already been used"
        }
        if !isValid {
            return "Not available, must select from current row or column"
        }
        if cell.isWildcard {
            return "Wildcard matches any sequence code"
        }
        if advancesSequence {
            return "Selecting this advances a target sequence"
        }
        return "Double tap to select"
    }

    private var textColor: Color {
        if cell.isSelected {
            return BreachColors.cellSelected
        }
        if cell.isWildcard {
            return BreachColors.cellWildcard
        }
        if cell.isDecay {
            return BreachColors.cellDecay
        }
        if advancesSequence, isValid {
            return BreachColors.cellAdvancing
        }
        if isValid {
            return BreachColors.textPrimary
        }
        return BreachColors.accent.opacity(0.7)
    }

    private var backgroundColor: Color {
        if cell.isBlocked {
            return BreachColors.cellBlocked.opacity(0.1)
        }
        if cell.isSelected {
            return BreachColors.cellSelected.opacity(0.2)
        }
        if cell.isWildcard {
            return BreachColors.cellWildcard.opacity(0.15)
        }
        if cell.isDecay {
            return BreachColors.cellDecay.opacity(0.1)
        }
        if advancesSequence && isValid {
            return BreachColors.cellAdvancing.opacity(0.15)
        }
        if isValid {
            return BreachColors.cellValid.opacity(0.15)
        }
        if isHighlightedRow || isHighlightedCol {
            return BreachColors.cellHighlight
        }
        return BreachColors.background
    }

    private var borderColor: Color {
        if cell.isBlocked {
            return BreachColors.cellBlocked.opacity(0.5)
        }
        if cell.isSelected {
            return BreachColors.cellSelected.opacity(0.3)
        }
        if cell.isWildcard {
            return BreachColors.cellWildcard
        }
        if cell.isDecay {
            return BreachColors.cellDecay.opacity(0.7)
        }
        if advancesSequence, isValid {
            return BreachColors.cellAdvancing
        }
        if isValid {
            return BreachColors.cellValid
        }
        return BreachColors.borderSecondary
    }

    private var borderWidth: CGFloat {
        if cell.isWildcard, isValid {
            return 2.5
        }
        if advancesSequence, isValid {
            return 2.5
        }
        return isValid ? 2 : 1
    }

    private var shadowColor: Color {
        if cell.isWildcard, isValid {
            return BreachColors.cellWildcard.opacity(0.5)
        }
        if advancesSequence, isValid {
            return BreachColors.cellAdvancing.opacity(0.5)
        }
        return .clear
    }

    private var shadowRadius: CGFloat {
        if cell.isWildcard, isValid {
            return 6
        }
        return advancesSequence && isValid ? 6 : 0
    }
}

#Preview {
    MatrixGridView(viewModel: GameViewModel())
        .background(BreachColors.background)
}
