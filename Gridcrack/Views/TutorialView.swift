import AppLogService
import SwiftUI

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let highlightColor: Color
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TransitionManager.self) private var transitionManager
    @State private var currentStep = 0

    // swiftlint:disable line_length
    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "WELCOME",
            description: "Gridcrack is a code-cracking puzzle. Your goal is to complete sequences by selecting codes from the grid.",
            icon: "terminal",
            highlightColor: BreachColors.accent
        ),
        TutorialStep(
            title: "THE GRID",
            description: "The grid contains hex codes. You must select codes in a specific pattern to crack the code.",
            icon: "square.grid.3x3",
            highlightColor: BreachColors.accent
        ),
        TutorialStep(
            title: "ROW & COLUMN RULES",
            description: "You alternate between selecting from rows and columns. Start by picking from the top row, then pick from that column, and so on.",
            icon: "arrow.left.and.right",
            highlightColor: BreachColors.accentHighlight
        ),
        TutorialStep(
            title: "THE BUFFER",
            description: "Each code you select goes into your buffer. The buffer has limited space - plan your moves carefully!",
            icon: "tray",
            highlightColor: BreachColors.accentHighlight
        ),
        TutorialStep(
            title: "TARGET SEQUENCES",
            description: "Complete sequences by selecting their codes in order. Codes don't need to be consecutive - just in the right order.",
            icon: "list.number",
            highlightColor: BreachColors.accentSecondary
        ),
        TutorialStep(
            title: "EARN STARS",
            description: "⭐ 1 star: Complete at least one sequence\n⭐⭐ 2 stars: Complete all sequences\n⭐⭐⭐ 3 stars: Complete all at or under par",
            icon: "star.fill",
            highlightColor: BreachColors.accentHighlight
        ),
        TutorialStep(
            title: "START CRACKING",
            description: "Highlighted cells show valid moves. Gold borders indicate codes that advance a sequence. Good luck!",
            icon: "bolt.fill",
            highlightColor: BreachColors.success
        )
    ]
    // swiftlint:enable line_length

    var body: some View {
        VStack(spacing: BreachSpacing.xl) {
            headerSection
            progressIndicator
            Spacer()
            stepContent
            Spacer()
            navigationButtons
        }
        .padding(.horizontal, BreachSpacing.xl)
        .padding(.bottom, BreachSpacing.xl)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .clearNavigationBackground()
        .onAppear {
            Logger.shared.info("Navigate to /tutorial", tags: ["navigation"])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button {
                transitionManager.transition { dismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BreachColors.accent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text("HOW TO PLAY")
                .font(BreachTypography.heading(16))
                .foregroundColor(BreachColors.accent)

            Spacer()

            Color.clear.frame(width: 44, height: 1)
        }
        .padding(.top, BreachSpacing.lg)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: BreachSpacing.xs) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= currentStep
                            ? steps[currentStep].highlightColor
                            : BreachColors.textMuted.opacity(0.3)
                    )
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step Content

    private var stepContent: some View {
        let step = steps[currentStep]

        return VStack(spacing: BreachSpacing.xl) {
            Image(systemName: step.icon)
                .font(.system(size: 64))
                .foregroundColor(step.highlightColor)
                .shadow(color: step.highlightColor.opacity(0.5), radius: 20)

            Text(step.title)
                .font(BreachTypography.heading(24))
                .foregroundColor(step.highlightColor)
                .multilineTextAlignment(.center)

            Text(step.description)
                .font(BreachTypography.body())
                .foregroundColor(BreachColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, BreachSpacing.lg)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: BreachSpacing.md) {
            if currentStep < steps.count - 1 {
                BreachButton("NEXT", color: steps[currentStep].highlightColor) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
            } else {
                BreachButton("DONE", color: BreachColors.success) {
                    transitionManager.transition { dismiss() }
                }
            }

            if currentStep < steps.count - 1 {
                Button {
                    transitionManager.transition { dismiss() }
                } label: {
                    Text("SKIP")
                        .font(BreachTypography.caption())
                        .foregroundColor(BreachColors.textMuted)
                }
                .padding(.top, BreachSpacing.sm)
            }
        }
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .menu).ignoresSafeArea()
        NavigationStack {
            TutorialView()
        }
    }
    .environment(BackgroundStateManager())
    .environment(TransitionManager())
}
