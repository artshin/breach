import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject, GamePlayable {
    @Published var gameState: GameState
    @Published var selectedDifficulty: Difficulty = .easy

    // Feedback managers
    private let sound: SoundManager
    private let haptics: HapticsManager
    private let settings: GameSettings

    init(
        difficulty: Difficulty = .easy,
        sound: SoundManager = .shared,
        haptics: HapticsManager = .shared,
        settings: GameSettings = .shared
    ) {
        self.sound = sound
        self.haptics = haptics
        self.settings = settings
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

    // MARK: - Cell Selection

    func selectCell(_ cell: Cell) {
        guard isValidSelection(cell: cell) else { return }

        sound.playCellSelect()
        haptics.cellSelected()

        let previousCompletedCount = gameState.sequences.filter(\.isComplete).count
        let previousMatchedCounts = gameState.sequences.map(\.matchedCount)

        // Mark cell as selected
        gameState.grid[cell.row][cell.col].isSelected = true
        gameState.buffer.append(cell.code)
        gameState.moveCount += 1
        gameState.lastPosition = cell.position

        // Toggle selection mode
        switch gameState.selectionMode {
        case .horizontal:
            gameState.selectionMode = .vertical(col: cell.col)
        case .vertical:
            gameState.selectionMode = .horizontal(row: cell.row)
        }

        // Update sequence progress
        GameEngine.updateSequenceProgress(
            sequences: &gameState.sequences,
            latestCode: cell.code,
            isWildcard: false
        )

        // Play feedback
        let newCompletedCount = gameState.sequences.filter(\.isComplete).count
        let newMatchedCounts = gameState.sequences.map(\.matchedCount)

        GameEngine.playSequenceFeedback(
            previousCompletedCount: previousCompletedCount,
            newCompletedCount: newCompletedCount,
            previousMatchedCounts: previousMatchedCounts,
            newMatchedCounts: newMatchedCounts,
            sound: sound,
            haptics: haptics
        )

        // Check feasibility
        let movesRemaining = gameState.bufferSize - gameState.buffer.count
        GameEngine.updateSequenceFeasibility(
            sequences: &gameState.sequences,
            currentPosition: gameState.currentPosition,
            isHorizontal: gameState.selectionMode.isHorizontal,
            usedCells: gameState.usedCells,
            movesRemaining: movesRemaining,
            grid: gameState.grid
        )

        // Check for newly impossible sequences
        let newlyImpossible = gameState.sequences.filter { $0.isImpossible && !$0.isComplete }
        if !newlyImpossible.isEmpty {
            Task { [sound, haptics] in
                try? await Task.sleep(for: .milliseconds(150))
                sound.playSequenceFailed()
                haptics.sequenceFailed()
            }
        }

        checkGameResult()
    }

    // MARK: - Game Result

    private func checkGameResult() {
        if gameState.allSequencesComplete {
            let result: GameResult = .finished(
                completedSequences: gameState.sequences.count,
                totalSequences: gameState.sequences.count,
                moves: gameState.moveCount,
                par: gameState.par
            )
            gameState.gameResult = result
            settings.recordGameResult(difficulty: selectedDifficulty, stars: result.stars)

            Task { [sound, haptics] in
                try? await Task.sleep(for: .milliseconds(300))
                sound.playGameWin()
                haptics.gameWin()
            }
            return
        }

        if gameState.buffer.count >= gameState.bufferSize {
            let completed = gameState.completedSequenceCount
            let result: GameResult = .finished(
                completedSequences: completed,
                totalSequences: gameState.sequences.count,
                moves: gameState.moveCount,
                par: gameState.par
            )
            gameState.gameResult = result
            settings.recordGameResult(difficulty: selectedDifficulty, stars: result.stars)

            Task { [sound, haptics] in
                try? await Task.sleep(for: .milliseconds(300))
                if completed > 0 {
                    sound.playGameWin()
                    haptics.gameWin()
                } else {
                    sound.playGameLose()
                    haptics.gameLose()
                }
            }
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

    func advancingPositions() -> Set<Position> {
        guard !gameState.gameResult.isGameOver else { return [] }
        guard settings.helpModeEnabled else { return [] }

        return PathFinder.positionsAdvancingSequences(
            sequences: gameState.sequences,
            currentPosition: gameState.currentPosition,
            isHorizontal: gameState.selectionMode.isHorizontal,
            usedCells: gameState.usedCells,
            grid: gameState.grid
        )
    }
}
