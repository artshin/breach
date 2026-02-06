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
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                // Stats
                VStack(spacing: 12) {
                    // Sequences completed
                    HStack {
                        Text("SEQUENCES")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.7))
                        Spacer()
                        Text("\(resultData.completed)/\(resultData.total)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(hasAnySuccess ? .green : .red)
                    }

                    // Moves vs Par
                    HStack {
                        Text("MOVES")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.7))
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(resultData.moves)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(resultData.moves <= resultData.par ? .green : .yellow)
                            Text("/")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("\(resultData.par)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.7))
                            Text("PAR")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // Action Buttons
                VStack(spacing: BreachSpacing.md) {
                    Button(action: onNewGame) {
                        Text("PLAY AGAIN")
                            .font(BreachTypography.body(16))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, BreachSpacing.xxl)
                            .padding(.vertical, BreachSpacing.md)
                            .frame(minWidth: 160)
                            .background(buttonColor)
                            .cornerRadius(BreachRadius.sm)
                    }

                    if let onHome {
                        Button(action: onHome) {
                            Text("HOME")
                                .font(BreachTypography.caption())
                                .foregroundColor(BreachColors.cyan)
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
        case 3: "OPTIMAL BREACH"
        case 2: "ACCESS GRANTED"
        case 1: "PARTIAL BREACH"
        default: "BREACH FAILED"
        }
    }

    private var titleColor: Color {
        switch stars {
        case 3: .yellow
        case 2: .green
        case 1: .orange
        default: .red
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
        case 3: .yellow
        case 2: .green
        case 1: .orange
        default: .cyan
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
                    .foregroundColor(index < count ? .yellow : .gray.opacity(0.3))
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
                    .foregroundColor(index < count ? .yellow : .gray.opacity(0.3))
                    .scaleEffect(starScales[index])
                    .rotationEffect(.degrees(starRotations[index]))
                    .shadow(color: index < count ? .yellow.opacity(0.5) : .clear, radius: 8)
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
