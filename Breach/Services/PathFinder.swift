import Foundation

enum PathFinder {
    /// Context for recursive path search
    private struct SearchContext {
        let codes: [String]
        let grid: [[Cell]]
        var position: Position
        var isHorizontal: Bool
        var usedCells: Set<Position>
        var movesRemaining: Int
    }

    /// Check if a sequence can still be completed from the current game state
    static func canCompleteSequence(
        sequence: TargetSequence,
        currentPosition: Position,
        isHorizontal: Bool,
        usedCells: Set<Position>,
        movesRemaining: Int,
        grid: [[Cell]]
    ) -> Bool {
        if sequence.isComplete { return true }

        let remainingCodes = sequence.codes.count - sequence.matchedCount
        if movesRemaining < remainingCodes { return false }

        var context = SearchContext(
            codes: Array(sequence.codes.dropFirst(sequence.matchedCount)),
            grid: grid,
            position: currentPosition,
            isHorizontal: isHorizontal,
            usedCells: usedCells,
            movesRemaining: movesRemaining
        )

        return canComplete(context: &context, codeIndex: 0)
    }

    private static func canComplete(context: inout SearchContext, codeIndex: Int) -> Bool {
        if codeIndex >= context.codes.count { return true }
        if context.movesRemaining <= 0 { return false }
        if context.movesRemaining < (context.codes.count - codeIndex) { return false }

        let candidates = getCandidates(
            position: context.position,
            isHorizontal: context.isHorizontal,
            usedCells: context.usedCells,
            grid: context.grid
        )

        if candidates.isEmpty { return false }

        let neededCode = context.codes[codeIndex]
        let matchingCells = candidates.filter { matchesCode($0, neededCode: neededCode) }
        let nonMatchingCells = candidates.filter { !matchesCode($0, neededCode: neededCode) }

        // Save state for backtracking
        let savedPosition = context.position
        let savedIsHorizontal = context.isHorizontal
        let savedMovesRemaining = context.movesRemaining

        for cell in matchingCells {
            context.usedCells.insert(cell.position)
            context.position = cell.position
            context.isHorizontal = !savedIsHorizontal
            context.movesRemaining = savedMovesRemaining - 1

            if canComplete(context: &context, codeIndex: codeIndex + 1) {
                return true
            }

            context.usedCells.remove(cell.position)
        }

        for cell in nonMatchingCells {
            context.usedCells.insert(cell.position)
            context.position = cell.position
            context.isHorizontal = !savedIsHorizontal
            context.movesRemaining = savedMovesRemaining - 1

            if canComplete(context: &context, codeIndex: codeIndex) {
                return true
            }

            context.usedCells.remove(cell.position)
        }

        // Restore state
        context.position = savedPosition
        context.isHorizontal = savedIsHorizontal
        context.movesRemaining = savedMovesRemaining

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
            for col in 0..<grid[position.row].count {
                let cell = grid[position.row][col]
                if !usedCells.contains(cell.position), !cell.isBlocked {
                    candidates.append(cell)
                }
            }
        } else {
            for row in 0..<grid.count {
                let cell = grid[row][position.col]
                if !usedCells.contains(cell.position), !cell.isBlocked {
                    candidates.append(cell)
                }
            }
        }

        return candidates
    }

    /// Check if a cell matches the needed code (handles wildcards)
    private static func matchesCode(_ cell: Cell, neededCode: String) -> Bool {
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

        let nextNeededCodes = Set(sequences.compactMap(\.nextNeededCode))

        let candidates = getCandidates(
            position: currentPosition,
            isHorizontal: isHorizontal,
            usedCells: usedCells,
            grid: grid
        )

        for cell in candidates {
            if cell.isWildcard, !nextNeededCodes.isEmpty {
                advancingPositions.insert(cell.position)
            } else if nextNeededCodes.contains(cell.code) {
                advancingPositions.insert(cell.position)
            }
        }

        return advancingPositions
    }
}
