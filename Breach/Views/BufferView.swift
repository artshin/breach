import SwiftUI

struct BufferView: View {
    let buffer: [String]
    let bufferSize: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BUFFER")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.7))

            HStack(spacing: 4) {
                ForEach(0..<bufferSize, id: \.self) { index in
                    BufferSlotView(
                        code: index < buffer.count ? buffer[index] : nil,
                        isFilled: index < buffer.count,
                        index: index
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
}

struct BufferSlotView: View {
    let code: String?
    let isFilled: Bool
    let index: Int

    @State private var animateIn = false

    var body: some View {
        Text(code ?? "  ")
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(isFilled ? .yellow : .cyan.opacity(0.3))
            .frame(width: 40, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isFilled ? Color.yellow.opacity(0.1) : Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isFilled ? Color.yellow : Color.cyan.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(animateIn && isFilled ? 1.0 : (isFilled ? 0.8 : 1.0))
            .opacity(animateIn || !isFilled ? 1.0 : 0.0)
            .onChange(of: isFilled) { newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        animateIn = true
                    }
                } else {
                    animateIn = false
                }
            }
            .onAppear {
                if isFilled {
                    animateIn = true
                }
            }
    }
}

#Preview {
    BufferView(buffer: ["1C", "BD", "55"], bufferSize: 6)
        .background(Color.black)
}
