import Foundation

/// Result of solving a puzzle grid
struct SolveResult {
    let solutions: [[Position]]
    let falseStarts: Int

    var isSolvable: Bool {
        !solutions.isEmpty
    }

    var par: Int {
        solutions.first?.count ?? 0
    }

    var solutionCount: Int {
        solutions.count
    }
}

/// Multi-sequence recursive backtracking solver
///
/// Evaluates a filled grid by finding all valid solution paths (up to a cap).
/// Tracks progress on ALL sequences simultaneously, matching GameEngine semantics.
/// Used during generation to score puzzle quality — not during gameplay.
enum PuzzleSolver {
    /// Solve a grid: find up to `maxSolutions` paths completing all sequences
    static func solve(
        grid: [[Cell]],
        sequences: [[String]],
        bufferSize: Int,
        maxSolutions: Int = 10
    ) -> SolveResult {
        let gridSize = grid.count
        guard gridSize > 0, !sequences.isEmpty else {
            return SolveResult(solutions: [], falseStarts: 0)
        }

        var allSolutions: [[Position]] = []
        var falseStarts = 0

        // Try every cell in row 0 as a starting position
        for col in 0..<gridSize {
            let cell = grid[0][col]
            if cell.isBlocked { continue }

            let startProgress = advanceAll(
                sequences: sequences,
                progress: Array(repeating: 0, count: sequences.count),
                code: cell.code,
                isWildcard: cell.isWildcard
            )

            var context = SearchContext(
                grid: grid,
                sequences: sequences,
                seqProgress: startProgress,
                path: [Position(row: 0, col: col)],
                usedCells: [Position(row: 0, col: col)],
                currentPos: Position(row: 0, col: col),
                isHorizontal: false,
                movesRemaining: bufferSize - 1,
                maxSolutions: maxSolutions
            )

            let beforeCount = allSolutions.count

            if isAllComplete(sequences: sequences, progress: startProgress) {
                allSolutions.append(context.path)
            } else {
                search(context: &context, solutions: &allSolutions)
            }

            if allSolutions.count == beforeCount {
                falseStarts += 1
            }
            if allSolutions.count >= maxSolutions { break }
        }

        // Sort by length (shortest = best par)
        let sorted = allSolutions.sorted { $0.count < $1.count }
        return SolveResult(solutions: sorted, falseStarts: falseStarts)
    }

    // MARK: - Recursive Search

    private struct SearchContext {
        let grid: [[Cell]]
        let sequences: [[String]]
        var seqProgress: [Int]
        var path: [Position]
        var usedCells: Set<Position>
        var currentPos: Position
        var isHorizontal: Bool
        var movesRemaining: Int
        let maxSolutions: Int
    }

    private static func search(
        context: inout SearchContext,
        solutions: inout [[Position]]
    ) {
        guard context.movesRemaining > 0 else { return }
        guard solutions.count < context.maxSolutions else { return }

        if !canStillComplete(context: context) { return }

        let candidates = getCandidates(context: context)
        if candidates.isEmpty { return }

        let saved = (
            context.seqProgress,
            context.path,
            context.currentPos,
            context.isHorizontal,
            context.movesRemaining
        )

        for cell in candidates {
            let newProgress = advanceAll(
                sequences: context.sequences,
                progress: saved.0,
                code: cell.code,
                isWildcard: cell.isWildcard
            )

            let pos = cell.position
            context.seqProgress = newProgress
            context.path.append(pos)
            context.usedCells.insert(pos)
            context.currentPos = pos
            context.isHorizontal = !saved.3
            context.movesRemaining = saved.4 - 1

            if isAllComplete(sequences: context.sequences, progress: newProgress) {
                solutions.append(context.path)
            } else {
                search(context: &context, solutions: &solutions)
            }

            // Backtrack
            context.path.removeLast()
            context.usedCells.remove(pos)
            context.seqProgress = saved.0
            context.currentPos = saved.2
            context.isHorizontal = saved.3
            context.movesRemaining = saved.4

            if solutions.count >= context.maxSolutions { return }
        }
    }

    // MARK: - Pruning

    private static func canStillComplete(context: SearchContext) -> Bool {
        // One move can advance multiple sequences sharing a needed code,
        // so the safe lower bound is the longest remaining sequence.
        let maxRemaining = zip(context.sequences, context.seqProgress)
            .map { $0.0.count - $0.1 }
            .max() ?? 0
        return context.movesRemaining >= maxRemaining
    }

    // MARK: - Candidates

    private static func getCandidates(context: SearchContext) -> [Cell] {
        let grid = context.grid
        var candidates: [Cell] = []

        if context.isHorizontal {
            for col in 0..<grid[context.currentPos.row].count {
                let cell = grid[context.currentPos.row][col]
                if !context.usedCells.contains(cell.position), !cell.isBlocked {
                    candidates.append(cell)
                }
            }
        } else {
            for row in 0..<grid.count {
                let cell = grid[row][context.currentPos.col]
                if !context.usedCells.contains(cell.position), !cell.isBlocked {
                    candidates.append(cell)
                }
            }
        }

        // Order: advancing cells first (find solutions faster)
        let neededCodes = neededCodesSet(
            sequences: context.sequences, progress: context.seqProgress
        )
        return candidates.sorted { cellA, cellB in
            let aAdvances = cellAdvances(cellA, neededCodes: neededCodes)
            let bAdvances = cellAdvances(cellB, neededCodes: neededCodes)
            if aAdvances != bAdvances { return aAdvances }
            return false
        }
    }

    // MARK: - Sequence Progress

    private static func advanceAll(
        sequences: [[String]],
        progress: [Int],
        code: String,
        isWildcard: Bool
    ) -> [Int] {
        var newProgress = progress
        for i in 0..<sequences.count {
            guard newProgress[i] < sequences[i].count else { continue }
            if isWildcard || sequences[i][newProgress[i]] == code {
                newProgress[i] += 1
            }
        }
        return newProgress
    }

    private static func isAllComplete(
        sequences: [[String]],
        progress: [Int]
    ) -> Bool {
        for i in 0..<sequences.count where progress[i] < sequences[i].count {
            return false
        }
        return true
    }

    private static func neededCodesSet(
        sequences: [[String]],
        progress: [Int]
    ) -> Set<String> {
        var codes = Set<String>()
        for i in 0..<sequences.count where progress[i] < sequences[i].count {
            codes.insert(sequences[i][progress[i]])
        }
        return codes
    }

    private static func cellAdvances(
        _ cell: Cell,
        neededCodes: Set<String>
    ) -> Bool {
        cell.isWildcard || neededCodes.contains(cell.code)
    }
}
