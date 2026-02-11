import Foundation

/// Shared puzzle generation utilities used by both PuzzleGenerator and GridRushPuzzleGenerator
enum PuzzleGeneratorCore {
    // MARK: - Path Placement

    static func placeSolutionPath(
        mergedPath: [String],
        gridSize: Int
    ) -> (grid: [[Cell]], path: [Position])? {
        var grid: [[Cell?]] = Array(
            repeating: Array(repeating: nil, count: gridSize),
            count: gridSize
        )

        var path: [Position] = []
        var usedPositions: Set<Position> = []

        var isHorizontal = true
        var currentRow = 0
        var currentCol = Int.random(in: 0..<gridSize)

        for code in mergedPath {
            let position: Position

            if path.isEmpty {
                position = Position(row: 0, col: currentCol)
            } else {
                var candidates: [Position] = []

                if isHorizontal {
                    for col in 0..<gridSize {
                        let pos = Position(row: currentRow, col: col)
                        if !usedPositions.contains(pos) {
                            candidates.append(pos)
                        }
                    }
                } else {
                    for row in 0..<gridSize {
                        let pos = Position(row: row, col: currentCol)
                        if !usedPositions.contains(pos) {
                            candidates.append(pos)
                        }
                    }
                }

                guard let chosen = candidates.randomElement() else {
                    return nil
                }
                position = chosen
            }

            let cell = Cell(code: code, row: position.row, col: position.col)
            grid[position.row][position.col] = cell
            path.append(position)
            usedPositions.insert(position)

            currentRow = position.row
            currentCol = position.col
            isHorizontal.toggle()
        }

        let partialGrid = grid.enumerated().map { rowIndex, row in
            row.enumerated().map { colIndex, cell in
                cell ?? Cell(code: "", row: rowIndex, col: colIndex)
            }
        }

        return (partialGrid, path)
    }

    // MARK: - Fill Remaining Cells

    static func fillRemainingCells(
        grid: [[Cell]],
        solutionPath: [Position],
        mergedPath _: [String]
    ) -> [[Cell]] {
        let solutionPositions = Set(solutionPath)
        let codes = Cell.availableCodes

        var filledGrid = grid

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let position = Position(row: row, col: col)

                if !solutionPositions.contains(position) {
                    let code = codes.randomElement()!
                    filledGrid[row][col] = Cell(code: code, row: row, col: col)
                }
            }
        }

        return filledGrid
    }

    // MARK: - Sequence Design

    /// Design sequences of variable lengths sharing overlapping codes in a merged path
    static func designVariableSequences(
        lengths: [Int],
        overlapSize: Int,
        codes: [String]
    ) -> (sequences: [[String]], merged: [String]) {
        guard !lengths.isEmpty else { return ([], []) }

        if lengths.count == 1 {
            let seq = (0..<lengths[0]).map { _ in codes.randomElement()! }
            return ([seq], seq)
        }

        let mergedLength = lengths.reduce(0, +) - overlapSize * (lengths.count - 1)
        let mergedCodes = (0..<mergedLength).map { _ in codes.randomElement()! }

        var sequences: [[String]] = []
        var start = 0
        for length in lengths {
            sequences.append(Array(mergedCodes[start..<(start + length)]))
            start += length - overlapSize
        }

        return (sequences, mergedCodes)
    }

    /// Generate random sequence lengths that sum to the correct total for a given merged path
    static func randomLengths(
        mergedLength: Int,
        count: Int,
        overlapSize: Int,
        maxLength: Int = 4
    ) -> [Int] {
        let total = mergedLength + overlapSize * (count - 1)
        let minLength = 3
        var lengths = Array(repeating: minLength, count: count)
        var remaining = total - count * minLength

        while remaining > 0 {
            let growable = (0..<count).filter { lengths[$0] < maxLength }
            guard let index = growable.randomElement() else { break }
            lengths[index] += 1
            remaining -= 1
        }

        return lengths.shuffled()
    }

    // MARK: - Validation

    static func validatePuzzle(_ puzzle: Puzzle, checkBlockers: Bool = false) -> Bool {
        guard puzzle.solutionPath.count == puzzle.par else { return false }

        var buffer: [String] = []
        var isHorizontal = true
        var lastPosition: Position?

        for (index, position) in puzzle.solutionPath.enumerated() {
            let cell = puzzle.grid[position.row][position.col]

            if checkBlockers, cell.isBlocked { return false }

            if index == 0 {
                guard position.row == 0 else { return false }
            } else if let last = lastPosition {
                if isHorizontal {
                    guard position.row == last.row else { return false }
                } else {
                    guard position.col == last.col else { return false }
                }
            }

            buffer.append(cell.code)
            lastPosition = position
            isHorizontal.toggle()
        }

        for sequence in puzzle.sequences
            where !bufferContainsSequence(buffer: buffer, sequence: sequence.codes) {
            return false
        }

        return true
    }

    static func bufferContainsSequence(buffer: [String], sequence: [String]) -> Bool {
        var seqIndex = 0
        for code in buffer where code == sequence[seqIndex] {
            seqIndex += 1
            if seqIndex >= sequence.count {
                return true
            }
        }
        return false
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

        var grid: [[Cell]] = []
        var path: [Position] = []

        for row in 0..<gridSize {
            var rowCells: [Cell] = []
            for col in 0..<gridSize {
                let code = codes.randomElement()!
                rowCells.append(Cell(code: code, row: row, col: col))
            }
            grid.append(rowCells)
        }

        var isHorizontal = true
        var currentRow = 0
        var currentCol = 0

        for code in sequence {
            let position = Position(row: currentRow, col: currentCol)
            grid[currentRow][currentCol] = Cell(code: code, row: currentRow, col: currentCol)
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
