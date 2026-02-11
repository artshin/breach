import Foundation

enum PuzzleGenerator {
    static func generate(difficulty: Difficulty) -> Puzzle {
        var attempts = 0
        let maxAttempts = 100

        while attempts < maxAttempts {
            attempts += 1

            if let puzzle = tryGenerate(difficulty: difficulty) {
                return puzzle
            }
        }

        return PuzzleGeneratorCore.generateFallback(
            gridSize: difficulty.gridSize,
            sequenceLength: 3,
            bufferSize: difficulty.bufferSize,
            difficulty: difficulty
        )
    }

    private static func tryGenerate(difficulty: Difficulty) -> Puzzle? {
        let gridSize = difficulty.gridSize

        // Step 1: Design sequences with overlaps
        let (sequences, mergedPath) = designSequences(difficulty: difficulty)

        // Step 2: Generate solution path through grid
        guard let (partialGrid, solutionPath) = PuzzleGeneratorCore.placeSolutionPath(
            mergedPath: mergedPath,
            gridSize: gridSize
        ) else {
            return nil
        }

        // Step 3: Fill remaining cells
        let grid = PuzzleGeneratorCore.fillRemainingCells(
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
        if PuzzleGeneratorCore.validatePuzzle(puzzle) {
            return puzzle
        }

        return nil
    }

    // MARK: - Sequence Design

    private static func designSequences(
        difficulty: Difficulty
    ) -> (sequences: [[String]], merged: [String]) {
        let codes = Cell.availableCodes

        switch difficulty {
        case .easy:
            let length = Int.random(in: 3...4)
            let seq = (0..<length).map { _ in codes.randomElement()! }
            return ([seq], seq)

        case .medium:
            let lengths = PuzzleGeneratorCore.randomLengths(
                mergedLength: 4, count: 2, overlapSize: 2
            )
            return PuzzleGeneratorCore.designVariableSequences(
                lengths: lengths, overlapSize: 2, codes: codes
            )

        case .hard:
            let merged = 5
            let lengths = PuzzleGeneratorCore.randomLengths(
                mergedLength: merged, count: 2, overlapSize: 1
            )
            return PuzzleGeneratorCore.designVariableSequences(
                lengths: lengths, overlapSize: 1, codes: codes
            )

        case .expert:
            let lengths = PuzzleGeneratorCore.randomLengths(
                mergedLength: 5, count: 3, overlapSize: 2
            )
            return PuzzleGeneratorCore.designVariableSequences(
                lengths: lengths, overlapSize: 2, codes: codes
            )
        }
    }
}
