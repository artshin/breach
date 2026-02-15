@testable import Gridcrack
import Testing

@Suite("PuzzleGenerator integration")
struct PuzzleGeneratorIntegrationTests {
    @Test("Easy difficulty produces valid puzzle", .timeLimit(.minutes(1)))
    func easyDifficulty() {
        let puzzle = PuzzleGenerator.generate(difficulty: .easy)
        #expect(PuzzleGeneratorCore.validatePuzzle(puzzle))
        #expect(puzzle.bufferSize >= puzzle.par)
        #expect(puzzle.sequences.count >= 1)
        #expect(puzzle.gridSize == Difficulty.easy.gridSize)
        #expect(puzzle.solutionPath[0].row == 0)
    }

    @Test("Medium difficulty produces valid puzzle", .timeLimit(.minutes(1)))
    func mediumDifficulty() {
        let puzzle = PuzzleGenerator.generate(difficulty: .medium)
        #expect(PuzzleGeneratorCore.validatePuzzle(puzzle))
        #expect(puzzle.bufferSize >= puzzle.par)
        #expect(puzzle.sequences.count >= 1)
        #expect(puzzle.gridSize == Difficulty.medium.gridSize)
        #expect(puzzle.solutionPath[0].row == 0)
    }

    @Test("Hard difficulty produces valid puzzle", .timeLimit(.minutes(1)))
    func hardDifficulty() {
        let puzzle = PuzzleGenerator.generate(difficulty: .hard)
        #expect(PuzzleGeneratorCore.validatePuzzle(puzzle))
        #expect(puzzle.bufferSize >= puzzle.par)
        #expect(puzzle.sequences.count >= 1)
        #expect(puzzle.gridSize == Difficulty.hard.gridSize)
        #expect(puzzle.solutionPath[0].row == 0)
    }

    @Test("Expert difficulty produces valid puzzle", .timeLimit(.minutes(1)))
    func expertDifficulty() {
        let puzzle = PuzzleGenerator.generate(difficulty: .expert)
        #expect(PuzzleGeneratorCore.validatePuzzle(puzzle))
        #expect(puzzle.bufferSize >= puzzle.par)
        #expect(puzzle.sequences.count >= 1)
        #expect(puzzle.gridSize == Difficulty.expert.gridSize)
        #expect(puzzle.solutionPath[0].row == 0)
    }

    @Test(
        "All difficulties produce valid puzzles",
        arguments: Difficulty.allCases
    )
    func allDifficulties(difficulty: Difficulty) {
        for _ in 0..<3 {
            let puzzle = PuzzleGenerator.generate(difficulty: difficulty)
            #expect(PuzzleGeneratorCore.validatePuzzle(puzzle))
            #expect(puzzle.bufferSize >= puzzle.par)
            #expect(puzzle.solutionPath[0].row == 0)
        }
    }
}
