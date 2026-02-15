@testable import Gridcrack
import Testing

@Suite("Solution-first generation integration")
struct SolutionFirstIntegrationTests {
    @Test(
        "All difficulties produce valid solvable puzzles",
        arguments: Difficulty.allCases
    )
    func allDifficultiesValid(difficulty: Difficulty) {
        for _ in 0..<5 {
            let puzzle = PuzzleGenerator.generate(difficulty: difficulty)
            #expect(PuzzleGeneratorCore.validatePuzzle(puzzle))
            #expect(puzzle.bufferSize >= puzzle.par)
            #expect(puzzle.solutionPath[0].row == 0)
            #expect(puzzle.gridSize == difficulty.gridSize)

            // Verify solver can find at least one solution
            let sequences = puzzle.sequences.map(\.codes)
            let result = PuzzleSolver.solve(
                grid: puzzle.grid,
                sequences: sequences,
                bufferSize: puzzle.bufferSize,
                maxSolutions: 1
            )
            #expect(result.isSolvable)
        }
    }

    @Test("Merged path fits within buffer size")
    func mergedPathFitsBuffer() {
        for difficulty in Difficulty.allCases {
            let puzzle = PuzzleGenerator.generate(difficulty: difficulty)
            #expect(puzzle.par <= puzzle.bufferSize)
        }
    }

    @Test("Grid Rush stages produce valid puzzles", arguments: [1, 3, 5, 7])
    func gridRushValid(gridNumber: Int) {
        let stage = GridRushStage.forGridNumber(gridNumber)
        for _ in 0..<3 {
            let puzzle = GridRushPuzzleGenerator.generate(stage: stage)
            #expect(PuzzleGeneratorCore.validatePuzzle(puzzle, checkBlockers: true))
            #expect(puzzle.bufferSize >= puzzle.par)
            #expect(puzzle.solutionPath[0].row == 0)

            let sequences = puzzle.sequences.map(\.codes)
            let result = PuzzleSolver.solve(
                grid: puzzle.grid,
                sequences: sequences,
                bufferSize: puzzle.bufferSize,
                maxSolutions: 1
            )
            #expect(result.isSolvable)
        }
    }

    @Test("Overlapping sequences produce valid chains")
    func overlappingSequenceChains() {
        let pool = Cell.availableCodes
        let configs: [OverlapConfig] = [
            OverlapConfig(
                overlapCount: 0, overlapDepth: 0,
                codePool: pool, sequenceLengths: [3]
            ),
            OverlapConfig(
                overlapCount: 1, overlapDepth: 1,
                codePool: pool, sequenceLengths: [3, 3]
            ),
            OverlapConfig(
                overlapCount: 2, overlapDepth: 2,
                codePool: pool, sequenceLengths: [3, 3, 3]
            )
        ]

        for config in configs {
            for _ in 0..<10 {
                let chain = PuzzleGeneratorCore.generateOverlappingSequences(
                    config: config
                )
                #expect(chain.sequences.count == config.sequenceLengths.count)
                #expect(
                    PuzzleGeneratorCore.verifyPathCompletes(
                        path: chain.mergedPath, sequences: chain.sequences
                    )
                )
            }
        }
    }
}
