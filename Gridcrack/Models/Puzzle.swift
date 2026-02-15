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
        case .easy: Int.random(in: 1...2)
        case .medium: Int.random(in: 1...2)
        case .hard: Int.random(in: 2...3)
        case .expert: Int.random(in: 2...4)
        }
    }

    var sequenceCountRange: ClosedRange<Int> {
        switch self {
        case .easy: 1...2
        case .medium: 1...2
        case .hard: 2...3
        case .expert: 2...4
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

    /// Estimated buffer size for display purposes (actual is par + bufferMargin, capped at 8)
    var bufferSize: Int {
        switch self {
        case .easy: 7
        case .medium: 7
        case .hard, .expert: 8
        }
    }

    /// Whether the solver quality gate runs (only expert with 4+ sequences)
    var usesSolverQualityGate: Bool {
        switch self {
        case .easy, .medium, .hard: false
        case .expert: true
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
