import Foundation

enum PathFinder {
    /// Check if a sequence can still be completed from the current game state
    static func canCompleteSequence(
        sequence: TargetSequence,
        currentPosition: Position,
        isHorizontal: Bool,
        usedCells: Set<Position>,
        movesRemaining: Int,
        grid: [[Cell]]
    ) -> Bool {
        // Already complete
        if sequence.isComplete { return true }

        // Not enough moves for remaining codes
        let remainingCodes = sequence.codes.count - sequence.matchedCount
        if movesRemaining < remainingCodes { return false }

        return canComplete(
            codes: Array(sequence.codes.dropFirst(sequence.matchedCount)),
            codeIndex: 0,
            position: currentPosition,
            isHorizontal: isHorizontal,
            usedCells: usedCells,
            movesRemaining: movesRemaining,
            grid: grid,
            memo: NSMutableDictionary()
        )
    }

    private static func canComplete(
        codes: [String],
        codeIndex: Int,
        position: Position,
        isHorizontal: Bool,
        usedCells: Set<Position>,
        movesRemaining: Int,
        grid: [[Cell]],
        memo: NSMutableDictionary
    ) -> Bool {
        // Base case: all codes found
        if codeIndex >= codes.count { return true }

        // Base case: no moves left
        if movesRemaining <= 0 { return false }

        // Pruning: not enough moves for remaining codes
        if movesRemaining < (codes.count - codeIndex) { return false }

        // Get candidates in current constraint
        let candidates = getCandidates(
            position: position,
            isHorizontal: isHorizontal,
            usedCells: usedCells,
            grid: grid
        )

        if candidates.isEmpty { return false }

        let neededCode = codes[codeIndex]

        // Try cells that match the needed code first (more likely to succeed)
        // Include wildcards as matching cells
        let matchingCells = candidates.filter { matchesCode($0, neededCode: neededCode) }
        let nonMatchingCells = candidates.filter { !matchesCode($0, neededCode: neededCode) }

        for cell in matchingCells {
            var newUsed = usedCells
            newUsed.insert(cell.position)

            if canComplete(
                codes: codes,
                codeIndex: codeIndex + 1,
                position: cell.position,
                isHorizontal: !isHorizontal,
                usedCells: newUsed,
                movesRemaining: movesRemaining - 1,
                grid: grid,
                memo: memo
            ) {
                return true
            }
        }

        // Try positioning moves (don't advance sequence but might enable path)
        for cell in nonMatchingCells {
            var newUsed = usedCells
            newUsed.insert(cell.position)

            if canComplete(
                codes: codes,
                codeIndex: codeIndex,
                position: cell.position,
                isHorizontal: !isHorizontal,
                usedCells: newUsed,
                movesRemaining: movesRemaining - 1,
                grid: grid,
                memo: memo
            ) {
                return true
            }
        }

        return false
    }

    /// Get valid candidate cells from current position, excluding blocked cells
    private static func getCandidates(
        position: Position,
        isHorizontal: Bool,
        usedCells: Set<Position>,
        grid: [[Cell]]
    ) -> [Cell] {
        var candidates: [Cell] = []

        if isHorizontal {
            // All cells in the current row
            for col in 0..<grid[position.row].count {
                let cell = grid[position.row][col]
                // Skip used cells and blocked cells
                if !usedCells.contains(cell.position), !cell.isBlocked {
                    candidates.append(cell)
                }
            }
        } else {
            // All cells in the current column
            for row in 0..<grid.count {
                let cell = grid[row][position.col]
                // Skip used cells and blocked cells
                if !usedCells.contains(cell.position), !cell.isBlocked {
                    candidates.append(cell)
                }
            }
        }

        return candidates
    }

    /// Check if a cell matches the needed code (handles wildcards)
    private static func matchesCode(_ cell: Cell, neededCode: String) -> Bool {
        // Wildcards match any code
        if cell.isWildcard {
            return true
        }
        return cell.code == neededCode
    }

    /// Find all positions that would advance any of the given sequences
    static func positionsAdvancingSequences(
        sequences: [TargetSequence],
        currentPosition: Position,
        isHorizontal: Bool,
        usedCells: Set<Position>,
        grid: [[Cell]]
    ) -> Set<Position> {
        var advancingPositions: Set<Position> = []

        // Get next needed codes from all incomplete sequences
        let nextNeededCodes = Set(sequences.compactMap(\.nextNeededCode))

        // Get valid cells in current constraint
        let candidates = getCandidates(
            position: currentPosition,
            isHorizontal: isHorizontal,
            usedCells: usedCells,
            grid: grid
        )

        for cell in candidates {
            // Wildcards always advance sequences (if there are incomplete sequences)
            if cell.isWildcard, !nextNeededCodes.isEmpty {
                advancingPositions.insert(cell.position)
            } else if nextNeededCodes.contains(cell.code) {
                advancingPositions.insert(cell.position)
            }
        }

        return advancingPositions
    }
}
