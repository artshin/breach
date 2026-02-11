import Foundation

/// Generates puzzles specifically for Grid Rush mode with special cell types
enum GridRushPuzzleGenerator {
    /// Generate a puzzle for a specific Grid Rush stage
    static func generate(stage: GridRushStage) -> Puzzle {
        var attempts = 0
        let maxAttempts = 100

        while attempts < maxAttempts {
            attempts += 1

            if let puzzle = tryGenerate(stage: stage) {
                return puzzle
            }
        }

        return PuzzleGeneratorCore.generateFallback(
            gridSize: stage.gridSize,
            sequenceLength: GridRushConfig.sequenceLength,
            bufferSize: GridRushConfig.bufferSize(for: stage),
            difficulty: .medium
        )
    }

    private static func tryGenerate(stage: GridRushStage) -> Puzzle? {
        let gridSize = stage.gridSize

        // Step 1: Design sequences with overlaps
        let (sequences, mergedPath) = designSequences(stage: stage)

        // Step 2: Generate solution path through grid
        guard let (partialGrid, solutionPath) = PuzzleGeneratorCore.placeSolutionPath(
            mergedPath: mergedPath,
            gridSize: gridSize
        ) else {
            return nil
        }

        // Step 3: Fill remaining cells
        var grid = PuzzleGeneratorCore.fillRemainingCells(
            grid: partialGrid,
            solutionPath: solutionPath,
            mergedPath: mergedPath
        )

        // Step 4: Place blockers (avoiding solution path)
        grid = placeBlockers(
            grid: grid,
            solutionPath: solutionPath,
            count: Int.random(in: stage.blockerCount)
        )

        // Step 5: Place wildcard cells (based on chance)
        grid = placeWildcards(
            grid: grid,
            solutionPath: solutionPath,
            chance: stage.wildcardChance
        )

        // Step 6: Place decay cells
        grid = placeDecayCells(
            grid: grid,
            solutionPath: solutionPath,
            count: stage.decayCellCount
        )

        // Step 7: Create target sequences
        let targetSequences = sequences.map { codes in
            TargetSequence(codes: codes)
        }

        let bufferSize = GridRushConfig.bufferSize(for: stage)

        let puzzle = Puzzle(
            grid: grid,
            sequences: targetSequences,
            bufferSize: bufferSize,
            par: mergedPath.count,
            difficulty: .medium,
            solutionPath: solutionPath
        )

        // Step 8: Validate (with blocker checking)
        if PuzzleGeneratorCore.validatePuzzle(puzzle, checkBlockers: true) {
            return puzzle
        }

        return nil
    }

    // MARK: - Sequence Design

    private static func designSequences(
        stage: GridRushStage
    ) -> (sequences: [[String]], merged: [String]) {
        let codes = Cell.availableCodes
        let count = stage.sequenceCount

        if count == 1 {
            let length = Int.random(in: 3...4)
            let seq = (0..<length).map { _ in codes.randomElement()! }
            return ([seq], seq)
        }

        let overlapSize = count >= 3 ? 2 : 1
        let merged = Int.random(in: 5...6)
        let lengths = PuzzleGeneratorCore.randomLengths(
            mergedLength: merged, count: count, overlapSize: overlapSize
        )
        return PuzzleGeneratorCore.designVariableSequences(
            lengths: lengths, overlapSize: overlapSize, codes: codes
        )
    }

    // MARK: - Special Cell Placement

    private static func placeBlockers(
        grid: [[Cell]],
        solutionPath: [Position],
        count: Int
    ) -> [[Cell]] {
        guard count > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)
        var availablePositions: [Position] = []

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                if !solutionPositions.contains(pos) {
                    availablePositions.append(pos)
                }
            }
        }

        availablePositions.shuffle()
        let blockerPositions = Array(availablePositions.prefix(count))

        for pos in blockerPositions {
            modifiedGrid[pos.row][pos.col] = Cell(
                code: "XX",
                row: pos.row,
                col: pos.col,
                cellType: .blocker
            )
        }

        return modifiedGrid
    }

    private static func placeWildcards(
        grid: [[Cell]],
        solutionPath: [Position],
        chance: Double
    ) -> [[Cell]] {
        guard chance > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                if !modifiedGrid[row][col].isBlocked {
                    if Double.random(in: 0...1) < chance, !solutionPositions.contains(pos) {
                        let originalCode = modifiedGrid[row][col].code
                        modifiedGrid[row][col] = Cell(
                            code: originalCode,
                            row: row,
                            col: col,
                            cellType: .wildcard
                        )
                    }
                }
            }
        }

        return modifiedGrid
    }

    private static func placeDecayCells(
        grid: [[Cell]],
        solutionPath: [Position],
        count: Int
    ) -> [[Cell]] {
        guard count > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)
        var availablePositions: [Position] = []

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                let cell = grid[row][col]
                if !solutionPositions.contains(pos), !cell.isBlocked, !cell.isWildcard {
                    availablePositions.append(pos)
                }
            }
        }

        availablePositions.shuffle()
        let decayPositions = Array(availablePositions.prefix(count))

        for pos in decayPositions {
            let originalCode = modifiedGrid[pos.row][pos.col].code
            let movesUntilDecay = Int.random(in: 3...5)
            modifiedGrid[pos.row][pos.col] = Cell(
                code: originalCode,
                row: pos.row,
                col: pos.col,
                cellType: .decay(movesRemaining: movesUntilDecay)
            )
        }

        return modifiedGrid
    }
}
