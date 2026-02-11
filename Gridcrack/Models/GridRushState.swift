import Foundation

/// Result of clearing a grid in Grid Rush mode
struct GridClearResult: Equatable {
    let baseBonus: Int
    let perfectBonus: Int
    let underParBonus: Int
    let speedBonus: Int
    let isPerfect: Bool
    let movesSaved: Int
    let wasSpeedClear: Bool

    var totalBonus: Int {
        baseBonus + perfectBonus + underParBonus + speedBonus
    }
}

/// State for a Grid Rush game session
struct GridRushState: Equatable {
    /// Current grid number (1-indexed)
    var currentGridNumber: Int

    /// Time remaining in seconds
    var timeRemaining: Int

    /// Total score accumulated
    var totalScore: Int

    /// Number of grids successfully cleared
    var gridsCompleted: Int

    /// Number of perfect clears (no wasted moves)
    var perfectClears: Int

    /// Current streak of consecutive perfect clears
    var consecutivePerfects: Int

    /// Best consecutive perfect streak in this run
    var bestPerfectStreak: Int

    /// Time when current grid started (for speed bonus calculation)
    var gridStartTime: Date?

    /// Total moves made across all grids
    var totalMoves: Int

    /// Whether the game has ended
    var isGameOver: Bool

    // MARK: - Initialization

    init() {
        currentGridNumber = 1
        timeRemaining = GridRushConfig.initialTime
        totalScore = 0
        gridsCompleted = 0
        perfectClears = 0
        consecutivePerfects = 0
        bestPerfectStreak = 0
        gridStartTime = nil
        totalMoves = 0
        isGameOver = false
    }

    // MARK: - Stage Configuration

    var currentStage: GridRushStage {
        GridRushStage.forGridNumber(currentGridNumber)
    }

    // MARK: - Bonus Calculation

    /// Calculate bonus time for clearing a grid
    /// - Parameters:
    ///   - moves: Number of moves used to clear the grid
    ///   - par: Minimum moves needed (par)
    ///   - gridClearTime: Time taken to clear the grid in seconds
    /// - Returns: GridClearResult with all bonus details
    func calculateBonusTime(moves: Int, par: Int, gridClearTime: TimeInterval) -> GridClearResult {
        let stage = currentStage

        // Base bonus from stage
        let baseBonus = stage.timeBonus

        // Perfect clear bonus (no wasted moves)
        let isPerfect = moves == par
        let perfectBonus = isPerfect ? GridRushConfig.perfectClearBonus : 0

        // Under par bonus
        let movesSaved = max(0, par - moves)
        let underParBonus = movesSaved * GridRushConfig.underParBonusPerMove

        // Speed bonus
        let wasSpeedClear = gridClearTime < GridRushConfig.speedBonusThreshold
        let speedBonus = wasSpeedClear ? GridRushConfig.speedBonus : 0

        return GridClearResult(
            baseBonus: baseBonus,
            perfectBonus: perfectBonus,
            underParBonus: underParBonus,
            speedBonus: speedBonus,
            isPerfect: isPerfect,
            movesSaved: movesSaved,
            wasSpeedClear: wasSpeedClear
        )
    }

    // MARK: - Mutations

    /// Apply a grid clear result and advance to next grid
    mutating func applyGridClear(result: GridClearResult, moves: Int) {
        // Add bonus time
        timeRemaining += result.totalBonus

        // Update stats
        gridsCompleted += 1
        totalMoves += moves

        // Track perfects
        if result.isPerfect {
            perfectClears += 1
            consecutivePerfects += 1
            bestPerfectStreak = max(bestPerfectStreak, consecutivePerfects)
        } else {
            consecutivePerfects = 0
        }

        // Calculate score (base points for completing + bonus multiplier)
        let gridPoints = 100 * currentGridNumber
        let perfectMultiplier = result.isPerfect ? 1.5 : 1.0
        let speedMultiplier = result.wasSpeedClear ? 1.2 : 1.0
        totalScore += Int(Double(gridPoints) * perfectMultiplier * speedMultiplier)

        // Advance to next grid
        currentGridNumber += 1
    }

    /// Decrement time by one second
    mutating func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        if timeRemaining <= 0 {
            isGameOver = true
        }
    }

    /// Mark the start of a new grid
    mutating func markGridStart() {
        gridStartTime = Date()
    }

    /// Get the time elapsed since grid start
    var gridElapsedTime: TimeInterval {
        guard let startTime = gridStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
}
