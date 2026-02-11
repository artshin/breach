import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(BackgroundStateManager.self) private var backgroundState
    @Environment(TransitionManager.self) private var transitionManager
    @StateObject private var viewModel: GameViewModel
    @State private var showAbortConfirmation = false

    init(difficulty: Difficulty) {
        _viewModel = StateObject(wrappedValue: GameViewModel(difficulty: difficulty))
    }

    /// Use side-by-side layout on iPad or landscape on larger phones
    private var useWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    private func syncBackground() {
        switch viewModel.gameResult {
        case .playing:
            let ratio = Double(viewModel.buffer.count) / Double(viewModel.bufferSize)
            backgroundState.state = .game(bufferFillRatio: ratio)
        case .finished:
            backgroundState.state = viewModel.gameResult.stars > 0 ? .win : .loss
        }
    }

    var body: some View {
        ZStack {
            if useWideLayout {
                wideLayout
            } else {
                compactLayout
            }

            // Game Over Overlay
            if viewModel.gameResult.isGameOver {
                GameOverView(
                    result: viewModel.gameResult,
                    onNewGame: { viewModel.newGame() },
                    onHome: { transitionManager.transition { dismiss() } }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .clearNavigationBackground()
        .onAppear { syncBackground() }
        .onChange(of: viewModel.buffer.count) { _ in syncBackground() }
        .onChange(of: viewModel.gameResult) { _ in syncBackground() }
        .alert("ABORT", isPresented: $showAbortConfirmation) {
            Button("ABORT", role: .destructive) {
                transitionManager.transition { dismiss() }
            }
            Button("CONTINUE", role: .cancel) {}
        } message: {
            Text("Current progress will be lost.")
        }
    }

    // MARK: - Compact Layout (iPhone Portrait)

    private var compactLayout: some View {
        VStack(spacing: BreachSpacing.md) {
            headerSection

            SequencePanelView(sequences: viewModel.sequences)

            BufferView(
                buffer: viewModel.buffer,
                bufferSize: viewModel.bufferSize
            )

            MatrixGridView(viewModel: viewModel)

            Spacer()

            actionSection
        }
        .padding(.horizontal, BreachSpacing.lg)
        .padding(.vertical, BreachSpacing.sm)
    }

    // MARK: - Wide Layout (iPad)

    private var wideLayout: some View {
        VStack(spacing: BreachSpacing.md) {
            headerSection

            HStack(alignment: .top, spacing: BreachSpacing.xl) {
                // Left side: Grid
                VStack {
                    MatrixGridView(viewModel: viewModel)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Right side: Sequences, Buffer, Actions
                VStack(spacing: BreachSpacing.lg) {
                    SequencePanelView(sequences: viewModel.sequences)

                    BufferView(
                        buffer: viewModel.buffer,
                        bufferSize: viewModel.bufferSize
                    )

                    Spacer()

                    actionSection
                }
                .frame(maxWidth: 320)
            }
        }
        .padding(.horizontal, BreachSpacing.xl)
        .padding(.vertical, BreachSpacing.md)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Abort Button
            Button {
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

            // Title
            VStack(spacing: 2) {
                Text("GRIDCRACK")
                    .font(BreachTypography.heading(16))
                    .foregroundColor(BreachColors.accent)

                if GameSettings.shared.helpModeEnabled {
                    Text("HELP MODE · UNRANKED")
                        .font(BreachTypography.caption(9))
                        .foregroundColor(BreachColors.warning)
                }
            }

            Spacer()

            // Difficulty Badge
            DifficultyBadge(difficulty: viewModel.selectedDifficulty)
        }
        .padding(.vertical, BreachSpacing.sm)
    }

    // MARK: - Action Section

    private var actionSection: some View {
        HStack(spacing: BreachSpacing.md) {
            // Par indicator
            HStack(spacing: BreachSpacing.xs) {
                Text("MOVES:")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
                Text("\(viewModel.moveCount)")
                    .font(BreachTypography.body(14))
                    .foregroundColor(viewModel.moveCount <= viewModel.par ? BreachColors.success : BreachColors.warning)
                Text("/")
                    .foregroundColor(BreachColors.textMuted)
                Text("\(viewModel.par)")
                    .font(BreachTypography.caption(12))
                    .foregroundColor(BreachColors.accent.opacity(0.7))
                Text("PAR")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
            }

            Spacer()

            // Restart Button
            BreachOutlineButton("RESTART", color: BreachColors.accent) {
                viewModel.newGame()
            }
        }
        .padding(.vertical, BreachSpacing.sm)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: Difficulty

    private var badgeColor: Color {
        switch difficulty {
        case .easy: BreachColors.tierEasy
        case .medium: BreachColors.tierMedium
        case .hard: BreachColors.tierHard
        case .expert: BreachColors.tierExpert
        }
    }

    var body: some View {
        Text(difficulty.displayName.uppercased())
            .font(BreachTypography.caption(10))
            .foregroundColor(badgeColor)
            .padding(.horizontal, BreachSpacing.sm)
            .padding(.vertical, BreachSpacing.xs)
            .background(badgeColor.opacity(0.15))
            .overlay(
                Rectangle()
                    .stroke(badgeColor.opacity(0.5), lineWidth: 1)
            )
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .game(bufferFillRatio: 0)).ignoresSafeArea()
        NavigationStack {
            GameView(difficulty: .easy)
        }
    }
    .environment(BackgroundStateManager())
    .environment(TransitionManager())
}
