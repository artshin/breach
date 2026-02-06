import SwiftUI

struct GridRushHeaderView: View {
    let timeRemaining: Int
    let gridNumber: Int
    let score: Int

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var isWide: Bool {
        horizontalSizeClass == .regular
    }

    private var timerColor: Color {
        if timeRemaining <= 10 {
            return BreachColors.timerCritical
        } else if timeRemaining <= 20 {
            return BreachColors.timerWarning
        }
        return BreachColors.timerSafe
    }

    var body: some View {
        HStack(spacing: BreachSpacing.lg) {
            // Grid counter
            VStack(spacing: 2) {
                Text("GRID")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
                Text("#\(gridNumber)")
                    .font(BreachTypography.heading(isWide ? 28 : 24))
                    .foregroundColor(BreachColors.accent)
            }
            .frame(minWidth: 70)

            Spacer()

            // Timer (center, prominent)
            VStack(spacing: 2) {
                Text("TIME")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
                Text(formatTime(timeRemaining))
                    .font(BreachTypography.title(isWide ? 42 : 36))
                    .foregroundColor(timerColor)
                    .shadow(color: timerColor.opacity(0.5), radius: timeRemaining <= 10 ? 10 : 5)
                    .animation(.easeInOut(duration: 0.3), value: timeRemaining <= 10)
            }

            Spacer()

            // Score
            VStack(spacing: 2) {
                Text("SCORE")
                    .font(BreachTypography.caption(10))
                    .foregroundColor(BreachColors.textMuted)
                Text("\(score)")
                    .font(BreachTypography.heading(isWide ? 28 : 24))
                    .foregroundColor(BreachColors.accentHighlight)
            }
            .frame(minWidth: 70)
        }
        .padding(.horizontal, BreachSpacing.lg)
        .padding(.vertical, BreachSpacing.md)
        .breachGlass(tint: timerColor, opacity: 0.05)
        .overlay(
            Rectangle()
                .stroke(timerColor.opacity(0.3), lineWidth: 1)
        )
        .breachBevel(color: timerColor)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    ZStack {
        BreachColors.background.ignoresSafeArea()
        VStack(spacing: 20) {
            GridRushHeaderView(timeRemaining: 45, gridNumber: 3, score: 1250)
            GridRushHeaderView(timeRemaining: 15, gridNumber: 5, score: 2500)
            GridRushHeaderView(timeRemaining: 5, gridNumber: 8, score: 4200)
        }
        .padding()
    }
}
