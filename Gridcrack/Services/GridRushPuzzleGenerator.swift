import Foundation

/// Generates puzzles for Grid Rush mode with special cell types
enum GridRushPuzzleGenerator {
    static func generate(stage: GridRushStage) -> Puzzle {
        let maxAttempts = 100

        for _ in 0..<maxAttempts {
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
        // 1. Generate sequences from code pool
        let codePool = Array(Cell.availableCodes.shuffled().prefix(stage.codePoolSize))
        let sequences = PuzzleGeneratorCore.generateSequences(
            count: stage.sequenceCount,
            lengthRange: 3...3,
            codePool: codePool
        )

        let fullPool = PuzzleGeneratorCore.selectCodePool(
            size: stage.codePoolSize,
            sequences: sequences
        )

        // 2. Fill grid randomly from pool
        var grid = PuzzleGeneratorCore.fillGrid(
            gridSize: stage.gridSize,
            codePool: fullPool
        )

        // 3. Place special cells (blockers, wildcards, decay)
        grid = placeBlockers(grid: grid, count: Int.random(in: stage.blockerCount))
        grid = placeWildcards(grid: grid, chance: stage.wildcardChance)
        grid = placeDecayCells(grid: grid, count: stage.decayCellCount)

        // 4. Solve with special cells in place
        let bufferSize = GridRushConfig.bufferSize(for: stage)
        let result = PuzzleSolver.solve(
            grid: grid,
            sequences: sequences,
            bufferSize: bufferSize,
            maxSolutions: stage.maxSolutions + 1
        )

        // 5. Score quality
        guard result.isSolvable else { return nil }
        guard result.solutionCount <= stage.maxSolutions else { return nil }
        guard result.falseStarts >= stage.minFalseStarts else { return nil }

        // 6. Build puzzle
        return Puzzle(
            grid: grid,
            sequences: sequences.map { TargetSequence(codes: $0) },
            bufferSize: bufferSize,
            par: result.par,
            difficulty: .medium,
            solutionPath: result.solutions[0]
        )
    }

    // MARK: - Special Cell Placement

    private static func placeBlockers(grid: [[Cell]], count: Int) -> [[Cell]] {
        guard count > 0 else { return grid }

        var modifiedGrid = grid
        var available: [Position] = []

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                available.append(Position(row: row, col: col))
            }
        }

        available.shuffle()
        for pos in available.prefix(count) {
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
        chance: Double
    ) -> [[Cell]] {
        guard chance > 0 else { return grid }

        var modifiedGrid = grid

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let cell = modifiedGrid[row][col]
                if !cell.isBlocked, Double.random(in: 0...1) < chance {
                    modifiedGrid[row][col] = Cell(
                        code: cell.code,
                        row: row,
                        col: col,
                        cellType: .wildcard
                    )
                }
            }
        }

        return modifiedGrid
    }

    private static func placeDecayCells(grid: [[Cell]], count: Int) -> [[Cell]] {
        guard count > 0 else { return grid }

        var modifiedGrid = grid
        var available: [Position] = []

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let cell = grid[row][col]
                if !cell.isBlocked, !cell.isWildcard {
                    available.append(Position(row: row, col: col))
                }
            }
        }

        available.shuffle()
        for pos in available.prefix(count) {
            let code = modifiedGrid[pos.row][pos.col].code
            let movesUntilDecay = Int.random(in: 3...5)
            modifiedGrid[pos.row][pos.col] = Cell(
                code: code,
                row: pos.row,
                col: pos.col,
                cellType: .decay(movesRemaining: movesUntilDecay)
            )
        }

        return modifiedGrid
    }
}
