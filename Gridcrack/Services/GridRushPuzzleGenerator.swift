import AppLogService
import Foundation

private let log = Logger.shared

/// Generates puzzles for Grid Rush mode with special cell types
enum GridRushPuzzleGenerator {
    static func generate(stage: GridRushStage) -> Puzzle {
        let maxAttempts = 20

        for attempt in 0..<maxAttempts {
            if let puzzle = tryGenerate(stage: stage) {
                log.info(
                    "Grid Rush puzzle generated",
                    metadata: [
                        "attempts": "\(attempt + 1)",
                        "gridSize": "\(stage.gridSize)"
                    ],
                    tags: ["puzzle", "gridrush"]
                )
                return puzzle
            }
        }

        log.warning(
            "Grid Rush puzzle used fallback",
            metadata: [
                "attempts": "\(maxAttempts)",
                "gridSize": "\(stage.gridSize)"
            ],
            tags: ["puzzle", "gridrush"]
        )
        return PuzzleGeneratorCore.generateFallback(
            gridSize: stage.gridSize,
            sequenceLength: GridRushConfig.sequenceLength,
            bufferSize: GridRushConfig.bufferSize(for: stage),
            difficulty: .medium
        )
    }

    // MARK: - Generation Pipeline

    private static func tryGenerate(stage: GridRushStage) -> Puzzle? {
        let codePool = Array(Cell.availableCodes.shuffled().prefix(stage.codePoolSize))

        // 1. Generate overlapping sequences
        let chain = buildChainForStage(stage: stage, codePool: codePool)
        guard !chain.sequences.isEmpty else { return nil }

        // 2. Place solution path
        guard let (partialGrid, solutionPath) = PuzzleGeneratorCore.placeSolutionPath(
            mergedPath: chain.mergedPath, gridSize: stage.gridSize
        ) else { return nil }

        // 3. Fill grid by stage strategy
        let strategy = fillStrategyForStage(stage, sequences: chain.sequences)
        var grid = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: partialGrid,
            solutionPath: solutionPath,
            strategy: strategy,
            codePool: codePool
        )

        // 4. Layer special cells
        grid = layerSpecialCells(grid: grid, solutionPath: solutionPath, stage: stage)

        // 5. Build puzzle and validate
        let par = chain.mergedPath.count
        let puzzle = Puzzle(
            grid: grid,
            sequences: chain.sequences.map { TargetSequence(codes: $0) },
            bufferSize: min(par + 2, 8),
            par: par,
            difficulty: .medium,
            solutionPath: solutionPath
        )

        guard PuzzleGeneratorCore.validatePuzzle(puzzle, checkBlockers: true) else {
            return nil
        }

        // 6. Easy stages: skip solver
        if stage.maxSolutions >= 100 { return puzzle }

        // 7. Harder stages: solver quality check
        return verifySolverQuality(
            puzzle: puzzle, sequences: chain.sequences, stage: stage
        )
    }

    // MARK: - Stage Helpers

    private static func buildChainForStage(
        stage: GridRushStage,
        codePool: [String]
    ) -> SolutionChain {
        let count = stage.sequenceCount

        if count == 1 {
            let length = Int.random(in: 3...4)
            let config = OverlapConfig(
                overlapCount: 0,
                overlapDepth: 0,
                codePool: codePool,
                sequenceLengths: [length]
            )
            return PuzzleGeneratorCore.generateOverlappingSequences(config: config)
        }

        let overlapCount = count >= 3 ? min(2, count - 1) : 1
        let overlapDepth = count >= 3 ? 2 : 1
        let merged = Int.random(in: 5...6)
        let lengths = PuzzleGeneratorCore.randomLengths(
            mergedLength: merged, count: count, overlapSize: overlapDepth
        )

        let config = OverlapConfig(
            overlapCount: overlapCount,
            overlapDepth: overlapDepth,
            codePool: codePool,
            sequenceLengths: lengths
        )
        return PuzzleGeneratorCore.generateOverlappingSequences(config: config)
    }

    private static func fillStrategyForStage(
        _ stage: GridRushStage,
        sequences: [[String]]
    ) -> FillStrategy {
        if stage.maxSolutions >= 100 {
            return .forgiving(solutionCodeDensity: 0.5)
        } else if stage.maxSolutions >= 8 {
            return .moderate(redHerringDensity: 0.15)
        } else {
            let seqCodes = Set(sequences.flatMap { $0 })
            return .deceptive(decoyDensity: 0.3, sequenceCodes: seqCodes)
        }
    }

    // MARK: - Special Cell Layering

    private static func layerSpecialCells(
        grid: [[Cell]],
        solutionPath: [Position],
        stage: GridRushStage
    ) -> [[Cell]] {
        var result = placeBlockers(
            grid: grid,
            solutionPath: solutionPath,
            count: Int.random(in: stage.blockerCount)
        )
        result = placeWildcards(
            grid: result, solutionPath: solutionPath, chance: stage.wildcardChance
        )
        result = placeDecayCells(
            grid: result, solutionPath: solutionPath, count: stage.decayCellCount
        )
        return result
    }

    // MARK: - Solver Verification

    private static func verifySolverQuality(
        puzzle: Puzzle,
        sequences: [[String]],
        stage: GridRushStage
    ) -> Puzzle? {
        let result = PuzzleSolver.solve(
            grid: puzzle.grid,
            sequences: sequences,
            bufferSize: puzzle.bufferSize,
            maxSolutions: stage.maxSolutions + 1
        )

        guard result.isSolvable else {
            log.debug("Rejected: not solvable", tags: ["puzzle", "gridrush"])
            return nil
        }
        guard result.solutionCount <= stage.maxSolutions else {
            log.debug(
                "Rejected: too many solutions (\(result.solutionCount))",
                tags: ["puzzle", "gridrush"]
            )
            return nil
        }
        guard result.falseStarts >= stage.minFalseStarts else {
            log.debug(
                "Rejected: too few false starts (\(result.falseStarts))",
                tags: ["puzzle", "gridrush"]
            )
            return nil
        }

        return puzzle
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
        var available: [Position] = []

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                if !solutionPositions.contains(pos) {
                    available.append(pos)
                }
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
        solutionPath: [Position],
        chance: Double
    ) -> [[Cell]] {
        guard chance > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                let cell = modifiedGrid[row][col]
                if !cell.isBlocked,
                   !solutionPositions.contains(pos),
                   Double.random(in: 0...1) < chance {
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

    private static func placeDecayCells(
        grid: [[Cell]],
        solutionPath: [Position],
        count: Int
    ) -> [[Cell]] {
        guard count > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)
        var available: [Position] = []

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                let cell = grid[row][col]
                if !solutionPositions.contains(pos),
                   !cell.isBlocked,
                   !cell.isWildcard {
                    available.append(pos)
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
