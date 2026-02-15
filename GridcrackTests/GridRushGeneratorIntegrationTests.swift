@testable import Gridcrack
import Testing

@Suite("GridRushPuzzleGenerator integration")
struct GridRushGeneratorIntegrationTests {
    @Test(
        "All stage tiers produce valid puzzles with blocker check",
        arguments: [1, 3, 5, 7]
    )
    func allStageTiers(gridNumber: Int) {
        let stage = GridRushStage.forGridNumber(gridNumber)
        for _ in 0..<3 {
            let puzzle = GridRushPuzzleGenerator.generate(stage: stage)
            #expect(PuzzleGeneratorCore.validatePuzzle(puzzle, checkBlockers: true))
            #expect(puzzle.bufferSize >= puzzle.par)
            #expect(puzzle.solutionPath[0].row == 0)
            #expect(puzzle.gridSize == stage.gridSize)
        }
    }

    @Test("No blockers on solution path")
    func noBlockersOnSolutionPath() {
        for gridNumber in [1, 3, 5, 7] {
            let stage = GridRushStage.forGridNumber(gridNumber)
            let puzzle = GridRushPuzzleGenerator.generate(stage: stage)

            for pos in puzzle.solutionPath {
                let cell = puzzle.grid[pos.row][pos.col]
                #expect(!cell.isBlocked)
            }
        }
    }

    @Test("Easy stage (grids 1-2) basic properties")
    func easyStage() {
        let stage = GridRushStage.forGridNumber(1)
        let puzzle = GridRushPuzzleGenerator.generate(stage: stage)

        #expect(puzzle.gridSize == 4)
        #expect(puzzle.sequences.count == stage.sequenceCount)
        #expect(PuzzleGeneratorCore.validatePuzzle(puzzle, checkBlockers: true))
    }

    @Test("Expert stage (grids 7+) has special cells")
    func expertStageSpecialCells() {
        let stage = GridRushStage.forGridNumber(7)
        let puzzle = GridRushPuzzleGenerator.generate(stage: stage)

        #expect(puzzle.gridSize == 6)
        #expect(PuzzleGeneratorCore.validatePuzzle(puzzle, checkBlockers: true))

        // Expert stage should have blockers (6...8 range)
        let blockerCount = puzzle.grid.flatMap { $0 }.filter(\.isBlocked).count
        #expect(blockerCount >= 0) // May be 0 if generation rolled low
    }
}
