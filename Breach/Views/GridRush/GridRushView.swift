import SwiftUI

struct GridRushView: View {
    @StateObject private var viewModel = GridRushViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(BackgroundStateManager.self) private var backgroundState
    @Environment(TransitionManager.self) private var transitionManager
    @State private var showAbortConfirmation = false

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var bufferFillRatio: Double {
        guard viewModel.bufferSize > 0 else { return 0 }
        return Double(viewModel.buffer.count) / Double(viewModel.bufferSize)
    }

    private func syncBackground() {
        let ratio = Double(viewModel.buffer.count) / Double(max(1, viewModel.bufferSize))
        backgroundState.state = .game(bufferFillRatio: ratio)
    }

    var body: some View {
        ZStack {
            if viewModel.gameState != nil {
                // Main game content
                VStack(spacing: BreachSpacing.md) {
                    rushHeaderSection

                    // Timer, grid counter, score
                    GridRushHeaderView(
                        timeRemaining: viewModel.timeRemaining,
                        gridNumber: viewModel.currentGridNumber,
                        score: viewModel.totalScore
                    )
                    .padding(.horizontal, BreachSpacing.lg)

                    if isWideLayout {
                        rushWideLayout
                    } else {
                        rushCompactLayout
                    }

                    Spacer()
                }
                .padding(.top, BreachSpacing.md)

                // Bonus animation overlay
                if let bonusResult = viewModel.showBonusAnimation {
                    GridClearBonusView(result: bonusResult)
                        .transition(.scale.combined(with: .opacity))
                }
            } else {
                // Loading state
                ProgressView()
                    .tint(BreachColors.accent)
            }

            // Game Over overlay
            if viewModel.isGameOver {
                GridRushGameOverView(
                    rushState: viewModel.rushState,
                    onPlayAgain: {
                        viewModel.startNewRun()
                    },
                    onGoHome: {
                        transitionManager.transition {
                            dismiss()
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .clearNavigationBackground()
        .onAppear {
            syncBackground()
            viewModel.startNewRun()
        }
        .onChange(of: viewModel.buffer.count) { _ in syncBackground() }
        .onDisappear {
            viewModel.pauseTimer()
        }
        .alert("ABORT RUN", isPresented: $showAbortConfirmation) {
            Button("ABORT", role: .destructive) {
                viewModel.pauseTimer()
                transitionManager.transition { dismiss() }
            }
            Button("CONTINUE", role: .cancel) {
                viewModel.resumeTimer()
            }
        } message: {
            Text("Current run progress will be lost.")
        }
    }

    // MARK: - Rush Header

    private var rushHeaderSection: some View {
        HStack {
            // Abort Button
            Button {
                viewModel.pauseTimer()
                showAbortConfirmation = true
            } label: {
                HStack(spacing: BreachSpacing.xs) {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("ABORT")
                        .font(BreachTypography.caption())
                }
                .foregroundColor(BreachColors.danger)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("GRID RUSH")
                    .font(BreachTypography.heading(16))
                    .foregroundColor(BreachColors.accentHighlight)

                if GameSettings.shared.helpModeEnabled {
                    Text("HELP MODE · UNRANKED")
                        .font(BreachTypography.caption(9))
                        .foregroundColor(BreachColors.warning)
                }
            }

            Spacer()

            // Pause Button
            Button {
                if viewModel.isPaused {
                    viewModel.resumeTimer()
                } else {
                    viewModel.pauseTimer()
                }
            } label: {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 16))
                    .foregroundColor(BreachColors.accent)
            }
        }
        .padding(.horizontal, BreachSpacing.lg)
        .padding(.vertical, BreachSpacing.sm)
    }

    // MARK: - Rush Compact Layout

    private var rushCompactLayout: some View {
        VStack(spacing: BreachSpacing.md) {
            SequencePanelView(sequences: viewModel.sequences)
                .padding(.horizontal, BreachSpacing.lg)

            BufferView(
                buffer: viewModel.buffer,
                bufferSize: viewModel.bufferSize
            )
            .padding(.horizontal, BreachSpacing.lg)

            MatrixGridView(viewModel: viewModel)
                .padding(.horizontal, BreachSpacing.sm)
        }
    }

    // MARK: - Rush Wide Layout

    private var rushWideLayout: some View {
        HStack(alignment: .top, spacing: BreachSpacing.lg) {
            // Left: Grid
            MatrixGridView(viewModel: viewModel)
                .frame(maxWidth: 400)

            // Right: Sequences and Buffer
            VStack(spacing: BreachSpacing.md) {
                SequencePanelView(sequences: viewModel.sequences)

                BufferView(
                    buffer: viewModel.buffer,
                    bufferSize: viewModel.bufferSize
                )

                Spacer()
            }
            .frame(maxWidth: 300)
        }
        .padding(.horizontal, BreachSpacing.lg)
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .game(bufferFillRatio: 0)).ignoresSafeArea()
        NavigationStack {
            GridRushView()
        }
    }
    .environment(BackgroundStateManager())
    .environment(TransitionManager())
}
