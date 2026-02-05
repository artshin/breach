import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject private var viewModel: GameViewModel

    init(difficulty: Difficulty) {
        _viewModel = StateObject(wrappedValue: GameViewModel(difficulty: difficulty))
    }

    // Use side-by-side layout on iPad or landscape on larger phones
    private var useWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    // Computed background state based on game result
    private var backgroundState: BackgroundGameState {
        switch viewModel.gameResult {
        case .playing:
            let bufferFillRatio = Double(viewModel.buffer.count) / Double(viewModel.bufferSize)
            return .game(bufferFillRatio: bufferFillRatio)
        case .finished(_, _, _, _):
            if viewModel.gameResult.stars > 0 {
                return .win
            } else {
                return .loss
            }
        }
    }

    var body: some View {
        ZStack {
            // Animated background
            BackgroundView(state: backgroundState)
                .ignoresSafeArea()

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
                    onHome: { dismiss() }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
            // Back Button
            Button(action: { dismiss() }) {
                HStack(spacing: BreachSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("EXIT")
                        .font(BreachTypography.caption())
                }
                .foregroundColor(BreachColors.cyan)
            }

            Spacer()

            // Title
            Text("BREACH PROTOCOL")
                .font(BreachTypography.heading(16))
                .foregroundColor(BreachColors.cyan)

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
                    .foregroundColor(viewModel.moveCount <= viewModel.par ? BreachColors.green : BreachColors.yellow)
                Text("/")
                    .foregroundColor(BreachColors.textMuted)
                Text("\(viewModel.par)")
                    .font(BreachTypography.caption(12))
                    .foregroundColor(BreachColors.cyan.opacity(0.7))
                Text("PAR")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
            }

            Spacer()

            // Restart Button
            BreachOutlineButton("RESTART", color: BreachColors.cyan) {
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
        case .easy: return BreachColors.green
        case .medium: return BreachColors.yellow
        case .hard: return BreachColors.orange
        case .expert: return BreachColors.red
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
                RoundedRectangle(cornerRadius: BreachRadius.sm)
                    .stroke(badgeColor.opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(BreachRadius.sm)
    }
}

#Preview {
    NavigationStack {
        GameView(difficulty: .easy)
    }
}
