import AppLogService
import Foundation

private let log = Logger.shared

enum PuzzleGenerator {
    /// Snapshot of randomized difficulty parameters, fixed for one generation attempt
    private struct DifficultyParams {
        let gridSize: Int
        let sequenceCount: Int
        let sequenceLengths: [Int]
        let codePoolSize: Int
        let bufferMargin: Int
        let usesSolverQualityGate: Bool
        let maxSolutions: Int
        let minFalseStarts: Int
        let overlapCount: Int
        let overlapDepth: Int
        let targetSolutionRange: ClosedRange<Int>

        init(difficulty: Difficulty) {
            gridSize = difficulty.gridSize
            sequenceCount = difficulty.sequenceCount
            codePoolSize = difficulty.codePoolSize
            bufferMargin = difficulty.bufferMargin
            usesSolverQualityGate = difficulty.usesSolverQualityGate

            // 1. Pick overlap params first (needed to compute maxTotal)
            let minLen: Int
            switch difficulty {
            case .easy:
                minLen = 2
                overlapCount = sequenceCount > 1 ? 1 : 0
                overlapDepth = 1
                targetSolutionRange = 2...100
                maxSolutions = 100
                minFalseStarts = 0
            case .medium:
                minLen = 2
                overlapCount = Int.random(in: 0...1)
                overlapDepth = 1
                targetSolutionRange = 1...50
                maxSolutions = 50
                minFalseStarts = 0
            case .hard:
                minLen = 3
                let hardMax = sequenceCount - 1
                overlapCount = Int.random(in: min(1, hardMax)...min(2, hardMax))
                overlapDepth = min(Int.random(in: 1...2), minLen - 1)
                targetSolutionRange = 1...25
                maxSolutions = 25
                minFalseStarts = 0
            case .expert:
                minLen = 3
                let expertMax = sequenceCount - 1
                overlapCount = Int.random(in: min(2, expertMax)...min(3, expertMax))
                overlapDepth = min(Int.random(in: 1...2), minLen - 1)
                targetSolutionRange = 1...10
                maxSolutions = 10
                minFalseStarts = 1
            }

            // 2. Compute maxTotal so merged path ≤ 8 (buffer cap)
            let maxTotal = 8 + overlapCount * overlapDepth
            sequenceLengths = Self.randomSequenceLengths(
                count: sequenceCount, minLength: minLen, maxTotal: maxTotal
            )
        }

        func fillStrategy(for sequences: [[String]]) -> FillStrategy {
            switch targetSolutionRange.upperBound {
            case 100: return .forgiving(solutionCodeDensity: 0.5)
            case 50: return .moderate(redHerringDensity: 0.15)
            default:
                let seqCodes = Set(sequences.flatMap { $0 })
                let density: Double = targetSolutionRange.upperBound <= 10 ? 0.4 : 0.3
                return .deceptive(decoyDensity: density, sequenceCodes: seqCodes)
            }
        }

        private static func randomSequenceLengths(
            count: Int, minLength: Int, maxTotal: Int
        ) -> [Int] {
            var lengths = Array(repeating: minLength, count: count)
            var remaining = maxTotal - count * minLength

            while remaining > 0 {
                let growable = (0..<count).filter { lengths[$0] < 5 }
                guard let idx = growable.randomElement() else { break }
                lengths[idx] += 1
                remaining -= 1
            }

            return lengths.shuffled()
        }
    }

    /// Why a generation attempt failed
    private enum RejectReason {
        case buildFailed
        case validationFailed
        case tooManySolutions(found: Int, cap: Int)
        case tooFewFalseStarts(found: Int, need: Int)
        case notSolvable
        case adjustmentFailed
    }

    static func generate(difficulty: Difficulty) -> Puzzle {
        let maxAttempts = 20
        var rejectCounts: [String: Int] = [:]
        var seqCountSeen: [Int: Int] = [:]

        for attempt in 0..<maxAttempts {
            let params = DifficultyParams(difficulty: difficulty)
            seqCountSeen[params.sequenceCount, default: 0] += 1

            let (puzzle, reason) = tryGenerate(
                difficulty: difficulty, params: params
            )

            if let puzzle {
                log.info(
                    "Puzzle generated",
                    metadata: [
                        "attempts": "\(attempt + 1)",
                        "difficulty": difficulty.rawValue,
                        "seqCount": "\(puzzle.sequences.count)",
                        "seqLens": "\(params.sequenceLengths)",
                        "par": "\(puzzle.par)",
                        "buffer": "\(puzzle.bufferSize)"
                    ],
                    tags: ["puzzle"]
                )
                return puzzle
            }

            if let reason {
                let key = rejectReasonKey(reason)
                rejectCounts[key, default: 0] += 1
            }
        }

        return generateFallback(
            difficulty: difficulty,
            maxAttempts: maxAttempts,
            rejectCounts: rejectCounts,
            seqCountSeen: seqCountSeen
        )
    }

    private static func generateFallback(
        difficulty: Difficulty,
        maxAttempts: Int,
        rejectCounts: [String: Int],
        seqCountSeen: [Int: Int]
    ) -> Puzzle {
        let rejectSummary = rejectCounts
            .sorted { $0.value > $1.value }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let seqSummary = seqCountSeen
            .sorted { $0.key < $1.key }
            .map { "\($0.key)seq=\($0.value)" }
            .joined(separator: " ")

        log.warning(
            "Puzzle generation used fallback",
            metadata: [
                "attempts": "\(maxAttempts)",
                "difficulty": difficulty.rawValue,
                "rejects": rejectSummary,
                "seqRolls": seqSummary
            ],
            tags: ["puzzle"]
        )
        return PuzzleGeneratorCore.generateFallback(
            gridSize: difficulty.gridSize,
            sequenceLength: 3,
            bufferSize: difficulty.bufferSize,
            difficulty: difficulty
        )
    }

    // MARK: - Generation Pipeline

    private static func tryGenerate(
        difficulty: Difficulty,
        params: DifficultyParams
    ) -> (Puzzle?, RejectReason?) {
        let codePool = Array(
            Cell.availableCodes.shuffled().prefix(params.codePoolSize)
        )

        // 1. Generate overlapping sequences
        let config = OverlapConfig(
            overlapCount: params.overlapCount,
            overlapDepth: params.overlapDepth,
            codePool: codePool,
            sequenceLengths: params.sequenceLengths
        )
        let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
        guard !chain.sequences.isEmpty else { return (nil, .buildFailed) }

        // 2. Place solution path
        guard let (partialGrid, solutionPath) = PuzzleGeneratorCore.placeSolutionPath(
            mergedPath: chain.mergedPath, gridSize: params.gridSize
        ) else { return (nil, .buildFailed) }

        // 3. Fill grid by difficulty strategy
        let strategy = params.fillStrategy(for: chain.sequences)
        let grid = PuzzleGeneratorCore.fillGridByDifficulty(
            grid: partialGrid,
            solutionPath: solutionPath,
            strategy: strategy,
            codePool: codePool
        )

        // 4. Build puzzle and validate
        let par = chain.mergedPath.count
        let puzzle = Puzzle(
            grid: grid,
            sequences: chain.sequences.map { TargetSequence(codes: $0) },
            bufferSize: min(par + params.bufferMargin, 8),
            par: par,
            difficulty: difficulty,
            solutionPath: solutionPath
        )

        guard PuzzleGeneratorCore.validatePuzzle(puzzle) else {
            return (nil, .validationFailed)
        }

        // 5. Skip solver for easy/medium
        guard params.usesSolverQualityGate else { return (puzzle, nil) }

        // 6. Solver quality gate with adjustment
        return verifySolverQuality(
            puzzle: puzzle,
            chain: chain,
            solutionPath: solutionPath,
            codePool: codePool,
            params: params
        )
    }

    // MARK: - Solver Verification

    private static func verifySolverQuality(
        puzzle: Puzzle,
        chain: SolutionChain,
        solutionPath: [Position],
        codePool: [String],
        params: DifficultyParams
    ) -> (Puzzle?, RejectReason?) {
        let sequences = chain.sequences
        let result = PuzzleSolver.solve(
            grid: puzzle.grid,
            sequences: sequences,
            bufferSize: puzzle.bufferSize,
            maxSolutions: params.maxSolutions + 1
        )

        guard result.isSolvable else {
            return (nil, .notSolvable)
        }
        guard result.falseStarts >= params.minFalseStarts else {
            return (
                nil,
                .tooFewFalseStarts(
                    found: result.falseStarts, need: params.minFalseStarts
                )
            )
        }

        // Check if solution count is in range, adjust if needed
        if params.targetSolutionRange.contains(result.solutionCount) {
            return (puzzle, nil)
        }

        guard let adjusted = PuzzleGeneratorCore.adjustSolutionCount(
            grid: puzzle.grid,
            solutionPath: solutionPath,
            sequences: sequences,
            bufferSize: puzzle.bufferSize,
            targetRange: params.targetSolutionRange,
            codePool: codePool
        ) else {
            return (nil, .adjustmentFailed)
        }

        let adjustedPuzzle = Puzzle(
            grid: adjusted,
            sequences: puzzle.sequences,
            bufferSize: puzzle.bufferSize,
            par: puzzle.par,
            difficulty: puzzle.difficulty,
            solutionPath: solutionPath
        )

        guard PuzzleGeneratorCore.validatePuzzle(adjustedPuzzle) else {
            return (nil, .validationFailed)
        }

        return (adjustedPuzzle, nil)
    }

    private static func rejectReasonKey(_ reason: RejectReason) -> String {
        switch reason {
        case .buildFailed: "build"
        case .validationFailed: "validation"
        case .tooManySolutions: "solutions"
        case .tooFewFalseStarts: "falseStarts"
        case .notSolvable: "unsolvable"
        case .adjustmentFailed: "adjustment"
        }
    }
}
