import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var gridSize: Int {
        switch self {
        case .easy, .medium, .hard: return 5
        case .expert: return 6
        }
    }

    var bufferSize: Int {
        switch self {
        case .easy: return 7
        case .medium: return 6
        case .hard: return 5
        case .expert: return 5
        }
    }

    var sequenceCount: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 2
        case .expert: return 3
        }
    }

    var sequenceLengths: [Int] {
        switch self {
        case .easy: return [3]
        case .medium: return [3, 3]
        case .hard: return [3, 3]
        case .expert: return [3, 3, 3]
        }
    }

    var requiresOverlap: Bool {
        switch self {
        case .easy: return false
        case .medium, .hard, .expert: return true
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
