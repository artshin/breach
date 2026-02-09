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
    @Environment(BackgroundStateManager.self) private var backgroundState
    @Environment(TransitionManager.self) private var transitionManager
    @ObservedObject private var settings = GameSettings.shared
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showingGame = false
    @State private var showingGridRush = false

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 0) {
            modeHeroSection

            ScrollView {
                VStack(spacing: BreachSpacing.xl) {
                    if mode == .standard {
                        standardContent
                    } else {
                        gridRushContent
                    }
                }
                .padding(.horizontal, isWideLayout ? BreachSpacing.xxl : BreachSpacing.lg)
                .padding(.top, BreachSpacing.lg)
            }

            Spacer()

            actionButton
        }
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

    // MARK: - Hero Section

    private var modeHeroSection: some View {
        VStack(spacing: BreachSpacing.md) {
            // Back button row
            HStack {
                Button {
                    transitionManager.transition { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(mode.color)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Spacer()
            }
            .padding(.horizontal, BreachSpacing.lg)

            // Decorated title area
            HStack(spacing: BreachSpacing.sm) {
                Rectangle()
                    .fill(mode.color.opacity(0.3))
                    .frame(height: 1)
                Text("//")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(mode.color.opacity(0.4))
                Rectangle()
                    .fill(mode.color.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, BreachSpacing.xxl)
            .frame(maxWidth: 300)

            // Mode icon with glow
            Image(systemName: mode.icon)
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(mode.color)
                .shadow(color: mode.color.opacity(0.6), radius: 12)
                .shadow(color: mode.color.opacity(0.3), radius: 24)

            GlowingText(mode.title, font: BreachTypography.title(28), color: mode.color)

            Text(mode.description)
                .font(BreachTypography.body())
                .foregroundColor(BreachColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            HStack(spacing: BreachSpacing.sm) {
                Rectangle()
                    .fill(mode.color.opacity(0.3))
                    .frame(height: 1)
                Text(mode == .standard ? "SYS://01" : "SYS://02")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(mode.color.opacity(0.4))
                Rectangle()
                    .fill(mode.color.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, BreachSpacing.xxl)
            .frame(maxWidth: 300)
        }
        .padding(.top, BreachSpacing.sm)
        .padding(.bottom, BreachSpacing.md)
    }

    // MARK: - Standard Content

    private var standardContent: some View {
        VStack(spacing: 0) {
            SectionDivider("SELECT DIFFICULTY")
                .padding(.bottom, BreachSpacing.md)

            ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                let isLocked = !settings.isDifficultyUnlocked(difficulty)
                DifficultyRow(
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

                if index < Difficulty.allCases.count - 1 {
                    Rectangle()
                        .fill(BreachColors.accent.opacity(0.1))
                        .frame(height: 1)
                }
            }
        }
        .frame(maxWidth: isWideLayout ? 600 : .infinity)
    }

    // MARK: - Grid Rush Content

    private var gridRushContent: some View {
        VStack(spacing: 0) {
            let stats = settings.gridRushStats

            if stats.totalRuns > 0 {
                SectionDivider("HIGH SCORE", color: BreachColors.accentHighlight)
                    .padding(.bottom, BreachSpacing.md)

                StatRow(
                    icon: "trophy",
                    label: "HIGH SCORE",
                    value: "\(stats.highScore)",
                    color: BreachColors.accentHighlight
                )

                StatRowDivider()

                StatRow(
                    icon: "square.grid.3x3",
                    label: "BEST GRIDS",
                    value: "\(stats.bestGridsCleared)",
                    color: BreachColors.accent
                )

                StatRowDivider()

                StatRow(
                    icon: "arrow.clockwise",
                    label: "TOTAL RUNS",
                    value: "\(stats.totalRuns)",
                    color: BreachColors.accentSecondary
                )
            } else {
                HStack(spacing: BreachSpacing.md) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18))
                        .foregroundColor(BreachColors.accentHighlight.opacity(0.4))

                    Text("No runs yet — clear grids against the clock!")
                        .font(BreachTypography.body())
                        .foregroundColor(BreachColors.textMuted)

                    Spacer()
                }
                .padding(.vertical, BreachSpacing.md)
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

// MARK: - Difficulty Row

struct DifficultyRow: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let isLocked: Bool
    var starsEarned = 0
    let action: () -> Void

    private var rowColor: Color {
        switch difficulty {
        case .easy: BreachColors.tierEasy
        case .medium: BreachColors.tierMedium
        case .hard: BreachColors.tierHard
        case .expert: BreachColors.tierExpert
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: BreachSpacing.md) {
                // Left color indicator bar
                Rectangle()
                    .fill(isLocked ? BreachColors.textMuted : rowColor)
                    .frame(width: 3, height: 40)

                difficultyInfo

                Spacer()

                if isLocked {
                    lockedLabel
                } else {
                    specLabel
                }
            }
            .padding(.vertical, BreachSpacing.xs)
            .background(
                isSelected && !isLocked
                    ? rowColor.opacity(0.1)
                    : Color.clear
            )
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.5 : 1.0)
    }

    private var difficultyInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(difficulty.displayName.uppercased())
                .font(BreachTypography.caption())
                .foregroundColor(
                    isLocked ? BreachColors.textMuted : (isSelected ? rowColor : BreachColors.textPrimary)
                )

            if !isLocked {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < min(starsEarned, 3) ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundColor(
                                i < min(starsEarned, 3) ? BreachColors.starFilled : BreachColors.starEmpty
                            )
                    }
                }
            }
        }
    }

    private var lockedLabel: some View {
        HStack(spacing: BreachSpacing.xs) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
            Text("LOCKED")
                .font(BreachTypography.caption(9))
        }
        .foregroundColor(BreachColors.textMuted)
        .padding(.trailing, BreachSpacing.sm)
    }

    private var specLabel: some View {
        HStack(spacing: BreachSpacing.xs) {
            Text("\(difficulty.sequenceCount) SEQ")
                .font(BreachTypography.caption(9))
            Text("\u{2022}")
                .font(BreachTypography.caption(9))
            Text("\(difficulty.bufferSize) BUF")
                .font(BreachTypography.caption(9))
        }
        .foregroundColor(BreachColors.textMuted)
        .padding(.trailing, BreachSpacing.sm)
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .menu).ignoresSafeArea()
        NavigationStack {
            ModeConfigView(mode: .standard)
        }
    }
    .environment(BackgroundStateManager())
    .environment(TransitionManager())
}
