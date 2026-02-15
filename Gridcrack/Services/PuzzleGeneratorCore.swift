import AppLogService
import Foundation

private let log = Logger.shared

// MARK: - Types

struct OverlapConfig {
    let overlapCount: Int
    let overlapDepth: Int
    let codePool: [String]
    let sequenceLengths: [Int]
}

struct SolutionChain {
    let sequences: [[String]]
    let mergedPath: [String]
}

enum FillStrategy {
    case forgiving(solutionCodeDensity: Double)
    case moderate(redHerringDensity: Double)
    case deceptive(decoyDensity: Double, sequenceCodes: Set<String>)
}

/// Shared puzzle generation utilities used by both PuzzleGenerator and GridRushPuzzleGenerator
enum PuzzleGeneratorCore {
    // MARK: - Path Placement

    /// Place a solution path through a grid, starting in row 0 and alternating row/col moves
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
                let candidates = findCandidates(
                    isHorizontal: isHorizontal,
                    currentRow: currentRow,
                    currentCol: currentCol,
                    gridSize: gridSize,
                    usedPositions: usedPositions
                )

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

    // MARK: - Overlapping Sequence Generation

    /// Generate sequences that share overlapping codes at junction points
    static func generateOverlappingSequences(
        config: OverlapConfig
    ) -> SolutionChain {
        let lengths = config.sequenceLengths
        let pool = config.codePool
        guard !lengths.isEmpty else {
            return SolutionChain(sequences: [], mergedPath: [])
        }

        if lengths.count == 1 {
            let seq = (0..<lengths[0]).map { _ in pool.randomElement()! }
            return SolutionChain(sequences: [seq], mergedPath: seq)
        }

        return buildMultiSequenceChain(config: config)
    }

    // MARK: - Difficulty-Based Grid Fill

    /// Fill non-solution cells according to the difficulty strategy
    static func fillGridByDifficulty(
        grid: [[Cell]],
        solutionPath: [Position],
        strategy: FillStrategy,
        codePool: [String]
    ) -> [[Cell]] {
        switch strategy {
        case let .forgiving(density), let .moderate(density):
            fillForgiving(
                grid: grid,
                solutionPath: solutionPath,
                codePool: codePool,
                solutionCodeDensity: density
            )
        case let .deceptive(density, sequenceCodes):
            fillDeceptive(
                grid: grid,
                solutionPath: solutionPath,
                codePool: codePool,
                decoyDensity: density,
                sequenceCodes: sequenceCodes
            )
        }
    }

    // MARK: - Solution Count Adjustment

    /// Adjust grid fill to bring solution count within target range
    static func adjustSolutionCount(
        grid: [[Cell]],
        solutionPath: [Position],
        sequences: [[String]],
        bufferSize: Int,
        targetRange: ClosedRange<Int>,
        codePool: [String]
    ) -> [[Cell]]? {
        let solutionPositions = Set(solutionPath)
        let sequenceCodes = Set(sequences.flatMap { $0 })
        let nonSeqCodes = codePool.filter { !sequenceCodes.contains($0) }
        var adjusted = grid

        for _ in 0..<3 {
            let result = PuzzleSolver.solve(
                grid: adjusted,
                sequences: sequences,
                bufferSize: bufferSize,
                maxSolutions: targetRange.upperBound + 1
            )

            if targetRange.contains(result.solutionCount) {
                return adjusted
            }

            if result.solutionCount < targetRange.lowerBound {
                adjusted = addSolutionCodes(
                    grid: adjusted,
                    solutionPositions: solutionPositions,
                    sequenceCodes: Array(sequenceCodes)
                )
            } else {
                adjusted = removeSolutionCodes(
                    grid: adjusted,
                    solutionPositions: solutionPositions,
                    sequenceCodes: sequenceCodes,
                    nonSeqCodes: nonSeqCodes
                )
            }
        }

        // Final check
        let finalResult = PuzzleSolver.solve(
            grid: adjusted,
            sequences: sequences,
            bufferSize: bufferSize,
            maxSolutions: targetRange.upperBound + 1
        )
        return targetRange.contains(finalResult.solutionCount) ? adjusted : nil
    }

    // MARK: - Random Lengths

    /// Generate random sequence lengths that sum to the correct total
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

    static func validatePuzzle(
        _ puzzle: Puzzle,
        checkBlockers: Bool = false
    ) -> Bool {
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

    static func bufferContainsSequence(
        buffer: [String],
        sequence: [String]
    ) -> Bool {
        var seqIndex = 0
        for code in buffer where code == sequence[seqIndex] {
            seqIndex += 1
            if seqIndex >= sequence.count {
                return true
            }
        }
        return false
    }

    /// Verify a merged path completes all sequences when used as a buffer
    static func verifyPathCompletes(
        path: [String],
        sequences: [[String]]
    ) -> Bool {
        var progress = Array(repeating: 0, count: sequences.count)
        for code in path {
            for i in 0..<sequences.count {
                if progress[i] < sequences[i].count,
                   sequences[i][progress[i]] == code {
                    progress[i] += 1
                }
            }
        }
        return progress.enumerated().allSatisfy { $0.element >= sequences[$0.offset].count }
    }

    // MARK: - Fallback

    static func generateFallback(
        gridSize: Int,
        sequenceLength: Int,
        bufferSize: Int,
        difficulty: Difficulty
    ) -> Puzzle {
        log.warning(
            "Generating fallback puzzle",
            metadata: [
                "gridSize": "\(gridSize)",
                "seqLen": "\(sequenceLength)",
                "buffer": "\(bufferSize)"
            ],
            tags: ["puzzle"]
        )
        let codes = Cell.availableCodes
        let sequence = (0..<sequenceLength).map { _ in codes.randomElement()! }

        var grid = fallbackGrid(gridSize: gridSize, codePool: codes)
        var path: [Position] = []

        var isHorizontal = true
        var currentRow = 0
        var currentCol = 0

        for code in sequence {
            let position = Position(row: currentRow, col: currentCol)
            grid[currentRow][currentCol] = Cell(
                code: code,
                row: currentRow,
                col: currentCol
            )
            path.append(position)

            if isHorizontal {
                currentRow = min(currentRow + 1, gridSize - 1)
            } else {
                currentCol = min(currentCol + 1, gridSize - 1)
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

// MARK: - Private Helpers

extension PuzzleGeneratorCore {
    private static func findCandidates(
        isHorizontal: Bool,
        currentRow: Int,
        currentCol: Int,
        gridSize: Int,
        usedPositions: Set<Position>
    ) -> [Position] {
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

        return candidates
    }

    /// Fill an entire grid randomly (used only by fallback)
    private static func fallbackGrid(gridSize: Int, codePool: [String]) -> [[Cell]] {
        (0..<gridSize).map { row in
            (0..<gridSize).map { col in
                Cell(code: codePool.randomElement()!, row: row, col: col)
            }
        }
    }

    // MARK: - Multi-Sequence Chain Builder

    private static func buildMultiSequenceChain(
        config: OverlapConfig
    ) -> SolutionChain {
        let lengths = config.sequenceLengths
        let pool = config.codePool
        let overlapCount = min(config.overlapCount, lengths.count - 1)
        let overlapDepth = config.overlapDepth

        // Decide which junctions have overlaps
        let junctionCount = lengths.count - 1
        let overlapJunctions = Set(
            (0..<junctionCount).shuffled().prefix(overlapCount)
        )

        var sequences: [[String]] = []
        var mergedPath: [String] = []

        for (i, length) in lengths.enumerated() {
            if i == 0 {
                let seq = (0..<length).map { _ in pool.randomElement()! }
                sequences.append(seq)
                mergedPath.append(contentsOf: seq)
            } else {
                let seq = buildNextSequence(
                    prevSequence: sequences[i - 1],
                    length: length,
                    pool: pool,
                    hasOverlap: overlapJunctions.contains(i - 1),
                    overlapDepth: overlapDepth
                )
                sequences.append(seq)
                let newCodes = overlapJunctions.contains(i - 1)
                    ? Array(seq.dropFirst(overlapDepth))
                    : seq
                mergedPath.append(contentsOf: newCodes)
            }
        }

        return SolutionChain(sequences: sequences, mergedPath: mergedPath)
    }

    private static func buildNextSequence(
        prevSequence: [String],
        length: Int,
        pool: [String],
        hasOverlap: Bool,
        overlapDepth: Int
    ) -> [String] {
        if hasOverlap {
            let depth = min(overlapDepth, prevSequence.count)
            let prefix = Array(prevSequence.suffix(depth))
            let remaining = (0..<(length - depth)).map { _ in pool.randomElement()! }
            return prefix + remaining
        } else {
            return (0..<length).map { _ in pool.randomElement()! }
        }
    }

    // MARK: - Fill Strategy Implementations

    /// Easy/Medium: fill with density-based chance of solution codes vs pool codes
    private static func fillForgiving(
        grid: [[Cell]],
        solutionPath: [Position],
        codePool: [String],
        solutionCodeDensity density: Double
    ) -> [[Cell]] {
        let solutionPositions = Set(solutionPath)
        let solutionCodes = Array(Set(solutionPath.map { grid[$0.row][$0.col].code }))
        var filled = grid

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                guard !solutionPositions.contains(Position(row: row, col: col)) else { continue }
                let code = Double.random(in: 0...1) < density && !solutionCodes.isEmpty
                    ? solutionCodes.randomElement()!
                    : codePool.randomElement()!
                filled[row][col] = Cell(code: code, row: row, col: col)
            }
        }

        return filled
    }

    /// Hard/Expert: adjacent cells get tempting codes, rest get non-sequence codes
    private static func fillDeceptive(
        grid: [[Cell]],
        solutionPath: [Position],
        codePool: [String],
        decoyDensity: Double,
        sequenceCodes: Set<String>
    ) -> [[Cell]] {
        let solutionPositions = Set(solutionPath)
        let seqArray = Array(sequenceCodes)
        let nonSeqCodes = codePool.filter { !sequenceCodes.contains($0) }
        let safeFiller = nonSeqCodes.isEmpty ? codePool : nonSeqCodes
        let adjacentPositions = buildAdjacentSet(
            solutionPath: solutionPath, gridSize: grid.count
        )
        var filled = grid

        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                let pos = Position(row: row, col: col)
                guard !solutionPositions.contains(pos) else { continue }

                let code: String = if adjacentPositions.contains(pos),
                                      Double.random(in: 0...1) < decoyDensity,
                                      !seqArray.isEmpty {
                    seqArray.randomElement()!
                } else {
                    safeFiller.randomElement()!
                }
                filled[row][col] = Cell(code: code, row: row, col: col)
            }
        }

        return filled
    }

    private static func buildAdjacentSet(
        solutionPath: [Position],
        gridSize: Int
    ) -> Set<Position> {
        let solutionSet = Set(solutionPath)
        var adjacent = Set<Position>()

        for pos in solutionPath {
            let neighbors = [
                Position(row: pos.row - 1, col: pos.col),
                Position(row: pos.row + 1, col: pos.col),
                Position(row: pos.row, col: pos.col - 1),
                Position(row: pos.row, col: pos.col + 1)
            ]
            for neighbor in neighbors {
                if neighbor.row >= 0, neighbor.row < gridSize,
                   neighbor.col >= 0, neighbor.col < gridSize,
                   !solutionSet.contains(neighbor) {
                    adjacent.insert(neighbor)
                }
            }
        }

        return adjacent
    }

    // MARK: - Solution Count Adjustment Helpers

    /// Swap some non-solution cells to sequence codes (increases solutions)
    private static func addSolutionCodes(
        grid: [[Cell]],
        solutionPositions: Set<Position>,
        sequenceCodes: [String]
    ) -> [[Cell]] {
        guard !sequenceCodes.isEmpty else { return grid }
        var adjusted = grid
        let candidates = nonSolutionPositions(grid: grid, excluding: solutionPositions)
        for pos in candidates.shuffled().prefix(max(1, grid.count)) {
            adjusted[pos.row][pos.col] = Cell(
                code: sequenceCodes.randomElement()!, row: pos.row, col: pos.col
            )
        }
        return adjusted
    }

    /// Swap some sequence-code filler cells to non-sequence codes (reduces solutions)
    private static func removeSolutionCodes(
        grid: [[Cell]],
        solutionPositions: Set<Position>,
        sequenceCodes: Set<String>,
        nonSeqCodes: [String]
    ) -> [[Cell]] {
        guard !nonSeqCodes.isEmpty else { return grid }
        var adjusted = grid
        let candidates = nonSolutionPositions(grid: grid, excluding: solutionPositions)
            .filter { sequenceCodes.contains(grid[$0.row][$0.col].code) }
        for pos in candidates.shuffled().prefix(max(1, grid.count)) {
            adjusted[pos.row][pos.col] = Cell(
                code: nonSeqCodes.randomElement()!, row: pos.row, col: pos.col
            )
        }
        return adjusted
    }

    private static func nonSolutionPositions(
        grid: [[Cell]],
        excluding solutionPositions: Set<Position>
    ) -> [Position] {
        (0..<grid.count).flatMap { row in
            (0..<grid[row].count).compactMap { col in
                let pos = Position(row: row, col: col)
                return solutionPositions.contains(pos) ? nil : pos
            }
        }
    }
}
