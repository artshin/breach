import SwiftUI

struct BufferView: View {
    let buffer: [String]
    let bufferSize: Int

    private var remaining: Int {
        bufferSize - buffer.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BUFFER")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(BreachColors.accent.opacity(0.7))

                Spacer()

                Text(remainingText)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(remainingColor)
            }

            HStack(spacing: 4) {
                ForEach(0..<bufferSize, id: \.self) { index in
                    BufferSlotView(
                        code: index < buffer.count ? buffer[index] : nil,
                        isFilled: index < buffer.count,
                        isNext: index == buffer.count,
                        index: index
                    )
                }
            }
        }
        .padding(12)
        .background(
            Rectangle()
                .stroke(BreachColors.borderPrimary, lineWidth: 1)
        )
        .breachBevel(intensity: 0.4)
    }

    private var remainingText: String {
        remaining == 0 ? "FULL" : "\(remaining) LEFT"
    }

    private var remainingColor: Color {
        if remaining == 0 {
            BreachColors.danger
        } else if remaining <= 1 {
            BreachColors.warning
        } else {
            BreachColors.accent.opacity(0.5)
        }
    }
}

struct BufferSlotView: View {
    let code: String?
    let isFilled: Bool
    let isNext: Bool
    let index: Int

    @State private var animateIn = false
    @State private var cursorPulse = false
    @State private var showEntryFlash = false

    var body: some View {
        Text(code ?? "  ")
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(textColor)
            .frame(width: 40, height: 36)
            .background(slotBackground)
            .overlay(slotBorder)
            .overlay(entryFlash)
            .scaleEffect(scaleValue)
            .opacity(opacityValue)
            .onChange(of: isFilled) { newValue in
                handleFillChange(newValue)
            }
            .onAppear(perform: handleOnAppear)
            .onChange(of: isNext) { _ in updateCursorPulse() }
    }
}

// MARK: - Buffer Slot Styling

extension BufferSlotView {
    private var textColor: Color {
        isFilled ? BreachColors.bufferFilled : BreachColors.bufferEmpty
    }

    private var slotBackground: some View {
        Rectangle().fill(backgroundFill)
    }

    private var backgroundFill: Color {
        if isFilled {
            BreachColors.bufferFilled.opacity(0.1)
        } else if isNext {
            BreachColors.sequenceNext.opacity(cursorPulse ? 0.06 : 0.02)
        } else {
            BreachColors.background
        }
    }

    private var slotBorder: some View {
        Rectangle()
            .stroke(borderColor, lineWidth: isNext ? 1.5 : 1)
    }

    private var borderColor: Color {
        if isFilled {
            BreachColors.bufferFilled
        } else if isNext {
            BreachColors.sequenceNext.opacity(cursorPulse ? 0.8 : 0.25)
        } else {
            BreachColors.bufferEmpty
        }
    }

    @ViewBuilder
    private var entryFlash: some View {
        if showEntryFlash {
            Rectangle()
                .fill(BreachColors.bufferFilled.opacity(0.4))
        }
    }

    private var scaleValue: CGFloat {
        animateIn && isFilled ? 1.0 : (isFilled ? 0.8 : 1.0)
    }

    private var opacityValue: Double {
        animateIn || !isFilled ? 1.0 : 0.0
    }
}

// MARK: - Buffer Slot Animations

extension BufferSlotView {
    private func handleFillChange(_ newValue: Bool) {
        if newValue {
            showEntryFlash = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateIn = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showEntryFlash = false
                }
            }
        } else {
            animateIn = false
            showEntryFlash = false
        }
    }

    private func handleOnAppear() {
        if isFilled {
            animateIn = true
        }
        updateCursorPulse()
    }

    private func updateCursorPulse() {
        if isNext, !isFilled {
            withAnimation(
                .easeInOut(duration: 0.7)
                    .repeatForever(autoreverses: true)
            ) {
                cursorPulse = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.15)) {
                cursorPulse = false
            }
        }
    }
}

#Preview {
    BufferView(buffer: ["1C", "BD", "55"], bufferSize: 6)
        .background(BreachColors.background)
}
