import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameState: GameState
    @Published var selectedDifficulty: Difficulty = .easy

    // Feedback managers
    private let sound = SoundManager.shared
    private let haptics = HapticsManager.shared
    private let settings = GameSettings.shared

    init(difficulty: Difficulty = .easy) {
        selectedDifficulty = difficulty
        gameState = GameState(difficulty: difficulty)
    }

    var grid: [[Cell]] {
        gameState.grid
    }

    var buffer: [String] {
        gameState.buffer
    }

    var bufferSize: Int {
        gameState.bufferSize
    }

    var sequences: [TargetSequence] {
        gameState.sequences
    }

    var gameResult: GameResult {
        gameState.gameResult
    }

    var selectionMode: SelectionMode {
        gameState.selectionMode
    }

    var par: Int {
        gameState.par
    }

    var moveCount: Int {
        gameState.moveCount
    }

    // MARK: - Cell Validation

    func isValidSelection(cell: Cell) -> Bool {
        guard !gameState.gameResult.isGameOver else { return false }
        guard !cell.isSelected else { return false }

        switch gameState.selectionMode {
        case let .horizontal(row):
            return cell.row == row
        case let .vertical(col):
            return cell.col == col
        }
    }

    /// Returns true if this cell would advance any sequence
    func cellAdvancesSequence(cell: Cell) -> Bool {
        guard isValidSelection(cell: cell) else { return false }

        let nextNeededCodes = Set(gameState.sequences
            .filter { !$0.isComplete && !$0.isImpossible }
            .compactMap(\.nextNeededCode))

        return nextNeededCodes.contains(cell.code)
    }

    // MARK: - Cell Selection

    func selectCell(_ cell: Cell) {
        guard isValidSelection(cell: cell) else { return }

        // Play cell selection feedback
        sound.playCellSelect()
        haptics.cellSelected()

        // Store sequence states before update to detect changes
        let previousCompletedCount = gameState.sequences.filter(\.isComplete).count
        let previousMatchedCounts = gameState.sequences.map(\.matchedCount)

        // Mark cell as selected
        gameState.grid[cell.row][cell.col].isSelected = true

        // Add code to buffer
        gameState.buffer.append(cell.code)
        gameState.moveCount += 1

        // Update last position
        gameState.lastPosition = cell.position

        // Toggle selection mode
        switch gameState.selectionMode {
        case .horizontal:
            gameState.selectionMode = .vertical(col: cell.col)
        case .vertical:
            gameState.selectionMode = .horizontal(row: cell.row)
        }

        // Update sequence progress
        updateSequenceProgress()

        // Check for sequence progress feedback
        let newCompletedCount = gameState.sequences.filter(\.isComplete).count
        let newMatchedCounts = gameState.sequences.map(\.matchedCount)

        // Check if any sequence was just completed
        if newCompletedCount > previousCompletedCount {
            sound.playSequenceComplete()
            haptics.sequenceComplete()
        } else {
            // Check if any sequence made progress
            for i in 0..<gameState.sequences.count
                where newMatchedCounts[i] > previousMatchedCounts[i] {
                sound.playSequenceProgress()
                haptics.sequenceProgress()
                break
            }
        }

        // Check feasibility of remaining sequences
        updateSequenceFeasibility()

        // Check for newly impossible sequences
        let newlyImpossible = gameState.sequences.filter { $0.isImpossible && !$0.isComplete }
        if !newlyImpossible.isEmpty {
            // Delay slightly to not conflict with progress sounds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.sound.playSequenceFailed()
                self?.haptics.sequenceFailed()
            }
        }

        // Check game result
        checkGameResult()
    }

    // MARK: - Sequence Progress

    private func updateSequenceProgress() {
        let latestCode = gameState.buffer.last

        for i in 0..<gameState.sequences.count {
            let sequence = gameState.sequences[i]

            // Skip completed or impossible sequences
            guard !sequence.isComplete, !sequence.isImpossible else { continue }

            // Check if latest code matches next needed
            if let nextCode = sequence.nextNeededCode, nextCode == latestCode {
                gameState.sequences[i].matchedCount += 1
            }
        }
    }

    private func updateSequenceFeasibility() {
        let movesRemaining = gameState.bufferSize - gameState.buffer.count

        for i in 0..<gameState.sequences.count {
            let sequence = gameState.sequences[i]

            // Skip completed or already marked impossible
            guard !sequence.isComplete, !sequence.isImpossible else { continue }

            // Check if sequence can still be completed
            let canComplete = PathFinder.canCompleteSequence(
                sequence: sequence,
                currentPosition: gameState.currentPosition,
                isHorizontal: gameState.selectionMode.isHorizontal,
                usedCells: gameState.usedCells,
                movesRemaining: movesRemaining,
                grid: gameState.grid
            )

            if !canComplete {
                gameState.sequences[i].isImpossible = true
            }
        }
    }

    // MARK: - Game Result

    private func checkGameResult() {
        // Check if all sequences are complete
        if gameState.allSequencesComplete {
            let result: GameResult = .finished(
                completedSequences: gameState.sequences.count,
                totalSequences: gameState.sequences.count,
                moves: gameState.moveCount,
                par: gameState.par
            )
            gameState.gameResult = result

            // Record stats
            settings.recordGameResult(difficulty: selectedDifficulty, stars: result.stars)

            // Play win feedback with delay to let sequence complete sound finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.sound.playGameWin()
                self?.haptics.gameWin()
            }
            return
        }

        // Check if buffer is full
        if gameState.buffer.count >= gameState.bufferSize {
            let completed = gameState.completedSequenceCount
            let result: GameResult = .finished(
                completedSequences: completed,
                totalSequences: gameState.sequences.count,
                moves: gameState.moveCount,
                par: gameState.par
            )
            gameState.gameResult = result

            // Record stats
            settings.recordGameResult(difficulty: selectedDifficulty, stars: result.stars)

            // Play appropriate feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                if completed > 0 {
                    // Partial success
                    self?.sound.playGameWin()
                    self?.haptics.gameWin()
                } else {
                    // Complete failure
                    self?.sound.playGameLose()
                    self?.haptics.gameLose()
                }
            }
            return
        }

        // Check if all remaining sequences are impossible
        let remainingPossible = gameState.sequences.filter { !$0.isComplete && !$0.isImpossible }
        if remainingPossible.isEmpty, !gameState.allSequencesComplete {
            // All remaining sequences are impossible, game effectively over
            // But player can continue to try to complete already-progressed sequences
            // For now, we let them play until buffer is full
        }
    }

    // MARK: - New Game

    func newGame() {
        gameState = GameState(difficulty: selectedDifficulty)
    }

    func newGame(difficulty: Difficulty) {
        selectedDifficulty = difficulty
        gameState = GameState(difficulty: difficulty)
    }

    // MARK: - Highlighting

    func getHighlightedRow() -> Int? {
        guard !gameState.gameResult.isGameOver else { return nil }
        if case let .horizontal(row) = gameState.selectionMode {
            return row
        }
        return nil
    }

    func getHighlightedColumn() -> Int? {
        guard !gameState.gameResult.isGameOver else { return nil }
        if case let .vertical(col) = gameState.selectionMode {
            return col
        }
        return nil
    }

    /// Get all positions that would advance any sequence
    func advancingPositions() -> Set<Position> {
        guard !gameState.gameResult.isGameOver else { return [] }

        return PathFinder.positionsAdvancingSequences(
            sequences: gameState.sequences,
            currentPosition: gameState.currentPosition,
            isHorizontal: gameState.selectionMode.isHorizontal,
            usedCells: gameState.usedCells,
            grid: gameState.grid
        )
    }
}
