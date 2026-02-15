@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.adjustSolutionCount")
struct AdjustSolutionCountTests {
    @Test("Grid already in range returns same grid")
    func alreadyInRange() {
        // Create a simple valid puzzle scenario
        let codePool = ["1C", "BD", "55", "E9"]
        let sequence = ["1C", "BD"]

        guard let (partialGrid, solutionPath) = PuzzleGeneratorCore.placeSolutionPath(
            mergedPath: sequence, gridSize: 4
        ) else {
            Issue.record("Path placement failed")
            return
        }

        let grid = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: partialGrid, solutionPath: solutionPath,
            strategy: .moderate(redHerringDensity: 0.0),
            codePool: codePool
        )

        // Wide target range should always succeed
        let result = PuzzleGeneratorCore.adjustSolutionCount(
            grid: grid, solutionPath: solutionPath,
            sequences: [sequence], bufferSize: 6,
            targetRange: 1...1000, codePool: codePool
        )
        #expect(result != nil)
    }

    @Test("Solution path is preserved after adjustment")
    func solutionPathPreserved() {
        let codePool = ["1C", "BD", "55", "E9"]
        let sequence = ["1C", "BD"]

        guard let (partialGrid, solutionPath) = PuzzleGeneratorCore.placeSolutionPath(
            mergedPath: sequence, gridSize: 4
        ) else {
            Issue.record("Path placement failed")
            return
        }

        let grid = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: partialGrid, solutionPath: solutionPath,
            strategy: .forgiving(solutionCodeDensity: 0.5),
            codePool: codePool
        )

        if let adjusted = PuzzleGeneratorCore.adjustSolutionCount(
            grid: grid, solutionPath: solutionPath,
            sequences: [sequence], bufferSize: 6,
            targetRange: 1...1000, codePool: codePool
        ) {
            // Solution path codes must be unchanged
            for pos in solutionPath {
                #expect(
                    adjusted[pos.row][pos.col].code == grid[pos.row][pos.col].code
                )
            }
        }
    }

    @Test("Returns nil for impossible target range")
    func impossibleRange() {
        let codePool = ["1C", "BD", "55", "E9"]
        let sequence = ["1C", "BD"]

        guard let (partialGrid, solutionPath) = PuzzleGeneratorCore.placeSolutionPath(
            mergedPath: sequence, gridSize: 4
        ) else {
            Issue.record("Path placement failed")
            return
        }

        // Fill with only non-sequence codes to make it hard to find many solutions
        let grid = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: partialGrid, solutionPath: solutionPath,
            strategy: .deceptive(
                decoyDensity: 0.0,
                sequenceCodes: Set(sequence)
            ),
            codePool: codePool
        )

        // Target range requiring 500+ solutions is practically impossible on a 4x4 grid
        let result = PuzzleGeneratorCore.adjustSolutionCount(
            grid: grid, solutionPath: solutionPath,
            sequences: [sequence], bufferSize: 4,
            targetRange: 500...1000, codePool: codePool
        )
        #expect(result == nil)
    }
}
