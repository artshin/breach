import SwiftUI

struct GameOverView: View {
    let result: GameResult
    let onNewGame: () -> Void
    var onHome: (() -> Void)?

    // Animation states
    @State private var showBackground = false
    @State private var showContent = false
    @State private var showButtons = false

    private struct ResultData {
        let completed: Int
        let total: Int
        let moves: Int
        let par: Int
    }

    private var resultData: ResultData {
        if case let .finished(completed, total, moves, par) = result {
            return ResultData(completed: completed, total: total, moves: moves, par: par)
        }
        return ResultData(completed: 0, total: 0, moves: 0, par: 0)
    }

    private var stars: Int {
        result.stars
    }

    private var hasAnySuccess: Bool {
        resultData.completed > 0
    }

    private var isOptimal: Bool {
        stars == 3
    }

    private var isFullCompletion: Bool {
        resultData.completed == resultData.total
    }

    var body: some View {
        ZStack {
            // Semi-transparent background with fade
            Color.black.opacity(showBackground ? 0.9 : 0)
                .ignoresSafeArea()
                .animation(.easeIn(duration: 0.3), value: showBackground)

            VStack(spacing: 20) {
                // Stars with animation
                AnimatedStarsView(count: stars, animate: showContent)
                    .padding(.bottom, 8)

                // Title
                Text(titleText)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(titleColor)

                // Subtitle
                Text(subtitleText)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(BreachColors.textSecondary)
                    .multilineTextAlignment(.center)

                // Stats
                VStack(spacing: 12) {
                    // Sequences completed
                    HStack {
                        Text("SEQUENCES")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(BreachColors.accent.opacity(0.7))
                        Spacer()
                        Text("\(resultData.completed)/\(resultData.total)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(hasAnySuccess ? BreachColors.success : BreachColors.danger)
                    }

                    // Moves vs Par
                    HStack {
                        Text("MOVES")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(BreachColors.accent.opacity(0.7))
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(resultData.moves)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(
                                    resultData.moves <= resultData.par ? BreachColors.success : BreachColors.warning
                                )
                            Text("/")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(BreachColors.textSecondary)
                            Text("\(resultData.par)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(BreachColors.accent.opacity(0.7))
                            Text("PAR")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(BreachColors.textSecondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    Rectangle()
                        .stroke(BreachColors.borderSecondary, lineWidth: 1)
                )
                .breachBevel()
                .padding(.horizontal, 20)

                // Action Buttons
                VStack(spacing: BreachSpacing.md) {
                    Button(action: onNewGame) {
                        Text("PLAY AGAIN")
                            .font(BreachTypography.body(16))
                            .fontWeight(.bold)
                            .foregroundColor(buttonColor)
                            .padding(.horizontal, BreachSpacing.xxl)
                            .padding(.vertical, BreachSpacing.md)
                            .frame(minWidth: 160)
                            .breachGlass(tint: buttonColor)
                            .overlay(
                                Rectangle()
                                    .stroke(buttonColor, lineWidth: 1)
                            )
                            .breachBevel(color: buttonColor)
                    }

                    if let onHome {
                        Button(action: onHome) {
                            Text("HOME")
                                .font(BreachTypography.caption())
                                .foregroundColor(BreachColors.accent)
                                .padding(.horizontal, BreachSpacing.lg)
                                .padding(.vertical, BreachSpacing.sm)
                        }
                    }
                }
                .padding(.top, BreachSpacing.lg)
            }
            .padding(BreachSpacing.xxl)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
        }
        .onAppear {
            // Trigger animations in sequence
            showBackground = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showButtons = true
            }
        }
    }

    private var titleText: String {
        switch stars {
        case 3: "PERFECT CRACK"
        case 2: "ACCESS GRANTED"
        case 1: "PARTIAL CRACK"
        default: "CRACK FAILED"
        }
    }

    private var titleColor: Color {
        switch stars {
        case 3: BreachColors.resultOptimal
        case 2: BreachColors.resultGood
        case 1: BreachColors.resultPartial
        default: BreachColors.resultFailed
        }
    }

    private var subtitleText: String {
        switch stars {
        case 3: "Perfect execution!\nAll sequences at or under par."
        case 2: "All sequences completed.\nCan you do it faster?"
        case 1: "Partial success.\nTry to complete all sequences."
        default: "No sequences completed.\nPlan your path carefully."
        }
    }

    private var buttonColor: Color {
        switch stars {
        case 3: BreachColors.resultOptimal
        case 2: BreachColors.resultGood
        case 1: BreachColors.resultPartial
        default: BreachColors.accent
        }
    }
}

struct StarsView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .font(.system(size: 32))
                    .foregroundColor(index < count ? BreachColors.starFilled : BreachColors.starEmpty)
            }
        }
    }
}

struct AnimatedStarsView: View {
    let count: Int
    let animate: Bool

    @State private var starScales: [CGFloat] = [0, 0, 0]
    @State private var starRotations: [Double] = [0, 0, 0]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .font(.system(size: 36))
                    .foregroundColor(index < count ? BreachColors.starFilled : BreachColors.starEmpty)
                    .scaleEffect(starScales[index])
                    .rotationEffect(.degrees(starRotations[index]))
                    .shadow(color: index < count ? BreachColors.starFilled.opacity(0.5) : .clear, radius: 8)
            }
        }
        .onChange(of: animate) { shouldAnimate in
            if shouldAnimate {
                animateStars()
            }
        }
        .onAppear {
            if animate {
                animateStars()
            }
        }
    }

    private func animateStars() {
        for i in 0..<3 {
            let delay = Double(i) * 0.15

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    starScales[i] = i < count ? 1.3 : 1.0
                    starRotations[i] = i < count ? 360 : 0
                }

                // Settle back to normal size
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        starScales[i] = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    GameOverView(
        result: .finished(completedSequences: 2, totalSequences: 2, moves: 4, par: 4),
        onNewGame: {},
        onHome: {}
    )
}
