import SwiftUI

// MARK: - Game Mode

enum GameMode {
    case standard
    case gridRush

    var title: String {
        switch self {
        case .standard: "STANDARD MODE"
        case .gridRush: "GRID RUSH"
        }
    }

    var description: String {
        switch self {
        case .standard: "Select difficulty and breach the protocol. Complete sequences within the buffer limit."
        case .gridRush: "Race against the clock. Clear grids to earn bonus time and rack up your score."
        }
    }

    var icon: String {
        switch self {
        case .standard: "terminal"
        case .gridRush: "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .standard: BreachColors.accent
        case .gridRush: BreachColors.accentHighlight
        }
    }
}

// MARK: - Mode Config View

struct ModeConfigView: View {
    let mode: GameMode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject private var backgroundState: BackgroundStateManager
    @EnvironmentObject private var transitionManager: TransitionManager
    @ObservedObject private var settings = GameSettings.shared
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showingGame = false
    @State private var showingGridRush = false

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(spacing: BreachSpacing.xl) {
            headerSection
            modeInfoSection

            if mode == .standard {
                standardContent
            } else {
                gridRushContent
            }

            Spacer()

            actionButton
        }
        .padding(.horizontal, isWideLayout ? BreachSpacing.xxl : BreachSpacing.xl)
        .padding(.bottom, BreachSpacing.xl)
        .onAppear {
            backgroundState.state = .menu
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .navigationDestination(isPresented: $showingGame) {
            GameView(difficulty: selectedDifficulty)
        }
        .navigationDestination(isPresented: $showingGridRush) {
            GridRushView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button {
                transitionManager.transition {
                    dismiss()
                }
            } label: {
                HStack(spacing: BreachSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("BACK")
                        .font(BreachTypography.caption())
                }
                .foregroundColor(BreachColors.accent)
            }

            Spacer()

            Text(mode.title)
                .font(BreachTypography.heading(16))
                .foregroundColor(mode.color)

            Spacer()

            // Invisible spacer for alignment
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.top, BreachSpacing.lg)
    }

    // MARK: - Mode Info

    private var modeInfoSection: some View {
        VStack(spacing: BreachSpacing.md) {
            Image(systemName: mode.icon)
                .font(.system(size: 40))
                .foregroundColor(mode.color)
                .shadow(color: mode.color.opacity(0.5), radius: 10)

            Text(mode.description)
                .font(BreachTypography.body())
                .foregroundColor(BreachColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .padding(.vertical, BreachSpacing.md)
    }

    // MARK: - Standard Content

    private var standardContent: some View {
        VStack(spacing: BreachSpacing.md) {
            BreachSectionHeader("SELECT DIFFICULTY")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BreachSpacing.md) {
                ForEach(Difficulty.allCases) { difficulty in
                    let isLocked = !settings.isDifficultyUnlocked(difficulty)
                    DifficultyCard(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        isLocked: isLocked,
                        starsEarned: settings.stats(for: difficulty).totalStars
                    ) {
                        guard !isLocked else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }

            Text(
                "Buffer: \(selectedDifficulty.bufferSize) | Grid: \(selectedDifficulty.gridSize)x\(selectedDifficulty.gridSize)"
            )
            .font(BreachTypography.caption(10))
            .foregroundColor(BreachColors.textMuted)
        }
        .frame(maxWidth: isWideLayout ? 600 : .infinity)
    }

    // MARK: - Grid Rush Content

    private var gridRushContent: some View {
        VStack(spacing: BreachSpacing.lg) {
            let stats = settings.gridRushStats

            if stats.totalRuns > 0 {
                VStack(spacing: BreachSpacing.md) {
                    BreachSectionHeader("HIGH SCORE", color: BreachColors.accentHighlight)

                    Text("\(stats.highScore)")
                        .font(BreachTypography.title(48))
                        .foregroundColor(BreachColors.accentHighlight)
                        .shadow(color: BreachColors.accentHighlight.opacity(0.5), radius: 10)

                    HStack(spacing: BreachSpacing.xl) {
                        VStack(spacing: BreachSpacing.xs) {
                            Text("\(stats.bestGridsCleared)")
                                .font(BreachTypography.heading(20))
                                .foregroundColor(BreachColors.accent)
                            Text("BEST GRIDS")
                                .font(BreachTypography.caption(10))
                                .foregroundColor(BreachColors.textMuted)
                        }

                        VStack(spacing: BreachSpacing.xs) {
                            Text("\(stats.totalRuns)")
                                .font(BreachTypography.heading(20))
                                .foregroundColor(BreachColors.accentSecondary)
                            Text("TOTAL RUNS")
                                .font(BreachTypography.caption(10))
                                .foregroundColor(BreachColors.textMuted)
                        }
                    }
                }
                .padding(BreachSpacing.xl)
                .breachGlass(tint: BreachColors.accentHighlight, opacity: 0.05)
                .overlay(
                    Rectangle()
                        .stroke(BreachColors.accentHighlight.opacity(0.3), lineWidth: 1)
                )
                .breachBevel(color: BreachColors.accentHighlight)
            } else {
                VStack(spacing: BreachSpacing.md) {
                    Text("No runs yet")
                        .font(BreachTypography.body())
                        .foregroundColor(BreachColors.textMuted)

                    Text("Clear grids against the clock!")
                        .font(BreachTypography.caption(11))
                        .foregroundColor(BreachColors.textMuted.opacity(0.7))
                }
                .padding(BreachSpacing.xl)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: BreachSpacing.md) {
            BreachButton(
                mode == .standard ? "INITIATE BREACH" : "START RUN",
                color: mode.color
            ) {
                transitionManager.transition(style: .breachInitiated) {
                    if mode == .standard {
                        showingGame = true
                    } else {
                        showingGridRush = true
                    }
                }
            }

            if mode == .gridRush {
                Text("Timed mode \u{2022} Clear grids for bonus time")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
            }
        }
        .padding(.bottom, BreachSpacing.lg)
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .menu).ignoresSafeArea()
        NavigationStack {
            ModeConfigView(mode: .standard)
        }
    }
    .environmentObject(BackgroundStateManager())
    .environmentObject(TransitionManager())
}
