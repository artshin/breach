import SwiftUI

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let highlightColor: Color
}

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0

    let onComplete: () -> Void

    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "WELCOME, NETRUNNER",
            description: "Breach Protocol is a hacking minigame. Your goal is to complete sequences by selecting codes from the matrix.",
            icon: "terminal",
            highlightColor: BreachColors.cyan
        ),
        TutorialStep(
            title: "THE MATRIX",
            description: "The matrix contains hex codes. You must select codes in a specific pattern to breach the system.",
            icon: "square.grid.3x3",
            highlightColor: BreachColors.cyan
        ),
        TutorialStep(
            title: "ROW & COLUMN RULES",
            description: "You alternate between selecting from rows and columns. Start by picking from the top row, then pick from that column, and so on.",
            icon: "arrow.left.and.right",
            highlightColor: BreachColors.yellow
        ),
        TutorialStep(
            title: "THE BUFFER",
            description: "Each code you select goes into your buffer. The buffer has limited space - plan your moves carefully!",
            icon: "tray",
            highlightColor: BreachColors.yellow
        ),
        TutorialStep(
            title: "TARGET SEQUENCES",
            description: "Complete sequences by selecting their codes in order. Codes don't need to be consecutive - just in the right order.",
            icon: "list.number",
            highlightColor: BreachColors.pink
        ),
        TutorialStep(
            title: "EARN STARS",
            description: "⭐ 1 star: Complete at least one sequence\n⭐⭐ 2 stars: Complete all sequences\n⭐⭐⭐ 3 stars: Complete all at or under par",
            icon: "star.fill",
            highlightColor: BreachColors.yellow
        ),
        TutorialStep(
            title: "READY TO BREACH",
            description: "Highlighted cells show valid moves. Yellow borders indicate codes that advance a sequence. Good luck, netrunner!",
            icon: "bolt.fill",
            highlightColor: BreachColors.green
        )
    ]

    var body: some View {
        ZStack {
            BreachColors.background
                .ignoresSafeArea()

            VStack(spacing: BreachSpacing.xl) {
                // Progress indicator
                progressIndicator

                Spacer()

                // Step content
                stepContent

                Spacer()

                // Navigation buttons
                navigationButtons
            }
            .padding(BreachSpacing.xl)
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: BreachSpacing.xs) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? steps[currentStep].highlightColor : BreachColors.textMuted.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step Content

    private var stepContent: some View {
        let step = steps[currentStep]

        return VStack(spacing: BreachSpacing.xl) {
            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 64))
                .foregroundColor(step.highlightColor)
                .shadow(color: step.highlightColor.opacity(0.5), radius: 20)

            // Title
            Text(step.title)
                .font(BreachTypography.heading(24))
                .foregroundColor(step.highlightColor)
                .multilineTextAlignment(.center)

            // Description
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
            // Main action button
            if currentStep < steps.count - 1 {
                BreachButton("NEXT", color: steps[currentStep].highlightColor) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
            } else {
                BreachButton("START PLAYING", color: BreachColors.green) {
                    TutorialManager.shared.markTutorialComplete()
                    onComplete()
                    dismiss()
                }
            }

            // Skip button
            if currentStep < steps.count - 1 {
                Button(action: {
                    TutorialManager.shared.markTutorialComplete()
                    onComplete()
                    dismiss()
                }) {
                    Text("SKIP TUTORIAL")
                        .font(BreachTypography.caption())
                        .foregroundColor(BreachColors.textMuted)
                }
                .padding(.top, BreachSpacing.sm)
            }
        }
    }
}

// MARK: - Tutorial Manager

@MainActor
class TutorialManager: ObservableObject {
    static let shared = TutorialManager()

    private let hasSeenTutorialKey = "tutorial.hasSeenTutorial"

    @Published var shouldShowTutorial: Bool

    private init() {
        self.shouldShowTutorial = !UserDefaults.standard.bool(forKey: hasSeenTutorialKey)
    }

    func markTutorialComplete() {
        UserDefaults.standard.set(true, forKey: hasSeenTutorialKey)
        shouldShowTutorial = false
    }

    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: hasSeenTutorialKey)
        shouldShowTutorial = true
    }
}

#Preview {
    TutorialView(onComplete: {})
}
