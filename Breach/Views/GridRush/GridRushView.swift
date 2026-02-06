import SwiftUI

struct GridRushView: View {
    @StateObject private var viewModel = GridRushViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var bufferFillRatio: Double {
        guard viewModel.bufferSize > 0 else { return 0 }
        return Double(viewModel.buffer.count) / Double(viewModel.bufferSize)
    }

    var body: some View {
        ZStack {
            // Background
            BackgroundView(state: .game(bufferFillRatio: bufferFillRatio))
                .ignoresSafeArea()

            if viewModel.gameState != nil {
                // Main game content
                VStack(spacing: BreachSpacing.md) {
                    // Header with timer, grid counter, score
                    GridRushHeaderView(
                        timeRemaining: viewModel.timeRemaining,
                        gridNumber: viewModel.currentGridNumber,
                        score: viewModel.totalScore
                    )
                    .padding(.horizontal, BreachSpacing.lg)

                    if isWideLayout {
                        // iPad: Side-by-side layout
                        HStack(alignment: .top, spacing: BreachSpacing.lg) {
                            // Left: Grid
                            GridRushMatrixGridView(viewModel: viewModel)
                                .frame(maxWidth: 400)

                            // Right: Buffer and Sequences
                            VStack(spacing: BreachSpacing.md) {
                                BufferView(
                                    buffer: viewModel.buffer,
                                    bufferSize: viewModel.bufferSize
                                )

                                SequencePanelView(sequences: viewModel.sequences)

                                Spacer()
                            }
                            .frame(maxWidth: 300)
                        }
                        .padding(.horizontal, BreachSpacing.lg)
                    } else {
                        // iPhone: Stacked layout
                        VStack(spacing: BreachSpacing.md) {
                            // Buffer
                            BufferView(
                                buffer: viewModel.buffer,
                                bufferSize: viewModel.bufferSize
                            )
                            .padding(.horizontal, BreachSpacing.lg)

                            // Grid
                            GridRushMatrixGridView(viewModel: viewModel)
                                .padding(.horizontal, BreachSpacing.sm)

                            // Sequences
                            SequencePanelView(sequences: viewModel.sequences)
                                .padding(.horizontal, BreachSpacing.lg)
                        }
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
                    .tint(BreachColors.cyan)
            }

            // Game Over overlay
            if viewModel.isGameOver {
                GridRushGameOverView(
                    rushState: viewModel.rushState,
                    onPlayAgain: {
                        viewModel.startNewRun()
                    },
                    onGoHome: {
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.pauseTimer()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("EXIT")
                    }
                    .font(BreachTypography.caption())
                    .foregroundColor(BreachColors.cyan)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if viewModel.isPaused {
                        viewModel.resumeTimer()
                    } else {
                        viewModel.pauseTimer()
                    }
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16))
                        .foregroundColor(BreachColors.cyan)
                }
            }
        }
        .onAppear {
            viewModel.startNewRun()
        }
        .onDisappear {
            viewModel.pauseTimer()
        }
    }
}

#Preview {
    NavigationStack {
        GridRushView()
    }
}
