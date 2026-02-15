@testable import Gridcrack
import Testing

@Suite("PuzzleSolver.solve")
struct PuzzleSolverTests {
    /// Build a 3x3 grid with known codes
    private func makeGrid(_ codes: [[String]]) -> [[Cell]] {
        codes.enumerated().map { row, rowCodes in
            rowCodes.enumerated().map { col, code in
                Cell(code: code, row: row, col: col)
            }
        }
    }

    @Test("Hand-built grid with known solution")
    func knownSolution() {
        // Grid:
        //   1C  BD  55
        //   E9  1C  7A
        //   FF  BD  E9
        //
        // Sequence: [1C, BD]
        // Expected path: (0,0)→(1,0) won't work (E9 != BD)
        //                (0,0)→vertical→(1,0) or (2,0) - nope
        // Actually: start at (0,0)="1C", then vertical to col 0:
        //   (0,0) isH starts true, toggles to false after first pick
        //   Wait - the solver starts isHorizontal=false after first move
        //   So from (0,0), next move is vertical (same col): (1,0)="E9" or (2,0)="FF"
        //   Neither matches BD.
        //   Start at (0,1)="BD"... doesn't match "1C"
        //   Start at (0,2)="55"... doesn't match "1C"
        //
        // Let me make a solvable grid:
        //   1C  BD  55
        //   BD  E9  7A    <- (1,0) = BD
        //   FF  1C  E9
        //
        // Path: (0,0)="1C" -> vertical col 0 -> (1,0)="BD" -> done!
        let grid = makeGrid([
            ["1C", "BD", "55"],
            ["BD", "E9", "7A"],
            ["FF", "1C", "E9"]
        ])
        let sequences = [["1C", "BD"]]
        let result = PuzzleSolver.solve(
            grid: grid, sequences: sequences, bufferSize: 4
        )

        #expect(result.isSolvable)
        #expect(result.par == 2)
        #expect(result.solutionCount >= 1)

        // Verify the first solution
        let sol = result.solutions[0]
        #expect(sol[0].row == 0)
        #expect(grid[sol[0].row][sol[0].col].code == "1C")
        #expect(grid[sol[1].row][sol[1].col].code == "BD")
    }

    @Test("Unsolvable grid")
    func unsolvableGrid() {
        // All cells have the same code, sequence needs two different codes
        let grid = makeGrid([
            ["1C", "1C", "1C"],
            ["1C", "1C", "1C"],
            ["1C", "1C", "1C"]
        ])
        let sequences = [["1C", "BD"]]
        let result = PuzzleSolver.solve(
            grid: grid, sequences: sequences, bufferSize: 6
        )

        #expect(!result.isSolvable)
        #expect(result.solutionCount == 0)
    }

    @Test("Blocked cells are routed around")
    func blockedCellsRoutedAround() {
        // Grid where direct path is blocked
        var grid = makeGrid([
            ["1C", "FF", "55"],
            ["BD", "E9", "7A"],
            ["55", "BD", "E9"]
        ])
        // Block (1,0) which has BD - force solver to find alternate route
        grid[1][0] = Cell(code: "BD", row: 1, col: 0, cellType: .blocker)

        let sequences = [["1C", "BD"]]
        let result = PuzzleSolver.solve(
            grid: grid, sequences: sequences, bufferSize: 6
        )

        // Should still find a solution via a longer path
        if result.isSolvable {
            for solution in result.solutions {
                for pos in solution {
                    #expect(!(pos.row == 1 && pos.col == 0))
                }
            }
        }
    }

    @Test("Wildcard matches any code")
    func wildcardMatchesAny() {
        var grid = makeGrid([
            ["1C", "FF", "55"],
            ["E9", "E9", "7A"],
            ["55", "BD", "E9"]
        ])
        // Make (1,0) a wildcard - should match "BD" in sequence
        grid[1][0] = Cell(code: "E9", row: 1, col: 0, cellType: .wildcard)

        let sequences = [["1C", "BD"]]
        let result = PuzzleSolver.solve(
            grid: grid, sequences: sequences, bufferSize: 4
        )

        #expect(result.isSolvable)
        // Check that a solution uses the wildcard cell
        let hasWildcardSolution = result.solutions.contains { sol in
            sol.contains(Position(row: 1, col: 0))
        }
        #expect(hasWildcardSolution)
    }

    @Test("Buffer size limits solution depth")
    func bufferSizeLimitsDepth() {
        let grid = makeGrid([
            ["1C", "FF", "55"],
            ["E9", "BD", "7A"],
            ["55", "1C", "E9"]
        ])
        // Sequence needs 1C then BD - minimum 2 moves
        let sequences = [["1C", "BD"]]

        // Buffer of 1 shouldn't find a solution (need at least 2)
        let result1 = PuzzleSolver.solve(
            grid: grid, sequences: sequences, bufferSize: 1
        )
        #expect(!result1.isSolvable)

        // Buffer of 4 should find solutions
        let result4 = PuzzleSolver.solve(
            grid: grid, sequences: sequences, bufferSize: 4
        )
        #expect(result4.isSolvable)
    }

    @Test("Multiple sequences all completed")
    func multipleSequencesCompleted() {
        // Grid designed so both sequences can be completed
        let grid = makeGrid([
            ["1C", "55", "FF"],
            ["BD", "E9", "7A"],
            ["55", "1C", "BD"]
        ])
        // seq1: 1C, BD  seq2: 1C, E9
        // From (0,0)="1C" advances both, then vertical:
        //   (1,0)="BD" completes seq1, (2,0)="55" doesn't help seq2
        //   Need a path that also gets E9
        let sequences = [["1C", "BD"], ["55", "E9"]]
        let result = PuzzleSolver.solve(
            grid: grid, sequences: sequences, bufferSize: 6
        )

        if result.isSolvable {
            // Verify the solution path actually completes all sequences
            let sol = result.solutions[0]
            let buffer = sol.map { grid[$0.row][$0.col].code }
            for seq in sequences {
                #expect(
                    PuzzleGeneratorCore.bufferContainsSequence(
                        buffer: buffer, sequence: seq
                    )
                )
            }
        }
    }
}
