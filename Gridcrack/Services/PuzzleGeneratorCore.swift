import Foundation

/// Shared puzzle generation utilities used by both PuzzleGenerator and GridRushPuzzleGenerator
enum PuzzleGeneratorCore {
    // MARK: - Grid Fill

    /// Fill an entire grid randomly from the code pool
    static func fillGrid(gridSize: Int, codePool: [String]) -> [[Cell]] {
        (0..<gridSize).map { row in
            (0..<gridSize).map { col in
                Cell(code: codePool.randomElement()!, row: row, col: col)
            }
        }
    }

    // MARK: - Sequence Generation

    /// Generate independent random sequences from a code pool
    static func generateSequences(
        count: Int,
        lengthRange: ClosedRange<Int>,
        codePool: [String]
    ) -> [[String]] {
        (0..<count).map { _ in
            let length = Int.random(in: lengthRange)
            return (0..<length).map { _ in codePool.randomElement()! }
        }
    }

    // MARK: - Code Pool

    /// Select a reduced code pool ensuring all sequence codes are included
    static func selectCodePool(
        size: Int,
        sequences: [[String]]
    ) -> [String] {
        let allCodes = Cell.availableCodes
        let sequenceCodes = Set(sequences.flatMap { $0 })
        var pool = Array(sequenceCodes)

        let remaining = allCodes.filter { !sequenceCodes.contains($0) }.shuffled()
        for code in remaining where pool.count < size {
            pool.append(code)
        }

        return pool
    }

    // MARK: - Fallback

    static func generateFallback(
        gridSize: Int,
        sequenceLength: Int,
        bufferSize: Int,
        difficulty: Difficulty
    ) -> Puzzle {
        let codes = Cell.availableCodes
        let sequence = (0..<sequenceLength).map { _ in codes.randomElement()! }

        var grid = fillGrid(gridSize: gridSize, codePool: codes)
        var path: [Position] = []

        var isHorizontal = true
        var currentRow = 0
        var currentCol = 0

        for code in sequence {
            let position = Position(row: currentRow, col: currentCol)
            grid[currentRow][currentCol] = Cell(
                code: code,
                row: currentRow,
                col: currentCol
            )
            path.append(position)

            if isHorizontal {
                currentCol = min(currentCol + 1, gridSize - 1)
            } else {
                currentRow = min(currentRow + 1, gridSize - 1)
            }
            isHorizontal.toggle()
        }

        return Puzzle(
            grid: grid,
            sequences: [TargetSequence(codes: sequence)],
            bufferSize: bufferSize,
            par: sequence.count,
            difficulty: difficulty,
            solutionPath: path
        )
    }
}
