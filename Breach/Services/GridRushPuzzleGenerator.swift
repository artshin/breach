import Foundation

/// Generates puzzles specifically for Grid Rush mode with special cell types
enum GridRushPuzzleGenerator {
    /// Generate a puzzle for a specific Grid Rush stage
    static func generate(stage: GridRushStage) -> Puzzle {
        var attempts = 0
        let maxAttempts = 100

        while attempts < maxAttempts {
            attempts += 1

            if let puzzle = tryGenerate(stage: stage) {
                return puzzle
            }
        }

        // Fallback: return a simple valid puzzle
        return generateFallback(stage: stage)
    }

    private static func tryGenerate(stage: GridRushStage) -> Puzzle? {
        let gridSize = stage.gridSize

        // Step 1: Design sequences with overlaps
        let (sequences, mergedPath) = designSequences(stage: stage)

        // Step 2: Generate solution path through grid
        guard let (partialGrid, solutionPath) = placeSolutionPath(
            mergedPath: mergedPath,
            gridSize: gridSize
        ) else {
            return nil
        }

        // Step 3: Fill remaining cells
        var grid = fillRemainingCells(
            grid: partialGrid,
            solutionPath: solutionPath,
            mergedPath: mergedPath
        )

        // Step 4: Place blockers (avoiding solution path)
        grid = placeBlockers(
            grid: grid,
            solutionPath: solutionPath,
            count: Int.random(in: stage.blockerCount)
        )

        // Step 5: Place wildcard cells (based on chance)
        grid = placeWildcards(
            grid: grid,
            solutionPath: solutionPath,
            chance: stage.wildcardChance
        )

        // Step 6: Place decay cells
        grid = placeDecayCells(
            grid: grid,
            solutionPath: solutionPath,
            count: stage.decayCellCount
        )

        // Step 7: Create target sequences
        let targetSequences = sequences.map { codes in
            TargetSequence(codes: codes)
        }

        let bufferSize = GridRushConfig.bufferSize(for: stage)

        let puzzle = Puzzle(
            grid: grid,
            sequences: targetSequences,
            bufferSize: bufferSize,
            par: mergedPath.count,
            difficulty: .medium, // Grid Rush uses its own difficulty system
            solutionPath: solutionPath
        )

        // Step 8: Validate
        if validatePuzzle(puzzle) {
            return puzzle
        }

        return nil
    }

    // MARK: - Sequence Design

    private static func designSequences(stage: GridRushStage) -> (sequences: [[String]], merged: [String]) {
        let codes = Cell.availableCodes
        let count = stage.sequenceCount

        if count == 1 {
            let seq = (0..<GridRushConfig.sequenceLength).map { _ in codes.randomElement()! }
            return ([seq], seq)
        } else if count == 2 {
            return designOverlappingSequences(count: 2, overlapSize: 1, codes: codes)
        } else {
            return designChainedSequences(count: count, codes: codes)
        }
    }

    private static func designOverlappingSequences(
        count: Int,
        overlapSize: Int,
        codes: [String]
    ) -> (sequences: [[String]], merged: [String]) {
        let seq1 = (0..<GridRushConfig.sequenceLength).map { _ in codes.randomElement()! }
        let overlap = Array(seq1.suffix(overlapSize))
        let seq2 = overlap + (0..<(GridRushConfig.sequenceLength - overlapSize)).map { _ in codes.randomElement()! }
        let merged = seq1 + Array(seq2.dropFirst(overlapSize))

        return ([seq1, seq2], merged)
    }

    private static func designChainedSequences(
        count: Int,
        codes: [String]
    ) -> (sequences: [[String]], merged: [String]) {
        var allCodes: [String] = []
        for _ in 0..<(2 + count) {
            allCodes.append(codes.randomElement()!)
        }

        var sequences: [[String]] = []
        for i in 0..<count {
            let seq = Array(allCodes[i..<(i + GridRushConfig.sequenceLength)])
            sequences.append(seq)
        }

        return (sequences, allCodes)
    }

    // MARK: - Path Placement

    private static func placeSolutionPath(
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

    private static func fillRemainingCells(
        grid: [[Cell]],
        solutionPath: [Position],
        mergedPath: [String]
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

    // MARK: - Special Cell Placement

    private static func placeBlockers(
        grid: [[Cell]],
        solutionPath: [Position],
        count: Int
    ) -> [[Cell]] {
        guard count > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)
        var availablePositions: [Position] = []

        // Collect positions not on solution path
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                if !solutionPositions.contains(pos) {
                    availablePositions.append(pos)
                }
            }
        }

        // Shuffle and take up to count positions
        availablePositions.shuffle()
        let blockerPositions = Array(availablePositions.prefix(count))

        for pos in blockerPositions {
            modifiedGrid[pos.row][pos.col] = Cell(
                code: "XX",
                row: pos.row,
                col: pos.col,
                cellType: .blocker
            )
        }

        return modifiedGrid
    }

    private static func placeWildcards(
        grid: [[Cell]],
        solutionPath: [Position],
        chance: Double
    ) -> [[Cell]] {
        guard chance > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                // Can place wildcards even on solution path (they help!)
                // But skip blockers
                if !modifiedGrid[row][col].isBlocked {
                    if Double.random(in: 0...1) < chance, !solutionPositions.contains(pos) {
                        let originalCode = modifiedGrid[row][col].code
                        modifiedGrid[row][col] = Cell(
                            code: originalCode,
                            row: row,
                            col: col,
                            cellType: .wildcard
                        )
                    }
                }
            }
        }

        return modifiedGrid
    }

    private static func placeDecayCells(
        grid: [[Cell]],
        solutionPath: [Position],
        count: Int
    ) -> [[Cell]] {
        guard count > 0 else { return grid }

        var modifiedGrid = grid
        let solutionPositions = Set(solutionPath)
        var availablePositions: [Position] = []

        // Collect positions not on solution path and not already special
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                let cell = grid[row][col]
                if !solutionPositions.contains(pos), !cell.isBlocked, !cell.isWildcard {
                    availablePositions.append(pos)
                }
            }
        }

        availablePositions.shuffle()
        let decayPositions = Array(availablePositions.prefix(count))

        for pos in decayPositions {
            let originalCode = modifiedGrid[pos.row][pos.col].code
            // Decay cells change after 3-5 moves
            let movesUntilDecay = Int.random(in: 3...5)
            modifiedGrid[pos.row][pos.col] = Cell(
                code: originalCode,
                row: pos.row,
                col: pos.col,
                cellType: .decay(movesRemaining: movesUntilDecay)
            )
        }

        return modifiedGrid
    }

    // MARK: - Validation

    private static func validatePuzzle(_ puzzle: Puzzle) -> Bool {
        guard puzzle.solutionPath.count == puzzle.par else { return false }

        var buffer: [String] = []
        var isHorizontal = true
        var lastPosition: Position?

        for (index, position) in puzzle.solutionPath.enumerated() {
            let cell = puzzle.grid[position.row][position.col]

            // Verify cell is not blocked
            if cell.isBlocked { return false }

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

    private static func bufferContainsSequence(buffer: [String], sequence: [String]) -> Bool {
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

    private static func generateFallback(stage: GridRushStage) -> Puzzle {
        let gridSize = stage.gridSize
        let codes = Cell.availableCodes

        let sequence = (0..<GridRushConfig.sequenceLength).map { _ in codes.randomElement()! }

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

        let bufferSize = GridRushConfig.bufferSize(for: stage)

        return Puzzle(
            grid: grid,
            sequences: [TargetSequence(codes: sequence)],
            bufferSize: bufferSize,
            par: sequence.count,
            difficulty: .medium,
            solutionPath: path
        )
    }
}
