import Foundation

/// Configuration for a specific Grid Rush stage based on grid number
struct GridRushStage {
    let gridSize: Int
    let sequenceCount: Int
    let blockerCount: ClosedRange<Int>
    let decayCellCount: Int
    let wildcardChance: Double
    let timeBonus: Int
    let codePoolSize: Int
    let maxSolutions: Int
    let minFalseStarts: Int

    /// Get the stage configuration for a specific grid number
    static func forGridNumber(_ gridNumber: Int) -> Self {
        switch gridNumber {
        case 1...2: easyStage
        case 3...4: mediumStage
        case 5...6: hardStage
        default: expertStage
        }
    }

    private static var easyStage: Self {
        Self(
            gridSize: 4,
            sequenceCount: 2,
            blockerCount: 0...0,
            decayCellCount: 0,
            wildcardChance: 0.0,
            timeBonus: 15,
            codePoolSize: 6,
            maxSolutions: 100,
            minFalseStarts: 0
        )
    }

    private static var mediumStage: Self {
        Self(
            gridSize: 5,
            sequenceCount: 2,
            blockerCount: 2...3,
            decayCellCount: 0,
            wildcardChance: 0.0,
            timeBonus: 12,
            codePoolSize: 5,
            maxSolutions: 8,
            minFalseStarts: 1
        )
    }

    private static var hardStage: Self {
        Self(
            gridSize: 5,
            sequenceCount: 3,
            blockerCount: 4...5,
            decayCellCount: 0,
            wildcardChance: 0.1,
            timeBonus: 10,
            codePoolSize: Int.random(in: 4...5),
            maxSolutions: 3,
            minFalseStarts: 2
        )
    }

    private static var expertStage: Self {
        Self(
            gridSize: 6,
            sequenceCount: 3,
            blockerCount: 6...8,
            decayCellCount: 2,
            wildcardChance: 0.15,
            timeBonus: 8,
            codePoolSize: 4,
            maxSolutions: 2,
            minFalseStarts: 3
        )
    }
}

/// Global configuration values for Grid Rush mode
enum GridRushConfig {
    /// Starting time in seconds
    static let initialTime = 60

    /// Bonus time for completing a grid without wasted moves
    static let perfectClearBonus = 5

    /// Bonus time per move saved under par
    static let underParBonusPerMove = 2

    /// Time threshold (in seconds) for speed bonus
    static let speedBonusThreshold: TimeInterval = 10.0

    /// Bonus time for clearing grid under speed threshold
    static let speedBonus = 3

    /// Buffer size for Grid Rush (scales with grid size)
    static func bufferSize(for stage: GridRushStage) -> Int {
        switch stage.gridSize {
        case 4:
            6
        case 5:
            7
        case 6:
            8
        default:
            7
        }
    }

    /// Sequence length for Grid Rush
    static let sequenceLength = 3
}
