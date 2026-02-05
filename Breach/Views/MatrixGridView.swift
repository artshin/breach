import SwiftUI

struct MatrixGridView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private let spacing: CGFloat = 4
    private let padding: CGFloat = 8

    // Calculate cell size based on grid size and device
    private func cellSize(for availableWidth: CGFloat) -> CGFloat {
        let gridSize = viewModel.grid.count
        let totalSpacing = spacing * CGFloat(gridSize - 1) + (padding * 2)
        let calculatedSize = (availableWidth - totalSpacing) / CGFloat(gridSize)

        // Clamp between min and max sizes
        let minSize: CGFloat = 44 // Minimum touch target
        let maxSize: CGFloat = horizontalSizeClass == .regular ? 80 : 60

        return min(max(calculatedSize, minSize), maxSize)
    }

    var body: some View {
        let advancingPositions = viewModel.advancingPositions()

        GeometryReader { geo in
            let size = cellSize(for: geo.size.width)
            let gridWidth = CGFloat(viewModel.grid.count) * size + CGFloat(viewModel.grid.count - 1) * spacing + padding * 2

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
                RoundedRectangle(cornerRadius: BreachRadius.sm)
                    .stroke(BreachColors.borderSecondary, lineWidth: 1)
            )
            .frame(width: gridWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

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
        Button(action: {
            // Trigger tap animation
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            Text(cell.code)
                .font(.system(size: cellSize > 50 ? 18 : 16, weight: .bold, design: .monospaced))
                .foregroundColor(textColor)
                .frame(width: cellSize, height: cellSize)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .cornerRadius(4)
                .shadow(color: shadowColor, radius: shadowRadius)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .opacity(cell.isSelected ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: cell.isSelected)
        .disabled(cell.isSelected || !isValid)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityLabel: String {
        var label = "Code \(cell.code), row \(cell.row + 1), column \(cell.col + 1)"
        if cell.isSelected {
            label += ", already selected"
        }
        return label
    }

    private var accessibilityHint: String {
        if cell.isSelected {
            return "This cell has already been used"
        }
        if !isValid {
            return "Not available, must select from current row or column"
        }
        if advancesSequence {
            return "Selecting this advances a target sequence"
        }
        return "Double tap to select"
    }

    private var textColor: Color {
        if cell.isSelected {
            return .gray.opacity(0.5)
        }
        if advancesSequence && isValid {
            return .yellow
        }
        if isValid {
            return .white
        }
        return .cyan.opacity(0.7)
    }

    private var backgroundColor: Color {
        if cell.isSelected {
            return Color.gray.opacity(0.2)
        }
        if advancesSequence && isValid {
            return Color.yellow.opacity(0.15)
        }
        if isValid {
            return Color.cyan.opacity(0.15)
        }
        if isHighlightedRow || isHighlightedCol {
            return Color.cyan.opacity(0.05)
        }
        return Color.black
    }

    private var borderColor: Color {
        if cell.isSelected {
            return .gray.opacity(0.3)
        }
        if advancesSequence && isValid {
            return .yellow
        }
        if isValid {
            return .cyan
        }
        return .cyan.opacity(0.3)
    }

    private var borderWidth: CGFloat {
        if advancesSequence && isValid {
            return 2.5
        }
        return isValid ? 2 : 1
    }

    private var shadowColor: Color {
        if advancesSequence && isValid {
            return .yellow.opacity(0.5)
        }
        return .clear
    }

    private var shadowRadius: CGFloat {
        advancesSequence && isValid ? 6 : 0
    }
}

#Preview {
    MatrixGridView(viewModel: GameViewModel())
        .background(Color.black)
}
