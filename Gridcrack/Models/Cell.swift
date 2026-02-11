import Foundation

struct Cell: Identifiable, Equatable {
    let id: UUID
    var code: String
    let row: Int
    let col: Int
    var isSelected: Bool
    var cellType: CellType

    init(code: String, row: Int, col: Int, isSelected: Bool = false, cellType: CellType = .normal) {
        id = UUID()
        self.code = code
        self.row = row
        self.col = col
        self.isSelected = isSelected
        self.cellType = cellType
    }

    var position: Position {
        Position(row: row, col: col)
    }

    // MARK: - Cell Type Convenience Properties

    /// Whether this cell is blocked and cannot be selected
    var isBlocked: Bool {
        cellType.isBlocked
    }

    /// Whether this cell is a wildcard that matches any code
    var isWildcard: Bool {
        cellType.isWildcard
    }

    /// Whether this cell is a decay cell
    var isDecay: Bool {
        cellType.isDecay
    }

    /// The number of moves remaining before decay, or nil if not a decay cell
    var decayMovesRemaining: Int? {
        cellType.decayMovesRemaining
    }

    /// The code to display (handles wildcard display)
    var displayCode: String {
        cellType.displayCode ?? code
    }

    // MARK: - Static Properties

    static let availableCodes = ["1C", "BD", "55", "E9", "7A", "FF"]

    static func randomCode() -> String {
        availableCodes.randomElement() ?? "1C"
    }
}
