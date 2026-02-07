import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var transitionManager: TransitionManager
    @ObservedObject private var settings = GameSettings.shared

    var body: some View {
        VStack(spacing: BreachSpacing.lg) {
            headerSection

            ScrollView {
                VStack(spacing: BreachSpacing.lg) {
                    overallStatsSection
                    gridRushStatsSection
                    difficultyStatsSection
                }
                .padding(.horizontal, BreachSpacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .clearNavigationBackground()
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button {
                transitionManager.transition { dismiss() }
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

            Text("STATISTICS")
                .font(BreachTypography.heading(16))
                .foregroundColor(BreachColors.accent)

            Spacer()

            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, BreachSpacing.lg)
        .padding(.top, BreachSpacing.lg)
    }

    // MARK: - Overall Stats

    private var overallStatsSection: some View {
        VStack(spacing: BreachSpacing.md) {
            BreachSectionHeader("OVERALL")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BreachSpacing.md) {
                StatCard(
                    title: "GAMES",
                    value: "\(settings.totalGamesPlayed)",
                    icon: "gamecontroller",
                    color: BreachColors.accent
                )

                StatCard(
                    title: "STARS",
                    value: "\(settings.totalStarsEarned)",
                    icon: "star.fill",
                    color: BreachColors.accentHighlight
                )

                StatCard(
                    title: "WIN RATE",
                    value: String(format: "%.0f%%", settings.overallWinRate * 100),
                    icon: "percent",
                    color: BreachColors.success
                )

                StatCard(
                    title: "BEST STREAK",
                    value: "\(settings.bestOverallStreak)",
                    icon: "flame",
                    color: BreachColors.accentSecondary
                )
            }
        }
    }

    // MARK: - Grid Rush Stats

    private var gridRushStatsSection: some View {
        VStack(spacing: BreachSpacing.md) {
            BreachSectionHeader("GRID RUSH", color: BreachColors.accentHighlight)

            let stats = settings.gridRushStats

            if stats.totalRuns > 0 {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: BreachSpacing.md) {
                    StatCard(
                        title: "RUNS",
                        value: "\(stats.totalRuns)",
                        icon: "arrow.clockwise",
                        color: BreachColors.accentHighlight
                    )

                    StatCard(
                        title: "HIGH SCORE",
                        value: "\(stats.highScore)",
                        icon: "trophy",
                        color: BreachColors.accentHighlight
                    )

                    StatCard(
                        title: "BEST GRIDS",
                        value: "\(stats.bestGridsCleared)",
                        icon: "square.grid.3x3",
                        color: BreachColors.accent
                    )

                    StatCard(
                        title: "TOTAL GRIDS",
                        value: "\(stats.totalGridsCleared)",
                        icon: "square.grid.2x2",
                        color: BreachColors.accent
                    )
                }

                // Additional stats row
                HStack(spacing: BreachSpacing.lg) {
                    VStack(spacing: BreachSpacing.xs) {
                        Text("\(stats.totalPerfectClears)")
                            .font(BreachTypography.heading(20))
                            .foregroundColor(BreachColors.success)
                        Text("PERFECTS")
                            .font(BreachTypography.caption(10))
                            .foregroundColor(BreachColors.textMuted)
                    }

                    VStack(spacing: BreachSpacing.xs) {
                        Text("\(stats.bestPerfectStreak)")
                            .font(BreachTypography.heading(20))
                            .foregroundColor(BreachColors.accentSecondary)
                        Text("BEST STREAK")
                            .font(BreachTypography.caption(10))
                            .foregroundColor(BreachColors.textMuted)
                    }

                    if stats.totalRuns > 0 {
                        VStack(spacing: BreachSpacing.xs) {
                            let avgGrids = Double(stats.totalGridsCleared) / Double(stats.totalRuns)
                            Text(String(format: "%.1f", avgGrids))
                                .font(BreachTypography.heading(20))
                                .foregroundColor(BreachColors.warning)
                            Text("AVG GRIDS")
                                .font(BreachTypography.caption(10))
                                .foregroundColor(BreachColors.textMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(BreachSpacing.md)
                .breachGlass()
                .overlay(
                    Rectangle()
                        .stroke(BreachColors.borderSecondary, lineWidth: 1)
                )
                .breachBevel()
            } else {
                // No runs yet
                VStack(spacing: BreachSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 32))
                        .foregroundColor(BreachColors.accentHighlight.opacity(0.5))

                    Text("No Grid Rush runs yet")
                        .font(BreachTypography.body())
                        .foregroundColor(BreachColors.textMuted)

                    Text("Clear grids against the clock!")
                        .font(BreachTypography.caption(11))
                        .foregroundColor(BreachColors.textMuted.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(BreachSpacing.xl)
                .breachGlass()
                .overlay(
                    Rectangle()
                        .stroke(BreachColors.borderSecondary, lineWidth: 1)
                )
                .breachBevel()
            }
        }
    }

    // MARK: - Difficulty Stats

    private var difficultyStatsSection: some View {
        VStack(spacing: BreachSpacing.md) {
            BreachSectionHeader("BY DIFFICULTY")

            ForEach(Difficulty.allCases) { difficulty in
                DifficultyStatsRow(
                    difficulty: difficulty,
                    stats: settings.stats(for: difficulty),
                    isUnlocked: settings.isDifficultyUnlocked(difficulty)
                )
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: BreachSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(BreachTypography.heading(24))
                .foregroundColor(BreachColors.textPrimary)

            Text(title)
                .font(BreachTypography.caption(10))
                .foregroundColor(BreachColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BreachSpacing.lg)
        .breachGlass()
        .overlay(
            Rectangle()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .breachBevel()
    }
}

// MARK: - Difficulty Stats Row

struct DifficultyStatsRow: View {
    let difficulty: Difficulty
    let stats: DifficultyStats
    let isUnlocked: Bool

    private var difficultyColor: Color {
        switch difficulty {
        case .easy: BreachColors.tierEasy
        case .medium: BreachColors.tierMedium
        case .hard: BreachColors.tierHard
        case .expert: BreachColors.tierExpert
        }
    }

    var body: some View {
        BreachPanel {
            HStack(spacing: BreachSpacing.md) {
                // Difficulty indicator
                VStack(spacing: BreachSpacing.xs) {
                    Text(difficulty.displayName.uppercased())
                        .font(BreachTypography.caption())
                        .foregroundColor(isUnlocked ? difficultyColor : BreachColors.textMuted)

                    // Stars
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < min(stats.totalStars, 3) ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(
                                    i < min(stats.totalStars, 3) ? BreachColors.starFilled : BreachColors.starEmpty
                                )
                        }
                    }
                }
                .frame(width: 80)

                if isUnlocked {
                    // Stats
                    HStack(spacing: BreachSpacing.lg) {
                        StatItem(label: "PLAYED", value: "\(stats.gamesPlayed)")
                        StatItem(label: "WIN %", value: String(format: "%.0f%%", stats.winRate * 100))
                        StatItem(label: "STREAK", value: "\(stats.bestStreak)")
                    }
                } else {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundColor(BreachColors.textMuted)
                    Spacer()
                }
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(BreachTypography.body(14))
                .foregroundColor(BreachColors.textPrimary)
            Text(label)
                .font(BreachTypography.caption(8))
                .foregroundColor(BreachColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .menu).ignoresSafeArea()
        NavigationStack {
            StatsView()
        }
    }
    .environmentObject(BackgroundStateManager())
    .environmentObject(TransitionManager())
}
