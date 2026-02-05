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
            return 0
        case .finished(let completed, let total, let moves, let par):
            if completed == 0 {
                return 0
            } else if completed < total {
                return 1 // Partial
            } else if moves <= par {
                return 3 // Optimal
            } else {
                return 2 // Full but not optimal
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
        case .horizontal(let row): return row
        case .vertical(let col): return col
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

    // Track last selected position for pathfinding
    var lastPosition: Position?

    init(puzzle: Puzzle) {
        self.grid = puzzle.grid
        self.bufferSize = puzzle.bufferSize
        self.buffer = []
        self.sequences = puzzle.sequences
        self.selectionMode = .horizontal(row: 0)
        self.gameResult = .playing
        self.moveCount = 0
        self.par = puzzle.par
        self.difficulty = puzzle.difficulty
        self.lastPosition = nil
    }

    // Convenience initializer for default game
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
        sequences.filter { $0.isComplete }.count
    }

    var allSequencesComplete: Bool {
        sequences.allSatisfy { $0.isComplete }
    }
}
