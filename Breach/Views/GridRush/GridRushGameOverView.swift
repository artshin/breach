import SwiftUI

struct GridRushGameOverView: View {
    let rushState: GridRushState
    let onPlayAgain: () -> Void
    let onGoHome: () -> Void

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isWide: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: BreachSpacing.xl) {
                // Title
                VStack(spacing: BreachSpacing.sm) {
                    Text("TIME'S UP")
                        .font(BreachTypography.title(isWide ? 42 : 36))
                        .foregroundColor(BreachColors.red)
                        .shadow(color: BreachColors.red.opacity(0.5), radius: 10)

                    Text("RUN COMPLETE")
                        .font(BreachTypography.caption(14))
                        .foregroundColor(BreachColors.textMuted)
                }

                // Stats grid
                VStack(spacing: BreachSpacing.lg) {
                    // Score (prominent)
                    VStack(spacing: BreachSpacing.xs) {
                        Text("FINAL SCORE")
                            .font(BreachTypography.caption(12))
                            .foregroundColor(BreachColors.textMuted)
                        Text("\(rushState.totalScore)")
                            .font(BreachTypography.title(isWide ? 56 : 48))
                            .foregroundColor(BreachColors.yellow)
                            .shadow(color: BreachColors.yellow.opacity(0.5), radius: 10)
                    }

                    // Stats row
                    HStack(spacing: BreachSpacing.xl) {
                        StatColumn(label: "GRIDS", value: "\(rushState.gridsCompleted)", color: BreachColors.cyan)
                        StatColumn(label: "PERFECTS", value: "\(rushState.perfectClears)", color: BreachColors.green)
                        StatColumn(
                            label: "BEST STREAK",
                            value: "\(rushState.bestPerfectStreak)",
                            color: BreachColors.orange
                        )
                    }
                }
                .padding(BreachSpacing.xl)
                .background(BreachColors.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: BreachRadius.md)
                        .stroke(BreachColors.borderSecondary, lineWidth: 1)
                )
                .cornerRadius(BreachRadius.md)

                // Buttons
                VStack(spacing: BreachSpacing.md) {
                    BreachButton("PLAY AGAIN", color: BreachColors.cyan, action: onPlayAgain)
                    BreachOutlineButton("HOME", color: BreachColors.cyan, action: onGoHome)
                }
            }
            .padding(BreachSpacing.xl)
            .frame(maxWidth: isWide ? 500 : .infinity)
        }
    }
}

struct StatColumn: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: BreachSpacing.xs) {
            Text(value)
                .font(BreachTypography.heading(24))
                .foregroundColor(color)
            Text(label)
                .font(BreachTypography.caption(10))
                .foregroundColor(BreachColors.textMuted)
        }
        .frame(minWidth: 80)
    }
}

#Preview {
    GridRushGameOverView(
        rushState: {
            var state = GridRushState()
            state.gridsCompleted = 7
            state.totalScore = 4250
            state.perfectClears = 4
            state.bestPerfectStreak = 3
            state.isGameOver = true
            return state
        }(),
        onPlayAgain: {},
        onGoHome: {}
    )
}
