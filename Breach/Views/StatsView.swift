import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = GameSettings.shared

    var body: some View {
        ZStack {
            BreachColors.background
                .ignoresSafeArea()

            VStack(spacing: BreachSpacing.lg) {
                // Header
                headerSection

                ScrollView {
                    VStack(spacing: BreachSpacing.lg) {
                        // Overall Stats
                        overallStatsSection

                        // Per-Difficulty Stats
                        difficultyStatsSection
                    }
                    .padding(.horizontal, BreachSpacing.lg)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("STATISTICS")
                .font(BreachTypography.heading())
                .foregroundColor(BreachColors.cyan)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BreachColors.cyan)
                    .frame(width: 32, height: 32)
            }
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
                    color: BreachColors.cyan
                )

                StatCard(
                    title: "STARS",
                    value: "\(settings.totalStarsEarned)",
                    icon: "star.fill",
                    color: BreachColors.yellow
                )

                StatCard(
                    title: "WIN RATE",
                    value: String(format: "%.0f%%", settings.overallWinRate * 100),
                    icon: "percent",
                    color: BreachColors.green
                )

                StatCard(
                    title: "BEST STREAK",
                    value: "\(settings.bestOverallStreak)",
                    icon: "flame",
                    color: BreachColors.orange
                )
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
        .background(BreachColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: BreachRadius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(BreachRadius.md)
    }
}

// MARK: - Difficulty Stats Row

struct DifficultyStatsRow: View {
    let difficulty: Difficulty
    let stats: DifficultyStats
    let isUnlocked: Bool

    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return BreachColors.green
        case .medium: return BreachColors.yellow
        case .hard: return BreachColors.orange
        case .expert: return BreachColors.red
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
                                .foregroundColor(i < min(stats.totalStars, 3) ? .yellow : BreachColors.textMuted.opacity(0.3))
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
    StatsView()
}
