import SwiftUI

struct GridRushHeaderView: View {
    let timeRemaining: Int
    let gridNumber: Int
    let score: Int

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var criticalPulse = false

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

    private var isCritical: Bool {
        timeRemaining <= 10
    }

    var body: some View {
        VStack(spacing: 0) {
            timerColor.frame(height: 2)
                .shadow(color: timerColor.opacity(0.6), radius: 4, y: 2)

            HStack(spacing: 0) {
                gridSection
                verticalDivider
                timerSection
                verticalDivider
                scoreSection
            }
            .padding(.vertical, BreachSpacing.md)
        }
        .background(headerBackground)
        .overlay(headerBorder)
        .onChange(of: isCritical) { newValue in
            if newValue {
                startCriticalPulse()
            } else {
                withAnimation(nil) { criticalPulse = false }
            }
        }
        .onAppear {
            if isCritical { startCriticalPulse() }
        }
    }

    // MARK: - Sections

    private var gridSection: some View {
        VStack(spacing: 2) {
            Text("GRID")
                .font(BreachTypography.caption(10))
                .foregroundColor(BreachColors.textMuted)
            Text("#\(gridNumber)")
                .font(BreachTypography.heading(isWide ? 28 : 24))
                .foregroundColor(BreachColors.accent)
        }
        .frame(maxWidth: .infinity)
    }

    private var timerSection: some View {
        VStack(spacing: 2) {
            Text("TIME")
                .font(BreachTypography.caption(10))
                .foregroundColor(BreachColors.textMuted)
            Text(formatTime(timeRemaining))
                .font(BreachTypography.title(isWide ? 42 : 36))
                .foregroundColor(timerColor)
                .shadow(
                    color: timerColor.opacity(0.5),
                    radius: criticalPulse ? 12 : 5
                )
        }
        .frame(maxWidth: .infinity)
    }

    private var scoreSection: some View {
        VStack(spacing: 2) {
            Text("SCORE")
                .font(BreachTypography.caption(10))
                .foregroundColor(BreachColors.textMuted)
            Text("\(score)")
                .font(BreachTypography.heading(isWide ? 28 : 24))
                .foregroundColor(BreachColors.accentHighlight)
        }
        .frame(maxWidth: .infinity)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(timerColor.opacity(0.2))
            .frame(width: 1, height: 40)
    }

    // MARK: - Background & Border

    private var headerBackground: some View {
        ZStack {
            BreachColors.surfacePrimary.opacity(0.9)
            LinearGradient(
                colors: [timerColor.opacity(0.1), timerColor.opacity(0.02), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var headerBorder: some View {
        Rectangle()
            .stroke(
                timerColor.opacity(criticalPulse ? 0.5 : 0.25),
                lineWidth: 1
            )
    }

    private func startCriticalPulse() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            criticalPulse = true
        }
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
