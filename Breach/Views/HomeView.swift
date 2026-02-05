import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject private var settings = GameSettings.shared
    @ObservedObject private var tutorialManager = TutorialManager.shared
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showingGame = false
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var showingTutorial = false

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            // Animated background
            BackgroundView(state: .menu)
                .ignoresSafeArea()

            VStack(spacing: isWideLayout ? BreachSpacing.xxl : BreachSpacing.xl) {
                Spacer()

                // Logo / Title
                titleSection

                Spacer()

                // Difficulty Selection
                difficultySection
                    .frame(maxWidth: isWideLayout ? 600 : .infinity)

                Spacer()

                // Play Button
                playSection

                Spacer()

                // Bottom buttons
                bottomSection
            }
            .padding(.horizontal, isWideLayout ? BreachSpacing.xxl : BreachSpacing.xl)
            .padding(.bottom, BreachSpacing.xl)
        }
        .navigationDestination(isPresented: $showingGame) {
            GameView(difficulty: selectedDifficulty)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView(onComplete: {})
        }
        .onAppear {
            if tutorialManager.shouldShowTutorial {
                showingTutorial = true
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        let titleSize: CGFloat = isWideLayout ? 56 : 42
        let subtitleSize: CGFloat = isWideLayout ? 24 : 18

        return VStack(spacing: BreachSpacing.sm) {
            // Decorative line
            HStack(spacing: BreachSpacing.sm) {
                Rectangle()
                    .fill(BreachColors.cyan.opacity(0.3))
                    .frame(height: 1)
                Text("//")
                    .font(BreachTypography.caption())
                    .foregroundColor(BreachColors.cyan.opacity(0.5))
                Rectangle()
                    .fill(BreachColors.cyan.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, BreachSpacing.xxl)
            .frame(maxWidth: 400)

            // Main title
            GlowingText("BREACH", font: BreachTypography.title(titleSize))

            Text("PROTOCOL")
                .font(BreachTypography.heading(subtitleSize))
                .foregroundColor(BreachColors.cyan.opacity(0.7))
                .tracking(isWideLayout ? 12 : 8)

            // Decorative line
            HStack(spacing: BreachSpacing.sm) {
                Rectangle()
                    .fill(BreachColors.cyan.opacity(0.3))
                    .frame(height: 1)
                Text("v1.0")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
                Rectangle()
                    .fill(BreachColors.cyan.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, BreachSpacing.xxl)
            .frame(maxWidth: 400)
        }
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
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
        }
    }

    // MARK: - Play Section

    private var playSection: some View {
        VStack(spacing: BreachSpacing.md) {
            BreachButton("INITIATE BREACH", color: BreachColors.cyan) {
                showingGame = true
            }

            Text("Buffer: \(selectedDifficulty.bufferSize) | Grid: \(selectedDifficulty.gridSize)x\(selectedDifficulty.gridSize)")
                .font(BreachTypography.caption(10))
                .foregroundColor(BreachColors.textMuted)
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        HStack(spacing: BreachSpacing.lg) {
            BreachIconButton("chart.bar") {
                showingStats = true
            }

            BreachIconButton("gearshape") {
                showingSettings = true
            }
        }
    }
}

// MARK: - Difficulty Card

struct DifficultyCard: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let difficulty: Difficulty
    let isSelected: Bool
    let isLocked: Bool
    var starsEarned: Int = 0
    let action: () -> Void

    private var isWide: Bool {
        horizontalSizeClass == .regular
    }

    private var cardColor: Color {
        switch difficulty {
        case .easy: return BreachColors.green
        case .medium: return BreachColors.yellow
        case .hard: return BreachColors.orange
        case .expert: return BreachColors.red
        }
    }

    private var difficultyIcon: String {
        switch difficulty {
        case .easy: return "1.circle"
        case .medium: return "2.circle"
        case .hard: return "3.circle"
        case .expert: return "4.circle"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: BreachSpacing.sm) {
                // Icon or lock
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: isWide ? 32 : 24))
                        .foregroundColor(BreachColors.textMuted)
                } else {
                    // Stars indicator
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < min(starsEarned, 3) ? "star.fill" : "star")
                                .font(.system(size: isWide ? 14 : 10))
                                .foregroundColor(i < min(starsEarned, 3) ? .yellow : BreachColors.textMuted.opacity(0.3))
                        }
                    }
                }

                // Name
                Text(difficulty.displayName.uppercased())
                    .font(BreachTypography.caption(isWide ? 14 : 12))
                    .foregroundColor(isLocked ? BreachColors.textMuted : (isSelected ? cardColor : BreachColors.textPrimary))

                // Stats or lock message
                if isLocked {
                    Text("LOCKED")
                        .font(BreachTypography.caption(isWide ? 10 : 8))
                        .foregroundColor(BreachColors.textMuted)
                } else {
                    HStack(spacing: BreachSpacing.xs) {
                        Text("\(difficulty.sequenceCount) SEQ")
                            .font(BreachTypography.caption(isWide ? 11 : 9))
                        Text("•")
                        Text("\(difficulty.bufferSize) BUF")
                            .font(BreachTypography.caption(isWide ? 11 : 9))
                    }
                    .foregroundColor(BreachColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isWide ? BreachSpacing.xl : BreachSpacing.lg)
            .background(isSelected && !isLocked ? cardColor.opacity(0.15) : BreachColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: BreachRadius.md)
                    .stroke(isSelected && !isLocked ? cardColor : BreachColors.borderSecondary, lineWidth: isSelected && !isLocked ? 2 : 1)
            )
            .cornerRadius(BreachRadius.md)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .disabled(isLocked)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
