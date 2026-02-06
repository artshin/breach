import Foundation

/// Represents the type of a cell in the puzzle grid
enum CellType: Equatable, Codable {
    /// Normal cell with a code that can be selected
    case normal

    /// Blocked cell that cannot be selected, forces alternate paths
    case blocker

    /// Decay cell that changes to a random code after N moves
    case decay(movesRemaining: Int)

    /// Wildcard cell that matches any sequence code, displays "??"
    case wildcard

    // MARK: - Computed Properties

    /// Whether this cell is blocked and cannot be selected
    var isBlocked: Bool {
        if case .blocker = self { return true }
        return false
    }

    /// Whether this cell is a wildcard that matches any code
    var isWildcard: Bool {
        if case .wildcard = self { return true }
        return false
    }

    /// Whether this cell is a decay cell
    var isDecay: Bool {
        if case .decay = self { return true }
        return false
    }

    /// The number of moves remaining before decay, or nil if not a decay cell
    var decayMovesRemaining: Int? {
        if case let .decay(moves) = self { return moves }
        return nil
    }

    // MARK: - Display Properties

    /// The display code for special cell types
    var displayCode: String? {
        switch self {
        case .wildcard:
            "??"
        case .blocker:
            "XX"
        default:
            nil
        }
    }
}
