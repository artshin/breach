import Foundation

enum PuzzleGenerator {
    static func generate(difficulty: Difficulty) -> Puzzle {
        let maxAttempts = 100

        for _ in 0..<maxAttempts {
            if let puzzle = tryGenerate(difficulty: difficulty) {
                return puzzle
            }
        }

        return PuzzleGeneratorCore.generateFallback(
            gridSize: difficulty.gridSize,
            sequenceLength: 3,
            bufferSize: difficulty.bufferSize,
            difficulty: difficulty
        )
    }

    private static func tryGenerate(difficulty: Difficulty) -> Puzzle? {
        let gridSize = difficulty.gridSize
        let poolSize = difficulty.codePoolSize

        // 1. Generate sequences from code pool
        let codePool = Array(Cell.availableCodes.shuffled().prefix(poolSize))
        let sequences = PuzzleGeneratorCore.generateSequences(
            count: difficulty.sequenceCount,
            lengthRange: difficulty.sequenceLengths,
            codePool: codePool
        )

        // 2. Ensure code pool includes all sequence codes
        let fullPool = PuzzleGeneratorCore.selectCodePool(
            size: poolSize,
            sequences: sequences
        )

        // 3. Fill grid randomly from pool
        let grid = PuzzleGeneratorCore.fillGrid(
            gridSize: gridSize,
            codePool: fullPool
        )

        // 4. Solve: find solutions up to maxSolutions cap
        let bufferLimit = estimateBufferLimit(
            difficulty: difficulty, sequences: sequences
        )
        let result = PuzzleSolver.solve(
            grid: grid,
            sequences: sequences,
            bufferSize: bufferLimit,
            maxSolutions: difficulty.maxSolutions + 1
        )

        // 5. Score: check quality criteria
        guard result.isSolvable else { return nil }
        guard result.solutionCount <= difficulty.maxSolutions else { return nil }
        guard result.falseStarts >= difficulty.minFalseStarts else { return nil }

        // 6. Build puzzle from solver result
        let par = result.par
        let bufferSize = par + difficulty.bufferMargin
        return Puzzle(
            grid: grid,
            sequences: sequences.map { TargetSequence(codes: $0) },
            bufferSize: bufferSize,
            par: par,
            difficulty: difficulty,
            solutionPath: result.solutions[0]
        )
    }

    /// Upper bound on buffer for solver search (generous to find solutions)
    private static func estimateBufferLimit(
        difficulty: Difficulty,
        sequences: [[String]]
    ) -> Int {
        let totalCodes = sequences.map(\.count).reduce(0, +)
        return totalCodes + difficulty.bufferMargin + 3
    }
}
