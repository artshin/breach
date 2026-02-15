@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.validatePuzzle")
struct ValidatePuzzleTests {
    /// Build a minimal valid puzzle for testing
    private func makeValidPuzzle() -> Puzzle {
        // 3x3 grid, path: (0,0) -> (1,0) -> (1,1)
        // Start row 0, first move horizontal (same row), toggles to vertical, etc.
        // Actually: path starts at row 0, isHorizontal starts true then toggles
        // Step 0: (0,0) - row 0 OK, isHorizontal toggles to false
        // Step 1: must be same col as (0,0) -> col 0, different row -> (1,0)
        //         isHorizontal toggles to true
        // Step 2: must be same row as (1,0) -> row 1, different col -> (1,1)
        let grid: [[Cell]] = [
            [Cell(code: "1C", row: 0, col: 0), Cell(code: "FF", row: 0, col: 1), Cell(code: "55", row: 0, col: 2)],
            [Cell(code: "BD", row: 1, col: 0), Cell(code: "E9", row: 1, col: 1), Cell(code: "7A", row: 1, col: 2)],
            [Cell(code: "55", row: 2, col: 0), Cell(code: "1C", row: 2, col: 1), Cell(code: "BD", row: 2, col: 2)]
        ]
        let path = [Position(row: 0, col: 0), Position(row: 1, col: 0), Position(row: 1, col: 1)]
        let sequence = TargetSequence(codes: ["1C", "BD", "E9"])

        return Puzzle(
            grid: grid,
            sequences: [sequence],
            bufferSize: 5,
            par: 3,
            difficulty: .easy,
            solutionPath: path
        )
    }

    @Test("Valid puzzle passes validation")
    func validPuzzle() {
        let puzzle = makeValidPuzzle()
        #expect(PuzzleGeneratorCore.validatePuzzle(puzzle))
    }

    @Test("Wrong par fails validation")
    func wrongPar() {
        let puzzle = makeValidPuzzle()
        let bad = Puzzle(
            grid: puzzle.grid,
            sequences: puzzle.sequences,
            bufferSize: puzzle.bufferSize,
            par: 999,
            difficulty: puzzle.difficulty,
            solutionPath: puzzle.solutionPath
        )
        #expect(!PuzzleGeneratorCore.validatePuzzle(bad))
    }

    @Test("Path not starting in row 0 fails")
    func pathNotStartingRow0() {
        let puzzle = makeValidPuzzle()
        let badPath = [Position(row: 1, col: 0), Position(row: 1, col: 1)]
        let bad = Puzzle(
            grid: puzzle.grid,
            sequences: [TargetSequence(codes: ["BD", "E9"])],
            bufferSize: puzzle.bufferSize,
            par: 2,
            difficulty: puzzle.difficulty,
            solutionPath: badPath
        )
        #expect(!PuzzleGeneratorCore.validatePuzzle(bad))
    }

    @Test("Row/col alternation violated fails")
    func alternationViolated() {
        let puzzle = makeValidPuzzle()
        // Two consecutive moves in the same row (both horizontal)
        let badPath = [
            Position(row: 0, col: 0),
            Position(row: 0, col: 1),
            Position(row: 0, col: 2)
        ]
        let bad = Puzzle(
            grid: puzzle.grid,
            sequences: [TargetSequence(codes: ["1C", "FF", "55"])],
            bufferSize: puzzle.bufferSize,
            par: 3,
            difficulty: puzzle.difficulty,
            solutionPath: badPath
        )
        #expect(!PuzzleGeneratorCore.validatePuzzle(bad))
    }

    @Test("Buffer not containing sequence fails")
    func bufferMissingSequence() {
        let puzzle = makeValidPuzzle()
        let bad = Puzzle(
            grid: puzzle.grid,
            sequences: [TargetSequence(codes: ["7A", "7A", "7A"])],
            bufferSize: puzzle.bufferSize,
            par: 3,
            difficulty: puzzle.difficulty,
            solutionPath: puzzle.solutionPath
        )
        #expect(!PuzzleGeneratorCore.validatePuzzle(bad))
    }

    @Test("Blocker on path fails with checkBlockers")
    func blockerOnPath() {
        var puzzle = makeValidPuzzle()
        var grid = puzzle.grid
        // Place blocker at solution path position (1,0)
        grid[1][0] = Cell(code: "BD", row: 1, col: 0, cellType: .blocker)
        let bad = Puzzle(
            grid: grid,
            sequences: puzzle.sequences,
            bufferSize: puzzle.bufferSize,
            par: puzzle.par,
            difficulty: puzzle.difficulty,
            solutionPath: puzzle.solutionPath
        )
        #expect(!PuzzleGeneratorCore.validatePuzzle(bad, checkBlockers: true))
        // Without checkBlockers, blocker is ignored
        #expect(PuzzleGeneratorCore.validatePuzzle(bad, checkBlockers: false))
    }
}
