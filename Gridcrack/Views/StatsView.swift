import AppLogService
import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TransitionManager.self) private var transitionManager
    @ObservedObject private var settings = GameSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("STATISTICS", tag: "SYS://STATS") {
                transitionManager.transition { dismiss() }
            }

            ScrollView {
                VStack(spacing: BreachSpacing.xl) {
                    overallStatsSection
                    gridRushStatsSection
                    difficultyStatsSection
                }
                .padding(.horizontal, BreachSpacing.lg)
                .padding(.top, BreachSpacing.lg)
                .padding(.bottom, BreachSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .clearNavigationBackground()
        .onAppear {
            Logger.shared.info("Navigate to /stats", tags: ["navigation"])
        }
    }

    // MARK: - Overall Stats

    private var overallStatsSection: some View {
        VStack(spacing: 0) {
            SectionDivider("OVERALL")
                .padding(.bottom, BreachSpacing.md)

            StatRow(
                icon: "gamecontroller",
                label: "GAMES PLAYED",
                value: "\(settings.totalGamesPlayed)",
                color: BreachColors.accent
            )

            StatRowDivider()

            StatRow(
                icon: "star.fill",
                label: "TOTAL STARS",
                value: "\(settings.totalStarsEarned)",
                color: BreachColors.accentHighlight
            )

            StatRowDivider()

            StatRow(
                icon: "percent",
                label: "WIN RATE",
                value: String(format: "%.0f%%", settings.overallWinRate * 100),
                color: BreachColors.success
            )

            StatRowDivider()

            StatRow(
                icon: "flame",
                label: "BEST STREAK",
                value: "\(settings.bestOverallStreak)",
                color: BreachColors.accentSecondary
            )
        }
    }

    // MARK: - Grid Rush Stats

    private var gridRushStatsSection: some View {
        VStack(spacing: 0) {
            SectionDivider("GRID RUSH", color: BreachColors.accentHighlight)
                .padding(.bottom, BreachSpacing.md)

            let stats = settings.gridRushStats

            if stats.totalRuns > 0 {
                gridRushStatRows(stats: stats)
            } else {
                gridRushEmptyState
            }
        }
    }

    private func gridRushStatRows(stats: GridRushStats) -> some View {
        VStack(spacing: 0) {
            StatRow(
                icon: "trophy",
                label: "HIGH SCORE",
                value: "\(stats.highScore)",
                color: BreachColors.accentHighlight
            )

            StatRowDivider()

            StatRow(
                icon: "arrow.clockwise",
                label: "TOTAL RUNS",
                value: "\(stats.totalRuns)",
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

            gridRushExtraRows(stats: stats)
        }
    }

    private func gridRushExtraRows(stats: GridRushStats) -> some View {
        VStack(spacing: 0) {
            StatRow(
                icon: "square.grid.2x2",
                label: "TOTAL GRIDS",
                value: "\(stats.totalGridsCleared)",
                color: BreachColors.accent
            )

            StatRowDivider()

            StatRow(
                icon: "checkmark.seal",
                label: "PERFECTS",
                value: "\(stats.totalPerfectClears)",
                color: BreachColors.success
            )

            StatRowDivider()

            StatRow(
                icon: "bolt.fill",
                label: "BEST STREAK",
                value: "\(stats.bestPerfectStreak)",
                color: BreachColors.accentSecondary
            )

            StatRowDivider()

            let avgGrids = Double(stats.totalGridsCleared) / Double(stats.totalRuns)
            StatRow(
                icon: "chart.bar",
                label: "AVG GRIDS",
                value: String(format: "%.1f", avgGrids),
                color: BreachColors.warning
            )
        }
    }

    private var gridRushEmptyState: some View {
        HStack(spacing: BreachSpacing.md) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 18))
                .foregroundColor(BreachColors.accentHighlight.opacity(0.4))

            VStack(alignment: .leading, spacing: 2) {
                Text("No Grid Rush runs yet")
                    .font(BreachTypography.body())
                    .foregroundColor(BreachColors.textMuted)

                Text("Clear grids against the clock!")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted.opacity(0.7))
            }

            Spacer()
        }
        .padding(.vertical, BreachSpacing.md)
    }

    // MARK: - Difficulty Stats

    private var difficultyStatsSection: some View {
        VStack(spacing: 0) {
            SectionDivider("BY DIFFICULTY")
                .padding(.bottom, BreachSpacing.md)

            ForEach(Array(Difficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                DifficultyStatsRow(
                    difficulty: difficulty,
                    stats: settings.stats(for: difficulty),
                    isUnlocked: settings.isDifficultyUnlocked(difficulty)
                )

                if index < Difficulty.allCases.count - 1 {
                    StatRowDivider()
                }
            }
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: BreachSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(BreachTypography.caption(11))
                .foregroundColor(BreachColors.textSecondary)

            Spacer()

            Text(value)
                .font(BreachTypography.code(16))
                .foregroundColor(color)
        }
        .padding(.vertical, BreachSpacing.sm)
    }
}

// MARK: - Stat Row Divider

struct StatRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(BreachColors.accent.opacity(0.1))
            .frame(height: 1)
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
        HStack(spacing: BreachSpacing.md) {
            // Left color indicator bar
            Rectangle()
                .fill(isUnlocked ? difficultyColor : BreachColors.textMuted)
                .frame(width: 3, height: 36)

            // Difficulty name + stars
            VStack(alignment: .leading, spacing: 2) {
                Text(difficulty.displayName.uppercased())
                    .font(BreachTypography.caption())
                    .foregroundColor(isUnlocked ? difficultyColor : BreachColors.textMuted)

                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < min(stats.totalStars, 3) ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundColor(
                                i < min(stats.totalStars, 3) ? BreachColors.starFilled : BreachColors.starEmpty
                            )
                    }
                }
            }
            .frame(width: 70, alignment: .leading)

            if isUnlocked {
                HStack(spacing: BreachSpacing.lg) {
                    StatItem(label: "PLAYED", value: "\(stats.gamesPlayed)")
                    StatItem(label: "WIN %", value: String(format: "%.0f%%", stats.winRate * 100))
                    StatItem(label: "STREAK", value: "\(stats.bestStreak)")
                }
            } else {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(BreachColors.textMuted)
                Spacer()
            }
        }
        .padding(.vertical, BreachSpacing.xs)
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
    .environment(BackgroundStateManager())
    .environment(TransitionManager())
}
