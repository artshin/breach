import Combine
import Foundation
import SwiftUI

@MainActor
class GridRushViewModel: ObservableObject, GamePlayable {
    // MARK: - Published State

    @Published var rushState: GridRushState
    @Published var gameState: GameState?
    @Published var showBonusAnimation: GridClearResult?
    @Published var isPaused = false

    // MARK: - Private Properties

    private var timer: Timer?
    private let sound: SoundManager
    private let haptics: HapticsManager
    private let settings: GameSettings

    // MARK: - Initialization

    init(
        sound: SoundManager = .shared,
        haptics: HapticsManager = .shared,
        settings: GameSettings = .shared
    ) {
        self.sound = sound
        self.haptics = haptics
        self.settings = settings
        rushState = GridRushState()
    }

    // MARK: - Computed Properties

    var grid: [[Cell]] {
        gameState?.grid ?? []
    }

    var buffer: [String] {
        gameState?.buffer ?? []
    }

    var bufferSize: Int {
        gameState?.bufferSize ?? 0
    }

    var sequences: [TargetSequence] {
        gameState?.sequences ?? []
    }

    var selectionMode: SelectionMode {
        gameState?.selectionMode ?? .horizontal(row: 0)
    }

    var isGameOver: Bool {
        rushState.isGameOver
    }

    var currentGridNumber: Int {
        rushState.currentGridNumber
    }

    var timeRemaining: Int {
        rushState.timeRemaining
    }

    var totalScore: Int {
        rushState.totalScore
    }

    // MARK: - Timer Control

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pauseTimer() {
        isPaused = true
        stopTimer()
    }

    func resumeTimer() {
        isPaused = false
        startTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !isPaused else { return }

        rushState.tick()

        if rushState.isGameOver {
            stopTimer()
            endGame()
        }
    }

    // MARK: - Game Flow

    func startNewRun() {
        rushState = GridRushState()
        loadNextGrid()
        startTimer()
    }

    func loadNextGrid() {
        let stage = rushState.currentStage
        let puzzle = GridRushPuzzleGenerator.generate(stage: stage)
        gameState = GameState(puzzle: puzzle)
        rushState.markGridStart()
    }

    // MARK: - Cell Selection

    func isValidSelection(cell: Cell) -> Bool {
        guard let state = gameState else { return false }
        guard !state.gameResult.isGameOver else { return false }
        guard !cell.isSelected else { return false }
        guard !cell.isBlocked else { return false }

        switch state.selectionMode {
        case let .horizontal(row):
            return cell.row == row
        case let .vertical(col):
            return cell.col == col
        }
    }

    func selectCell(_ cell: Cell) {
        guard var state = gameState else { return }
        guard isValidSelection(cell: cell) else { return }

        sound.playCellSelect()
        haptics.cellSelected()

        let previousCompletedCount = state.sequences.filter(\.isComplete).count
        let previousMatchedCounts = state.sequences.map(\.matchedCount)

        // Mark cell as selected
        state.grid[cell.row][cell.col].isSelected = true
        state.buffer.append(cell.code)
        state.moveCount += 1
        state.lastPosition = cell.position

        // Toggle selection mode
        switch state.selectionMode {
        case .horizontal:
            state.selectionMode = .vertical(col: cell.col)
        case .vertical:
            state.selectionMode = .horizontal(row: cell.row)
        }

        // Update decay cells
        updateDecayCells(grid: &state.grid)

        // Update sequence progress
        GameEngine.updateSequenceProgress(
            sequences: &state.sequences,
            latestCode: cell.code,
            isWildcard: cell.isWildcard
        )

        gameState = state

        // Play feedback
        let newCompletedCount = state.sequences.filter(\.isComplete).count
        let newMatchedCounts = state.sequences.map(\.matchedCount)

        GameEngine.playSequenceFeedback(
            previousCompletedCount: previousCompletedCount,
            newCompletedCount: newCompletedCount,
            previousMatchedCounts: previousMatchedCounts,
            newMatchedCounts: newMatchedCounts,
            sound: sound,
            haptics: haptics
        )

        // Update feasibility
        updateSequenceFeasibility()

        // Check if grid is cleared
        checkGridCleared()
    }

    private func updateSequenceFeasibility() {
        guard var state = gameState else { return }

        let movesRemaining = state.bufferSize - state.buffer.count
        GameEngine.updateSequenceFeasibility(
            sequences: &state.sequences,
            currentPosition: state.currentPosition,
            isHorizontal: state.selectionMode.isHorizontal,
            usedCells: state.usedCells,
            movesRemaining: movesRemaining,
            grid: state.grid
        )

        gameState = state
    }

    // MARK: - Decay Cells

    private func updateDecayCells(grid: inout [[Cell]]) {
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if case let .decay(movesRemaining) = grid[row][col].cellType {
                    if movesRemaining <= 1 {
                        let newCode = Cell.randomCode()
                        grid[row][col].code = newCode
                        grid[row][col].cellType = .normal
                    } else {
                        grid[row][col].cellType = .decay(movesRemaining: movesRemaining - 1)
                    }
                }
            }
        }
    }

    // MARK: - Grid Completion

    private func checkGridCleared() {
        guard let state = gameState else { return }

        if state.allSequencesComplete {
            handleGridCleared()
            return
        }

        if state.buffer.count >= state.bufferSize {
            handleGridFailed()
        }
    }

    private func handleGridCleared() {
        guard let state = gameState else { return }

        let gridClearTime = rushState.gridElapsedTime
        let result = rushState.calculateBonusTime(
            moves: state.moveCount,
            par: state.par,
            gridClearTime: gridClearTime
        )

        rushState.applyGridClear(result: result, moves: state.moveCount)
        showBonusAnimation = result

        sound.playGameWin()
        haptics.gameWin()

        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1500))
            self?.showBonusAnimation = nil
            self?.loadNextGrid()
        }
    }

    private func handleGridFailed() {
        sound.playGameLose()
        haptics.gameLose()

        rushState.currentGridNumber += 1

        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1000))
            self?.loadNextGrid()
        }
    }

    // MARK: - Game Over

    func endGame() {
        stopTimer()
        rushState.isGameOver = true

        settings.recordGridRushResult(
            gridsCompleted: rushState.gridsCompleted,
            score: rushState.totalScore,
            perfectClears: rushState.perfectClears
        )

        sound.playGameLose()
        haptics.gameLose()
    }

    // MARK: - Highlighting

    func getHighlightedRow() -> Int? {
        guard let state = gameState, !state.gameResult.isGameOver else { return nil }
        if case let .horizontal(row) = state.selectionMode {
            return row
        }
        return nil
    }

    func getHighlightedColumn() -> Int? {
        guard let state = gameState, !state.gameResult.isGameOver else { return nil }
        if case let .vertical(col) = state.selectionMode {
            return col
        }
        return nil
    }

    func advancingPositions() -> Set<Position> {
        guard let state = gameState, !state.gameResult.isGameOver else { return [] }

        return PathFinder.positionsAdvancingSequences(
            sequences: state.sequences,
            currentPosition: state.currentPosition,
            isHorizontal: state.selectionMode.isHorizontal,
            usedCells: state.usedCells,
            grid: state.grid
        )
    }

    // MARK: - Cleanup

    deinit {
        timer?.invalidate()
    }
}
