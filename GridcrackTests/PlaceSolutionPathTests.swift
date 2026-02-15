@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.placeSolutionPath")
struct PlaceSolutionPathTests {
    @Test("Path starts in row 0")
    func pathStartsRow0() {
        for _ in 0..<20 {
            let codes = (0..<4).map { _ in Cell.availableCodes.randomElement()! }
            guard let (_, path) = PuzzleGeneratorCore.placeSolutionPath(
                mergedPath: codes, gridSize: 5
            ) else {
                continue
            }
            #expect(path[0].row == 0)
        }
    }

    @Test("Path alternates row/col movement")
    func pathAlternatesRowCol() {
        for _ in 0..<20 {
            let codes = (0..<5).map { _ in Cell.availableCodes.randomElement()! }
            guard let (_, path) = PuzzleGeneratorCore.placeSolutionPath(
                mergedPath: codes, gridSize: 5
            ) else {
                continue
            }

            // After step 0, isHorizontal toggles to false → first transition is vertical
            var isHorizontal = false
            for i in 1..<path.count {
                if isHorizontal {
                    // Horizontal move: same row, different col
                    #expect(path[i].row == path[i - 1].row)
                } else {
                    // Vertical move: same col, different row
                    #expect(path[i].col == path[i - 1].col)
                }
                isHorizontal.toggle()
            }
        }
    }

    @Test("All positions are unique")
    func allPositionsUnique() {
        for _ in 0..<20 {
            let codes = (0..<5).map { _ in Cell.availableCodes.randomElement()! }
            guard let (_, path) = PuzzleGeneratorCore.placeSolutionPath(
                mergedPath: codes, gridSize: 5
            ) else {
                continue
            }
            let unique = Set(path)
            #expect(unique.count == path.count)
        }
    }

    @Test("Grid cells match codes at path positions")
    func gridCellsMatchCodes() {
        for _ in 0..<20 {
            let codes = ["1C", "BD", "55", "E9"]
            guard let (grid, path) = PuzzleGeneratorCore.placeSolutionPath(
                mergedPath: codes, gridSize: 5
            ) else {
                continue
            }
            for (i, pos) in path.enumerated() {
                #expect(grid[pos.row][pos.col].code == codes[i])
            }
        }
    }

    @Test("Returns nil for too-long path in small grid")
    func tooLongPathReturnsNil() {
        // 2x2 grid can hold at most 2-3 positions before running out
        // A path of 10 should exceed available positions
        let codes = (0..<10).map { _ in "1C" }
        var nilCount = 0
        for _ in 0..<50 {
            if PuzzleGeneratorCore.placeSolutionPath(mergedPath: codes, gridSize: 2) == nil {
                nilCount += 1
            }
        }
        // Should fail most/all of the time
        #expect(nilCount > 40)
    }

    @Test("Path length matches input codes length")
    func pathLengthMatchesInput() {
        for length in 3...6 {
            let codes = (0..<length).map { _ in Cell.availableCodes.randomElement()! }
            guard let (_, path) = PuzzleGeneratorCore.placeSolutionPath(
                mergedPath: codes, gridSize: 6
            ) else {
                continue
            }
            #expect(path.count == length)
        }
    }
}
