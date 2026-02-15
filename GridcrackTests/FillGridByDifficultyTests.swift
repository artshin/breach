@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.fillGridByDifficulty")
struct FillGridByDifficultyTests {
    private let codePool = Cell.availableCodes

    private func makePartialGrid() -> (grid: [[Cell]], path: [Position]) {
        var grid: [[Cell]] = (0..<3).map { row in
            (0..<3).map { col in
                Cell(code: "", row: row, col: col)
            }
        }
        grid[0][0] = Cell(code: "1C", row: 0, col: 0)
        grid[1][0] = Cell(code: "BD", row: 1, col: 0)
        let path = [Position(row: 0, col: 0), Position(row: 1, col: 0)]
        return (grid, path)
    }

    // MARK: - Forgiving Strategy

    @Test("Forgiving: solution positions are preserved")
    func forgivingSolutionPreserved() {
        let (grid, path) = makePartialGrid()
        let filled = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: grid, solutionPath: path,
            strategy: .forgiving(solutionCodeDensity: 0.5),
            codePool: codePool
        )
        #expect(filled[0][0].code == "1C")
        #expect(filled[1][0].code == "BD")
    }

    @Test("Forgiving: no empty codes after fill")
    func forgivingNoEmpty() {
        let (grid, path) = makePartialGrid()
        let filled = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: grid, solutionPath: path,
            strategy: .forgiving(solutionCodeDensity: 0.5),
            codePool: codePool
        )
        for row in filled {
            for cell in row {
                #expect(!cell.code.isEmpty)
            }
        }
    }

    @Test("Forgiving: high density fills with solution codes")
    func forgivingHighDensity() {
        let (grid, path) = makePartialGrid()
        let solutionCodeSet: Set<String> = ["1C", "BD"]
        var solutionCodeCount = 0
        var total = 0

        for _ in 0..<50 {
            let filled = PuzzleGeneratorCore.fillGridByDifficulty(
                grid: grid, solutionPath: path,
                strategy: .forgiving(solutionCodeDensity: 1.0),
                codePool: codePool
            )
            for row in 0..<3 {
                for col in 0..<3 {
                    let pos = Position(row: row, col: col)
                    if !Set(path).contains(pos) {
                        total += 1
                        if solutionCodeSet.contains(filled[row][col].code) {
                            solutionCodeCount += 1
                        }
                    }
                }
            }
        }

        // With density 1.0, all filler should be solution codes
        #expect(solutionCodeCount == total)
    }

    // MARK: - Moderate Strategy

    @Test("Moderate: density 0 produces no red herrings")
    func moderateZeroDensity() {
        let (grid, path) = makePartialGrid()
        let filled = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: grid, solutionPath: path,
            strategy: .moderate(redHerringDensity: 0.0),
            codePool: ["FF"]
        )
        for row in 0..<3 {
            for col in 0..<3 {
                let pos = Position(row: row, col: col)
                if !Set(path).contains(pos) {
                    #expect(filled[row][col].code == "FF")
                }
            }
        }
    }

    // MARK: - Deceptive Strategy

    @Test("Deceptive: non-adjacent cells use non-sequence codes")
    func deceptiveNonAdjacentSafe() {
        // 5x5 grid with path at (0,2) and (1,2)
        var grid: [[Cell]] = (0..<5).map { row in
            (0..<5).map { col in
                Cell(code: "", row: row, col: col)
            }
        }
        grid[0][2] = Cell(code: "1C", row: 0, col: 2)
        grid[1][2] = Cell(code: "BD", row: 1, col: 2)
        let path = [Position(row: 0, col: 2), Position(row: 1, col: 2)]

        let sequenceCodes: Set<String> = ["1C", "BD"]
        let filled = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: grid, solutionPath: path,
            strategy: .deceptive(decoyDensity: 0.0, sequenceCodes: sequenceCodes),
            codePool: codePool
        )

        // With decoy density 0, no cells get sequence codes (except solution)
        let nonSeqCodes = Set(codePool).subtracting(sequenceCodes)
        for row in 0..<5 {
            for col in 0..<5 {
                let pos = Position(row: row, col: col)
                if !Set(path).contains(pos) {
                    #expect(nonSeqCodes.contains(filled[row][col].code))
                }
            }
        }
    }

    // MARK: - Grid Dimensions

    @Test("Grid dimensions preserved")
    func gridDimensionsPreserved() {
        let (grid, path) = makePartialGrid()
        let strategies: [FillStrategy] = [
            .forgiving(solutionCodeDensity: 0.5),
            .moderate(redHerringDensity: 0.15),
            .deceptive(decoyDensity: 0.3, sequenceCodes: ["1C"])
        ]

        for strategy in strategies {
            let filled = PuzzleGeneratorCore.fillGridByDifficulty(
                grid: grid, solutionPath: path,
                strategy: strategy, codePool: codePool
            )
            #expect(filled.count == 3)
            for row in filled {
                #expect(row.count == 3)
            }
        }
    }
}
