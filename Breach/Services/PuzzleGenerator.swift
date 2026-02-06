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
            let seq = (0..<3).map { _ in codes.randomElement()! }
            return ([seq], seq)

        case .medium:
            return PuzzleGeneratorCore.designOverlappingSequences(
                count: 2, overlapSize: 2, sequenceLength: 3, codes: codes
            )

        case .hard:
            return PuzzleGeneratorCore.designOverlappingSequences(
                count: 2, overlapSize: 1, sequenceLength: 3, codes: codes
            )

        case .expert:
            return PuzzleGeneratorCore.designChainedSequences(
                count: 3, sequenceLength: 3, codes: codes
            )
        }
    }
}
