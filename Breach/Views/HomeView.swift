import SwiftUI

struct HomeView: View {
    enum Sheet: Identifiable {
        case settings, stats, tutorial

        var id: String {
            "\(self)"
        }
    }

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject private var backgroundState: BackgroundStateManager
    @EnvironmentObject private var transitionManager: TransitionManager
    @ObservedObject private var tutorialManager = TutorialManager.shared
    @State private var selectedMode: GameMode = .standard
    @State private var showModeConfig = false
    @State private var activeSheet: Sheet?

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            titleSection

            Spacer()

            heroSection
                .padding(.horizontal, isWideLayout ? BreachSpacing.xxl : BreachSpacing.lg)

            Spacer()
                .frame(height: BreachSpacing.xxl)

            bottomBar
                .padding(.bottom, BreachSpacing.xl)
        }
        .navigationDestination(isPresented: $showModeConfig) {
            ModeConfigView(mode: selectedMode)
        }
        .sheet(
            item: $activeSheet,
            onDismiss: {
                if tutorialManager.shouldShowTutorial {
                    activeSheet = .tutorial
                }
            },
            content: { sheet in
                switch sheet {
                case .settings:
                    SettingsView()
                case .stats:
                    StatsView()
                case .tutorial:
                    TutorialView(onComplete: {})
                }
            }
        )
        .clearNavigationBackground()
        .onAppear {
            backgroundState.state = .menu
            if tutorialManager.shouldShowTutorial {
                activeSheet = .tutorial
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        let titleSize: CGFloat = isWideLayout ? 56 : 42
        let subtitleSize: CGFloat = isWideLayout ? 24 : 18

        return VStack(spacing: BreachSpacing.sm) {
            HStack(spacing: BreachSpacing.sm) {
                Rectangle()
                    .fill(BreachColors.accent.opacity(0.3))
                    .frame(height: 1)
                Text("//")
                    .font(BreachTypography.caption())
                    .foregroundColor(BreachColors.accent.opacity(0.5))
                Rectangle()
                    .fill(BreachColors.accent.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, BreachSpacing.xxl)
            .frame(maxWidth: 400)

            GlowingText("BREACH", font: BreachTypography.title(titleSize))

            Text("PROTOCOL")
                .font(BreachTypography.heading(subtitleSize))
                .foregroundColor(BreachColors.accent.opacity(0.7))
                .tracking(isWideLayout ? 12 : 8)

            HStack(spacing: BreachSpacing.sm) {
                Rectangle()
                    .fill(BreachColors.accent.opacity(0.3))
                    .frame(height: 1)
                Text("v1.0")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
                Rectangle()
                    .fill(BreachColors.accent.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal, BreachSpacing.xxl)
            .frame(maxWidth: 400)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        HStack(spacing: BreachSpacing.md) {
            HeroModeButton(
                title: "STANDARD",
                subtitle: "Breach the protocol",
                icon: "terminal",
                tag: "SYS://01",
                color: BreachColors.accent
            ) {
                navigateToMode(.standard)
            }

            HeroModeButton(
                title: "GRID RUSH",
                subtitle: "Race the clock",
                icon: "bolt.fill",
                tag: "SYS://02",
                color: BreachColors.accentHighlight
            ) {
                navigateToMode(.gridRush)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: BreachSpacing.sm) {
            HStack(spacing: BreachSpacing.sm) {
                Rectangle().fill(BreachColors.borderMuted).frame(height: 1)
                Text("SYS")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(BreachColors.textMuted)
                Rectangle().fill(BreachColors.borderMuted).frame(height: 1)
            }
            .frame(maxWidth: 200)

            HStack(spacing: BreachSpacing.xl) {
                SystemBarButton(icon: "chart.bar", label: "STATS", color: BreachColors.accentSecondary) {
                    activeSheet = .stats
                }
                SystemBarButton(icon: "gearshape", label: "CONFIG", color: BreachColors.textSecondary) {
                    activeSheet = .settings
                }
            }
        }
    }

    private func navigateToMode(_ mode: GameMode) {
        transitionManager.transition {
            selectedMode = mode
            showModeConfig = true
        }
    }
}

// MARK: - Hero Mode Button

struct HeroModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let tag: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                color.frame(height: 3)
                    .shadow(color: color.opacity(0.6), radius: 6, y: 2)

                VStack(spacing: BreachSpacing.md) {
                    HStack {
                        Text(tag)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(color.opacity(0.5))
                        Spacer()
                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                            .shadow(color: color, radius: 4)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: color.opacity(0.7), radius: 12)
                        .shadow(color: color.opacity(0.3), radius: 25)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)

                    color.opacity(0.25).frame(height: 1)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(BreachTypography.code(14))
                            .foregroundColor(color)
                        Text(subtitle)
                            .font(BreachTypography.caption(9))
                            .foregroundColor(BreachColors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(BreachSpacing.md)
            }
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    BreachColors.surfacePrimary.opacity(0.85)
                    LinearGradient(
                        colors: [color.opacity(0.12), color.opacity(0.03), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .overlay(
                Rectangle()
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - System Bar Button

struct SystemBarButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .foregroundColor(color)
            .padding(.horizontal, BreachSpacing.md)
            .padding(.vertical, BreachSpacing.sm)
            .background(color.opacity(0.06))
            .overlay(
                Rectangle()
                    .stroke(color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Difficulty Card

struct DifficultyCard: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let difficulty: Difficulty
    let isSelected: Bool
    let isLocked: Bool
    var starsEarned = 0
    let action: () -> Void

    private var isWide: Bool {
        horizontalSizeClass == .regular
    }

    private var cardColor: Color {
        switch difficulty {
        case .easy: BreachColors.tierEasy
        case .medium: BreachColors.tierMedium
        case .hard: BreachColors.tierHard
        case .expert: BreachColors.tierExpert
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: BreachSpacing.sm) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: isWide ? 32 : 24))
                        .foregroundColor(BreachColors.textMuted)
                } else {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < min(starsEarned, 3) ? "star.fill" : "star")
                                .font(.system(size: isWide ? 14 : 10))
                                .foregroundColor(
                                    i < min(starsEarned, 3) ? BreachColors.starFilled : BreachColors.starEmpty
                                )
                        }
                    }
                }

                Text(difficulty.displayName.uppercased())
                    .font(BreachTypography.caption(isWide ? 14 : 12))
                    .foregroundColor(
                        isLocked ? BreachColors.textMuted : (isSelected ? cardColor : BreachColors.textPrimary)
                    )

                if isLocked {
                    Text("LOCKED")
                        .font(BreachTypography.caption(isWide ? 10 : 8))
                        .foregroundColor(BreachColors.textMuted)
                } else {
                    HStack(spacing: BreachSpacing.xs) {
                        Text("\(difficulty.sequenceCount) SEQ")
                            .font(BreachTypography.caption(isWide ? 11 : 9))
                        Text("\u{2022}")
                        Text("\(difficulty.bufferSize) BUF")
                            .font(BreachTypography.caption(isWide ? 11 : 9))
                    }
                    .foregroundColor(BreachColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isWide ? BreachSpacing.xl : BreachSpacing.lg)
            .background(isSelected && !isLocked ? cardColor.opacity(0.15) : BreachColors.surfacePrimary)
            .overlay(
                Rectangle()
                    .stroke(
                        isSelected && !isLocked ? cardColor : BreachColors.borderSecondary,
                        lineWidth: isSelected && !isLocked ? 2 : 1
                    )
            )
            .breachBevel(color: isSelected && !isLocked ? cardColor : BreachColors.accent)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .disabled(isLocked)
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .menu).ignoresSafeArea()
        NavigationStack {
            HomeView()
        }
    }
    .environmentObject(BackgroundStateManager())
    .environmentObject(TransitionManager())
    .onAppear {
        GameSettings.shared.backgroundStyle = .circuitTraces
    }
}
