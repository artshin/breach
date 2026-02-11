import Foundation

/// Shared game mechanics used by both Standard and Grid Rush view models
@MainActor
enum GameEngine {
    /// Update sequence progress after selecting a cell
    static func updateSequenceProgress(
        sequences: inout [TargetSequence],
        latestCode: String,
        isWildcard: Bool
    ) {
        for i in 0..<sequences.count {
            let sequence = sequences[i]
            guard !sequence.isComplete, !sequence.isImpossible else { continue }

            if let nextCode = sequence.nextNeededCode {
                if isWildcard || nextCode == latestCode {
                    sequences[i].matchedCount += 1
                }
            }
        }
    }

    /// Check feasibility of remaining sequences
    static func updateSequenceFeasibility(
        sequences: inout [TargetSequence],
        currentPosition: Position,
        isHorizontal: Bool,
        usedCells: Set<Position>,
        movesRemaining: Int,
        grid: [[Cell]]
    ) {
        for i in 0..<sequences.count {
            let sequence = sequences[i]
            guard !sequence.isComplete, !sequence.isImpossible else { continue }

            let canComplete = PathFinder.canCompleteSequence(
                sequence: sequence,
                currentPosition: currentPosition,
                isHorizontal: isHorizontal,
                usedCells: usedCells,
                movesRemaining: movesRemaining,
                grid: grid
            )

            if !canComplete {
                sequences[i].isImpossible = true
            }
        }
    }

    /// Play sound/haptic feedback based on sequence state changes
    static func playSequenceFeedback(
        previousCompletedCount: Int,
        newCompletedCount: Int,
        previousMatchedCounts: [Int],
        newMatchedCounts: [Int],
        sound: SoundManager,
        haptics: HapticsManager
    ) {
        if newCompletedCount > previousCompletedCount {
            sound.playSequenceComplete()
            haptics.sequenceComplete()
        } else {
            for i in 0..<newMatchedCounts.count
                where newMatchedCounts[i] > previousMatchedCounts[i] {
                sound.playSequenceProgress()
                haptics.sequenceProgress()
                break
            }
        }
    }
}
