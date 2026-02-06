import Combine
import Foundation
import SwiftUI

@MainActor
class GridRushViewModel: ObservableObject {
    // MARK: - Published State

    @Published var rushState: GridRushState
    @Published var gameState: GameState?
    @Published var showBonusAnimation: GridClearResult?
    @Published var isPaused = false

    // MARK: - Private Properties

    private var timer: Timer?
    private let sound = SoundManager.shared
    private let haptics = HapticsManager.shared
    private let settings = GameSettings.shared

    // MARK: - Initialization

    init() {
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

        // Play feedback
        sound.playCellSelect()
        haptics.cellSelected()

        // Store sequence states before update
        let previousCompletedCount = state.sequences.filter(\.isComplete).count
        let previousMatchedCounts = state.sequences.map(\.matchedCount)

        // Mark cell as selected
        state.grid[cell.row][cell.col].isSelected = true

        // Add code to buffer (use actual code, not display code for wildcards)
        state.buffer.append(cell.code)
        state.moveCount += 1

        // Update last position
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
        updateSequenceProgress(state: &state, cell: cell)

        // Update game state
        gameState = state

        // Check for sequence progress feedback
        let newCompletedCount = state.sequences.filter(\.isComplete).count
        let newMatchedCounts = state.sequences.map(\.matchedCount)

        if newCompletedCount > previousCompletedCount {
            sound.playSequenceComplete()
            haptics.sequenceComplete()
        } else {
            for i in 0..<state.sequences.count
                where newMatchedCounts[i] > previousMatchedCounts[i] {
                sound.playSequenceProgress()
                haptics.sequenceProgress()
                break
            }
        }

        // Update feasibility
        updateSequenceFeasibility()

        // Check if grid is cleared
        checkGridCleared()
    }

    private func updateSequenceProgress(state: inout GameState, cell: Cell) {
        let latestCode = cell.code

        for i in 0..<state.sequences.count {
            let sequence = state.sequences[i]

            guard !sequence.isComplete, !sequence.isImpossible else { continue }

            if let nextCode = sequence.nextNeededCode {
                // Wildcards match any code
                if cell.isWildcard || nextCode == latestCode {
                    state.sequences[i].matchedCount += 1
                }
            }
        }
    }

    private func updateSequenceFeasibility() {
        guard var state = gameState else { return }

        let movesRemaining = state.bufferSize - state.buffer.count

        for i in 0..<state.sequences.count {
            let sequence = state.sequences[i]

            guard !sequence.isComplete, !sequence.isImpossible else { continue }

            let canComplete = PathFinder.canCompleteSequence(
                sequence: sequence,
                currentPosition: state.currentPosition,
                isHorizontal: state.selectionMode.isHorizontal,
                usedCells: state.usedCells,
                movesRemaining: movesRemaining,
                grid: state.grid
            )

            if !canComplete {
                state.sequences[i].isImpossible = true
            }
        }

        gameState = state
    }

    // MARK: - Decay Cells

    private func updateDecayCells(grid: inout [[Cell]]) {
        for row in 0..<grid.count {
            for col in 0..<grid[row].count {
                if case let .decay(movesRemaining) = grid[row][col].cellType {
                    if movesRemaining <= 1 {
                        // Decay: change to random code
                        let newCode = Cell.randomCode()
                        grid[row][col].code = newCode
                        grid[row][col].cellType = .normal
                    } else {
                        // Decrement counter
                        grid[row][col].cellType = .decay(movesRemaining: movesRemaining - 1)
                    }
                }
            }
        }
    }

    // MARK: - Grid Completion

    private func checkGridCleared() {
        guard let state = gameState else { return }

        // Check if all sequences are complete
        if state.allSequencesComplete {
            handleGridCleared()
            return
        }

        // Check if buffer is full (failed to complete)
        if state.buffer.count >= state.bufferSize {
            // In Grid Rush, failing a grid just means you don't get bonus time
            // But the game continues until timer runs out
            handleGridFailed()
        }
    }

    private func handleGridCleared() {
        guard let state = gameState else { return }

        // Calculate bonus time
        let gridClearTime = rushState.gridElapsedTime
        let result = rushState.calculateBonusTime(
            moves: state.moveCount,
            par: state.par,
            gridClearTime: gridClearTime
        )

        // Apply the result
        rushState.applyGridClear(result: result, moves: state.moveCount)

        // Show bonus animation
        showBonusAnimation = result

        // Play success feedback
        sound.playGameWin()
        haptics.gameWin()

        // Load next grid after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showBonusAnimation = nil
            self?.loadNextGrid()
        }
    }

    private func handleGridFailed() {
        // In Grid Rush, failing just loads the next grid without bonus
        // Play failure feedback
        sound.playGameLose()
        haptics.gameLose()

        // Advance to next grid
        rushState.currentGridNumber += 1

        // Load next grid after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadNextGrid()
        }
    }

    // MARK: - Game Over

    func endGame() {
        stopTimer()
        rushState.isGameOver = true

        // Record stats
        settings.recordGridRushResult(
            gridsCompleted: rushState.gridsCompleted,
            score: rushState.totalScore,
            perfectClears: rushState.perfectClears
        )

        // Play game over feedback
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
