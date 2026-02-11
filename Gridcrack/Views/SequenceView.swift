import SwiftUI

struct SequencePanelView: View {
    let sequences: [TargetSequence]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SEQUENCES")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(BreachColors.accent.opacity(0.7))

            ForEach(sequences) { sequence in
                SequenceRowView(sequence: sequence)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .stroke(BreachColors.borderPrimary, lineWidth: 1)
        )
        .breachBevel()
    }
}

// MARK: - Sequence Row

struct SequenceRowView: View {
    let sequence: TargetSequence

    @State private var showCompletionGlow = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var pulseNext = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showFailFlash = false
    @State private var completionScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                statusIndicator
                codesSection
                Spacer()
                progressCounter
                completionBadge
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)

            progressBar
        }
        .background(rowBackground)
        .clipped()
        .scaleEffect(completionScale)
        .offset(x: shakeOffset)
        .opacity(rowOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .onAppear(perform: handleOnAppear)
        .onChange(of: sequence.isComplete) { newValue in
            if newValue { animateCompletion() }
        }
        .onChange(of: sequence.isImpossible) { newValue in
            if newValue { animateFailure() }
        }
    }

    // MARK: - Sub Views

    private var statusIndicator: some View {
        Image(systemName: statusIcon)
            .font(.system(size: 10))
            .foregroundColor(statusColor)
    }

    private var codesSection: some View {
        HStack(spacing: 4) {
            ForEach(
                Array(sequence.codes.enumerated()),
                id: \.offset
            ) { index, code in
                codeCell(code: code, at: index)
            }
        }
    }

    private func codeCell(
        code: String,
        at index: Int
    ) -> some View {
        HStack(spacing: 4) {
            codeBadge(code: code, at: index)

            if index < sequence.codes.count - 1 {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(separatorColor)
            }
        }
    }

    private func codeBadge(
        code: String,
        at index: Int
    ) -> some View {
        Text(code)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(codeColor(at: index))
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(codeHighlight(at: index))
            .shadow(color: codeGlow(at: index), radius: 6)
            .overlay(codeDoneStrike(at: index))
    }

    private var progressCounter: some View {
        Text("[\(sequence.matchedCount)/\(sequence.codes.count)]")
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(progressTextColor)
    }

    @ViewBuilder
    private var completionBadge: some View {
        if sequence.isComplete {
            completionCheckmark
        } else if sequence.isImpossible {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(
                    BreachColors.sequenceFailed.opacity(0.7)
                )
        }
    }

    private var completionCheckmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 12))
            .foregroundColor(BreachColors.sequenceComplete)
            .scaleEffect(checkmarkScale)
            .shadow(
                color: completionGlowColor,
                radius: showCompletionGlow ? 8 : 0
            )
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(BreachColors.accent.opacity(0.08))
                Rectangle()
                    .fill(progressBarColor)
                    .frame(width: geo.size.width * sequence.progress)
                    .animation(
                        .easeInOut(duration: 0.3),
                        value: sequence.progress
                    )
            }
        }
        .frame(height: 2)
    }

    private var rowBackground: some View {
        ZStack {
            if showCompletionGlow {
                BreachColors.sequenceComplete.opacity(0.15)
            }
            if showFailFlash {
                BreachColors.sequenceFailed.opacity(0.2)
            }
        }
    }
}

// MARK: - Sequence Row Styling

extension SequenceRowView {
    private var isActive: Bool {
        !sequence.isComplete && !sequence.isImpossible
    }

    private func isNextCode(at index: Int) -> Bool {
        isActive && index == sequence.matchedCount
    }

    private func isMatchedCode(at index: Int) -> Bool {
        isActive && index < sequence.matchedCount
    }

    private var statusIcon: String {
        if sequence.isComplete {
            "checkmark.circle.fill"
        } else if sequence.isImpossible {
            "xmark.circle"
        } else if sequence.matchedCount > 0 {
            "circle.lefthalf.filled"
        } else {
            "circle"
        }
    }

    private var statusColor: Color {
        if sequence.isComplete {
            BreachColors.sequenceComplete
        } else if sequence.isImpossible {
            BreachColors.sequenceFailed.opacity(0.5)
        } else if sequence.matchedCount > 0 {
            BreachColors.sequenceNext
        } else {
            BreachColors.accent.opacity(0.5)
        }
    }

    private func codeColor(at index: Int) -> Color {
        if sequence.isComplete {
            BreachColors.sequenceComplete
        } else if sequence.isImpossible {
            BreachColors.textMuted
        } else if index < sequence.matchedCount {
            BreachColors.sequenceMatched
        } else if index == sequence.matchedCount {
            BreachColors.sequenceNext
        } else {
            BreachColors.sequenceRemaining
        }
    }

    @ViewBuilder
    private func codeHighlight(at index: Int) -> some View {
        if isNextCode(at: index) {
            Rectangle()
                .fill(
                    BreachColors.sequenceNext
                        .opacity(pulseNext ? 0.2 : 0.06)
                )
                .overlay(
                    Rectangle().stroke(
                        BreachColors.sequenceNext
                            .opacity(pulseNext ? 0.5 : 0.15),
                        lineWidth: 1
                    )
                )
        }
    }

    private func codeGlow(at index: Int) -> Color {
        if isNextCode(at: index), pulseNext {
            BreachColors.sequenceNext.opacity(0.5)
        } else {
            .clear
        }
    }

    @ViewBuilder
    private func codeDoneStrike(at index: Int) -> some View {
        if isMatchedCode(at: index) {
            Rectangle()
                .fill(BreachColors.sequenceMatched.opacity(0.5))
                .frame(height: 1)
        }
    }

    private var separatorColor: Color {
        if sequence.isComplete {
            BreachColors.sequenceComplete.opacity(0.5)
        } else if sequence.isImpossible {
            BreachColors.textMuted.opacity(0.3)
        } else {
            BreachColors.accent.opacity(0.3)
        }
    }

    private var progressTextColor: Color {
        if sequence.isComplete {
            BreachColors.sequenceComplete
        } else if sequence.isImpossible {
            BreachColors.textMuted
        } else {
            BreachColors.accent.opacity(0.7)
        }
    }

    private var progressBarColor: Color {
        if sequence.isComplete { return BreachColors.sequenceComplete }
        if sequence.isImpossible { return BreachColors.sequenceFailed.opacity(0.3) }
        return BreachColors.sequenceNext.opacity(0.6)
    }

    private var rowOpacity: Double {
        sequence.isImpossible && !showFailFlash ? 0.4 : 1.0
    }

    private var completionGlowColor: Color {
        showCompletionGlow ? BreachColors.sequenceComplete.opacity(0.8) : .clear
    }

    private var accessibilityText: String {
        let codes = sequence.codes.joined(separator: " then ")
        let matched = sequence.matchedCount
        let total = sequence.codes.count

        if sequence.isComplete {
            return "Sequence completed: \(codes). \(matched) of \(total)"
        } else if sequence.isImpossible {
            return "Sequence failed: \(codes). Cannot be completed"
        } else {
            let next = sequence.nextNeededCode ?? ""
            return "Sequence: \(codes). \(matched) of \(total). Next: \(next)"
        }
    }
}

// MARK: - Sequence Row Animations

extension SequenceRowView {
    private func handleOnAppear() {
        if sequence.isComplete {
            checkmarkScale = 1.0
        }
        startPulseIfNeeded()
    }

    private func startPulseIfNeeded() {
        guard isActive else { return }
        withAnimation(
            .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseNext = true
        }
    }

    private func animateCompletion() {
        withAnimation(.easeOut(duration: 0.15)) {
            pulseNext = false
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            completionScale = 1.04
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                completionScale = 1.0
            }
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            checkmarkScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                checkmarkScale = 1.0
            }
        }
        withAnimation(.easeIn(duration: 0.15)) {
            showCompletionGlow = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                showCompletionGlow = false
            }
        }
    }

    private func animateFailure() {
        withAnimation(.easeOut(duration: 0.1)) {
            pulseNext = false
        }
        withAnimation(.easeIn(duration: 0.1)) {
            showFailFlash = true
        }
        shakeOffset = 8
        withAnimation(.interpolatingSpring(stiffness: 600, damping: 12)) {
            shakeOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                showFailFlash = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SequencePanelView(sequences: [
            TargetSequence(codes: ["1C", "55", "BD"], matchedCount: 2),
            TargetSequence(codes: ["55", "BD", "E9"], matchedCount: 1),
            TargetSequence(codes: ["7A", "FF"], matchedCount: 0, isImpossible: true)
        ])
        SequencePanelView(sequences: [
            TargetSequence(codes: ["1C", "55", "BD"], matchedCount: 3)
        ])
    }
    .padding()
    .background(BreachColors.background)
}
