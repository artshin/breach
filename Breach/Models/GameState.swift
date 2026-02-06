import Foundation

enum GameResult: Equatable {
    case playing
    case finished(completedSequences: Int, totalSequences: Int, moves: Int, par: Int)

    var isGameOver: Bool {
        if case .playing = self { return false }
        return true
    }

    var stars: Int {
        switch self {
        case .playing:
            0
        case let .finished(completed, total, moves, par):
            if completed == 0 {
                0
            } else if completed < total {
                1 // Partial
            } else if moves <= par {
                3 // Optimal
            } else {
                2 // Full but not optimal
            }
        }
    }
}

enum SelectionMode: Equatable {
    case horizontal(row: Int)
    case vertical(col: Int)

    var isHorizontal: Bool {
        if case .horizontal = self { return true }
        return false
    }

    var constraintIndex: Int {
        switch self {
        case let .horizontal(row): row
        case let .vertical(col): col
        }
    }
}

struct GameState: Equatable {
    var grid: [[Cell]]
    var buffer: [String]
    let bufferSize: Int
    var sequences: [TargetSequence]
    var selectionMode: SelectionMode
    var gameResult: GameResult
    var moveCount: Int
    let par: Int
    let difficulty: Difficulty

    /// Track last selected position for pathfinding
    var lastPosition: Position?

    init(puzzle: Puzzle) {
        grid = puzzle.grid
        bufferSize = puzzle.bufferSize
        buffer = []
        sequences = puzzle.sequences
        selectionMode = .horizontal(row: 0)
        gameResult = .playing
        moveCount = 0
        par = puzzle.par
        difficulty = puzzle.difficulty
        lastPosition = nil
    }

    /// Convenience initializer for default game
    init(difficulty: Difficulty = .easy) {
        let puzzle = PuzzleGenerator.generate(difficulty: difficulty)
        self.init(puzzle: puzzle)
    }

    var usedCells: Set<Position> {
        var positions: Set<Position> = []
        for row in grid {
            for cell in row where cell.isSelected {
                positions.insert(cell.position)
            }
        }
        return positions
    }

    var currentPosition: Position {
        lastPosition ?? Position(row: 0, col: 0)
    }

    var completedSequenceCount: Int {
        sequences.filter(\.isComplete).count
    }

    var allSequencesComplete: Bool {
        sequences.allSatisfy(\.isComplete)
    }
}
