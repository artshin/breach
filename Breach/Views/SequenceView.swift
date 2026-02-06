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

struct SequenceRowView: View {
    let sequence: TargetSequence

    @State private var showCompletionGlow = false
    @State private var checkmarkScale: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Image(systemName: statusIcon)
                .font(.system(size: 10))
                .foregroundColor(statusColor)

            // Codes with progress
            HStack(spacing: 4) {
                ForEach(Array(sequence.codes.enumerated()), id: \.offset) { index, code in
                    HStack(spacing: 4) {
                        Text(code)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(codeColor(at: index))

                        if index < sequence.codes.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8))
                                .foregroundColor(separatorColor)
                        }
                    }
                }
            }

            Spacer()

            // Progress indicator
            Text("[\(sequence.matchedCount)/\(sequence.codes.count)]")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(progressColor)

            // Status badge with animation
            if sequence.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(BreachColors.sequenceComplete)
                    .scaleEffect(checkmarkScale)
                    .shadow(
                        color: showCompletionGlow ? BreachColors.sequenceComplete.opacity(0.8) : .clear,
                        radius: showCompletionGlow ? 8 : 0
                    )
            } else if sequence.isImpossible {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(BreachColors.sequenceFailed.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            Rectangle()
                .fill(showCompletionGlow ? BreachColors.sequenceComplete.opacity(0.1) : Color.clear)
        )
        .opacity(sequence.isImpossible ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .onChange(of: sequence.isComplete) { isComplete in
            if isComplete {
                // Animate checkmark appearing
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    checkmarkScale = 1.2
                }
                // Then settle to normal size
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        checkmarkScale = 1.0
                    }
                }
                // Glow effect
                withAnimation(.easeIn(duration: 0.2)) {
                    showCompletionGlow = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCompletionGlow = false
                    }
                }
            }
        }
        .onAppear {
            if sequence.isComplete {
                checkmarkScale = 1.0
            }
        }
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

    private var separatorColor: Color {
        if sequence.isComplete {
            BreachColors.sequenceComplete.opacity(0.5)
        } else if sequence.isImpossible {
            BreachColors.textMuted.opacity(0.3)
        } else {
            BreachColors.accent.opacity(0.3)
        }
    }

    private var progressColor: Color {
        if sequence.isComplete {
            BreachColors.sequenceComplete
        } else if sequence.isImpossible {
            BreachColors.textMuted
        } else {
            BreachColors.accent.opacity(0.7)
        }
    }

    private var accessibilityLabel: String {
        let codes = sequence.codes.joined(separator: " then ")
        let progress = "\(sequence.matchedCount) of \(sequence.codes.count) matched"

        if sequence.isComplete {
            return "Sequence completed: \(codes). \(progress)"
        } else if sequence.isImpossible {
            return "Sequence failed: \(codes). Cannot be completed"
        } else {
            let nextCode = sequence.nextNeededCode ?? ""
            return "Sequence: \(codes). \(progress). Next needed: \(nextCode)"
        }
    }
}

/// Keep legacy SequenceView for compatibility
struct SequenceView: View {
    let sequence: TargetSequence

    var body: some View {
        SequenceRowView(sequence: sequence)
            .padding(12)
            .background(
                Rectangle()
                    .stroke(
                        sequence.isComplete
                            ? BreachColors.sequenceComplete
                            : BreachColors.sequenceRemaining.opacity(0.5),
                        lineWidth: 1
                    )
            )
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
