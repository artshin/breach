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

    var bufferSize: Int {
        switch self {
        case .easy: 7
        case .medium: 6
        case .hard: 5
        case .expert: 5
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

    var sequenceLengths: [Int] {
        switch self {
        case .easy: [3]
        case .medium: [3, 3]
        case .hard: [3, 3]
        case .expert: [3, 3, 3]
        }
    }

    var requiresOverlap: Bool {
        switch self {
        case .easy: false
        case .medium, .hard, .expert: true
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
