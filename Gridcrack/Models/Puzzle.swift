import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String {
        rawValue
    }

    var displayName: String {
        rawValue.capitalized
    }

    var gridSize: Int {
        switch self {
        case .easy, .medium, .hard: 5
        case .expert: 6
        }
    }

    var sequenceCount: Int {
        switch self {
        case .easy: 1
        case .medium: 2
        case .hard: 2
        case .expert: 3
        }
    }

    var sequenceLengths: ClosedRange<Int> {
        switch self {
        case .easy: 3...4
        case .medium: 3...3
        case .hard: 3...4
        case .expert: 3...4
        }
    }

    /// How many of 6 available codes to use (fewer = more ambiguity)
    var codePoolSize: Int {
        switch self {
        case .easy: 6
        case .medium: 5
        case .hard: Int.random(in: 4...5)
        case .expert: 4
        }
    }

    /// Buffer = par + margin. Par is computed by the solver.
    var bufferMargin: Int {
        switch self {
        case .easy: 3
        case .medium: 2
        case .hard: 1
        case .expert: Int.random(in: 0...1)
        }
    }

    /// Estimated buffer size for display purposes (actual is par + bufferMargin)
    var bufferSize: Int {
        switch self {
        case .easy: 7
        case .medium: 7
        case .hard: 8
        case .expert: 9
        }
    }

    /// Accept puzzles with at most this many distinct solutions
    var maxSolutions: Int {
        switch self {
        case .easy: 100
        case .medium: 8
        case .hard: 3
        case .expert: 2
        }
    }

    /// Require at least this many row-0 dead ends for confusion
    var minFalseStarts: Int {
        switch self {
        case .easy: 0
        case .medium: 1
        case .hard: 2
        case .expert: 3
        }
    }
}

struct Puzzle {
    let grid: [[Cell]]
    let sequences: [TargetSequence]
    let bufferSize: Int
    let par: Int
    let difficulty: Difficulty
    let solutionPath: [Position]

    var gridSize: Int {
        grid.count
    }
}
