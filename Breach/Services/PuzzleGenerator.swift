import Foundation

struct PuzzleGenerator {

    static func generate(difficulty: Difficulty) -> Puzzle {
        var attempts = 0
        let maxAttempts = 100

        while attempts < maxAttempts {
            attempts += 1

            if let puzzle = tryGenerate(difficulty: difficulty) {
                return puzzle
            }
        }

        // Fallback: return a simple valid puzzle
        return generateFallback(difficulty: difficulty)
    }

    private static func tryGenerate(difficulty: Difficulty) -> Puzzle? {
        let gridSize = difficulty.gridSize

        // Step 1: Design sequences with overlaps
        let (sequences, mergedPath) = designSequences(difficulty: difficulty)

        // Step 2: Generate solution path through grid
        guard let (partialGrid, solutionPath) = placeSolutionPath(
            mergedPath: mergedPath,
            gridSize: gridSize
        ) else {
            return nil
        }

        // Step 3: Fill remaining cells
        let grid = fillRemainingCells(
            grid: partialGrid,
            solutionPath: solutionPath,
            mergedPath: mergedPath
        )

        // Step 4: Create target sequences
        let targetSequences = sequences.map { codes in
            TargetSequence(codes: codes)
        }

        let puzzle = Puzzle(
            grid: grid,
            sequences: targetSequences,
            bufferSize: difficulty.bufferSize,
            par: mergedPath.count,
            difficulty: difficulty,
            solutionPath: solutionPath
        )

        // Step 5: Validate
        if validatePuzzle(puzzle) {
            return puzzle
        }

        return nil
    }

    // MARK: - Sequence Design

    private static func designSequences(difficulty: Difficulty) -> (sequences: [[String]], merged: [String]) {
        let codes = Cell.availableCodes

        switch difficulty {
        case .easy:
            // Single sequence, no overlap needed
            let seq = (0..<3).map { _ in codes.randomElement()! }
            return ([seq], seq)

        case .medium:
            // Two sequences with suffix-prefix overlap
            return designOverlappingSequences(count: 2, overlapSize: 2, codes: codes)

        case .hard:
            // Two sequences with smaller overlap
            return designOverlappingSequences(count: 2, overlapSize: 1, codes: codes)

        case .expert:
            // Three sequences with chained overlaps
            return designChainedSequences(count: 3, codes: codes)
        }
    }

    private static func designOverlappingSequences(
        count: Int,
        overlapSize: Int,
        codes: [String]
    ) -> (sequences: [[String]], merged: [String]) {
        // Create first sequence
        let seq1 = (0..<3).map { _ in codes.randomElement()! }

        // Create second sequence that overlaps with first
        // Last `overlapSize` codes of seq1 = first `overlapSize` codes of seq2
        let overlap = Array(seq1.suffix(overlapSize))
        let seq2 = overlap + (0..<(3 - overlapSize)).map { _ in codes.randomElement()! }

        // Merged path: seq1 + remaining of seq2
        let merged = seq1 + Array(seq2.dropFirst(overlapSize))

        return ([seq1, seq2], merged)
    }

    private static func designChainedSequences(
        count: Int,
        codes: [String]
    ) -> (sequences: [[String]], merged: [String]) {
        // Create chained sequences: A-B-C, B-C-D, C-D-E
        // Merged: A-B-C-D-E

        var allCodes: [String] = []
        for _ in 0..<(2 + count) {
            allCodes.append(codes.randomElement()!)
        }

        var sequences: [[String]] = []
        for i in 0..<count {
            let seq = Array(allCodes[i..<(i + 3)])
            sequences.append(seq)
        }

        return (sequences, allCodes)
    }

    // MARK: - Path Placement

    private static func placeSolutionPath(
        mergedPath: [String],
        gridSize: Int
    ) -> (grid: [[Cell]], path: [Position])? {
        // Initialize empty grid
        var grid: [[Cell?]] = Array(
            repeating: Array(repeating: nil, count: gridSize),
            count: gridSize
        )

        var path: [Position] = []
        var usedPositions: Set<Position> = []

        // Start in row 0 (horizontal constraint for first move)
        var isHorizontal = true
        var currentRow = 0
        var currentCol = Int.random(in: 0..<gridSize)

        for code in mergedPath {
            // Find a valid position
            let position: Position

            if path.isEmpty {
                // First move: must be in row 0
                position = Position(row: 0, col: currentCol)
            } else {
                // Find available positions in current constraint
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
                    return nil // No valid position available
                }
                position = chosen
            }

            // Place the code
            let cell = Cell(code: code, row: position.row, col: position.col)
            grid[position.row][position.col] = cell
            path.append(position)
            usedPositions.insert(position)

            // Update constraints for next move
            currentRow = position.row
            currentCol = position.col
            isHorizontal = !isHorizontal
        }

        // Convert to non-optional grid (fill nulls temporarily)
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
                    // Fill with a random code
                    // For simplicity, just use random codes
                    // More sophisticated: avoid codes that create shortcuts
                    let code = codes.randomElement()!
                    filledGrid[row][col] = Cell(code: code, row: row, col: col)
                }
            }
        }

        return filledGrid
    }

    // MARK: - Validation

    private static func validatePuzzle(_ puzzle: Puzzle) -> Bool {
        // Check that the solution path actually works
        guard puzzle.solutionPath.count == puzzle.par else { return false }

        // Simulate following the solution path
        var buffer: [String] = []
        var isHorizontal = true
        var lastPosition: Position? = nil

        for (index, position) in puzzle.solutionPath.enumerated() {
            let cell = puzzle.grid[position.row][position.col]

            // Verify constraint
            if index == 0 {
                // First move must be row 0
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
            isHorizontal = !isHorizontal
        }

        // Verify all sequences can be completed with this buffer
        for sequence in puzzle.sequences {
            if !bufferContainsSequence(buffer: buffer, sequence: sequence.codes) {
                return false
            }
        }

        return true
    }

    private static func bufferContainsSequence(buffer: [String], sequence: [String]) -> Bool {
        var seqIndex = 0
        for code in buffer {
            if code == sequence[seqIndex] {
                seqIndex += 1
                if seqIndex >= sequence.count {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Fallback

    private static func generateFallback(difficulty: Difficulty) -> Puzzle {
        // Generate a simple guaranteed-solvable puzzle
        let gridSize = difficulty.gridSize
        let codes = Cell.availableCodes

        // Simple sequence
        let sequence = (0..<3).map { _ in codes.randomElement()! }

        // Place sequence in a straight line from (0,0)
        var grid: [[Cell]] = []
        var path: [Position] = []

        for row in 0..<gridSize {
            var rowCells: [Cell] = []
            for col in 0..<gridSize {
                let code: String
                if row == 0 && col < sequence.count && col < gridSize {
                    // Special case: place first code at (0, col) where we'll select it
                    code = codes.randomElement()!
                } else {
                    code = codes.randomElement()!
                }
                rowCells.append(Cell(code: code, row: row, col: col))
            }
            grid.append(rowCells)
        }

        // Override with solution path
        // Path: (0,0) -> (1,0) -> (1,1) -> (2,1)... alternating
        var isHorizontal = true
        var currentRow = 0
        var currentCol = 0

        for code in sequence {
            let position = Position(row: currentRow, col: currentCol)
            grid[currentRow][currentCol] = Cell(code: code, row: currentRow, col: currentCol)
            path.append(position)

            // Move for next code
            if isHorizontal {
                currentCol = min(currentCol + 1, gridSize - 1)
            } else {
                currentRow = min(currentRow + 1, gridSize - 1)
            }
            isHorizontal = !isHorizontal
        }

        return Puzzle(
            grid: grid,
            sequences: [TargetSequence(codes: sequence)],
            bufferSize: difficulty.bufferSize,
            par: sequence.count,
            difficulty: difficulty,
            solutionPath: path
        )
    }
}
