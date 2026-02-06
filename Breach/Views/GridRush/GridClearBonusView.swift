import SwiftUI

struct GridClearBonusView: View {
    let result: GridClearResult

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: BreachSpacing.md) {
            // Main bonus text
            Text("+\(result.totalBonus)s")
                .font(BreachTypography.title(48))
                .foregroundColor(BreachColors.green)
                .shadow(color: BreachColors.green.opacity(0.5), radius: 15)

            // Breakdown
            VStack(spacing: BreachSpacing.xs) {
                if result.baseBonus > 0 {
                    BonusLineView(label: "CLEAR", value: "+\(result.baseBonus)s", color: BreachColors.cyan)
                }

                if result.isPerfect {
                    BonusLineView(label: "PERFECT", value: "+\(result.perfectBonus)s", color: BreachColors.yellow)
                }

                if result.movesSaved > 0 {
                    BonusLineView(label: "UNDER PAR", value: "+\(result.underParBonus)s", color: BreachColors.green)
                }

                if result.wasSpeedClear {
                    BonusLineView(label: "SPEED", value: "+\(result.speedBonus)s", color: BreachColors.pink)
                }
            }
        }
        .padding(BreachSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: BreachRadius.lg)
                .fill(BreachColors.panelBackground.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: BreachRadius.lg)
                .stroke(BreachColors.green.opacity(0.5), lineWidth: 2)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.5)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}

struct BonusLineView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(BreachTypography.caption(12))
                .foregroundColor(BreachColors.textMuted)

            Spacer()

            Text(value)
                .font(BreachTypography.body(14))
                .foregroundColor(color)
        }
        .frame(width: 150)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        GridClearBonusView(
            result: GridClearResult(
                baseBonus: 12,
                perfectBonus: 5,
                underParBonus: 4,
                speedBonus: 3,
                isPerfect: true,
                movesSaved: 2,
                wasSpeedClear: true
            )
        )
    }
}
