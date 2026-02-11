import SwiftUI

// MARK: - Primary Button

struct BreachButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    @State private var glowPulse = false

    init(_ title: String, color: Color = BreachColors.accent, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                color.frame(height: 2)
                    .shadow(color: color.opacity(0.6), radius: 4, y: 2)
                buttonContent
            }
            .frame(minWidth: 180)
            .background(buttonBackground)
            .overlay(buttonBorder)
        }
        .buttonStyle(.plain)
        .onAppear(perform: startGlowPulse)
    }

    private var buttonContent: some View {
        VStack(spacing: 3) {
            Text(">> \(title) <<")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.3))
            Text(title)
                .font(BreachTypography.code(15))
                .foregroundColor(color)
                .shadow(
                    color: color.opacity(glowPulse ? 0.5 : 0.2),
                    radius: glowPulse ? 10 : 4
                )
        }
        .padding(.horizontal, BreachSpacing.xl)
        .padding(.vertical, BreachSpacing.md)
    }

    private var buttonBackground: some View {
        ZStack {
            BreachColors.surfacePrimary.opacity(0.9)
            LinearGradient(
                colors: [color.opacity(0.15), color.opacity(0.04), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var buttonBorder: some View {
        Rectangle()
            .stroke(color.opacity(glowPulse ? 0.35 : 0.2), lineWidth: 1)
            .shadow(color: color.opacity(glowPulse ? 0.15 : 0), radius: glowPulse ? 8 : 0)
    }

    private func startGlowPulse() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }
}

// MARK: - Secondary Button (Outline)

struct BreachOutlineButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(_ title: String, color: Color = BreachColors.accent, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BreachTypography.code(13))
                .foregroundColor(color)
                .padding(.horizontal, BreachSpacing.xl)
                .padding(.vertical, BreachSpacing.md)
                .frame(minWidth: 140)
                .background(BreachColors.surfacePrimary.opacity(0.6))
                .background(color.opacity(0.04))
                .overlay(Rectangle().stroke(color.opacity(0.2), lineWidth: 1))
                .overlay(alignment: .leading) {
                    color.opacity(0.5).frame(width: 2)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Button

struct BreachIconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let action: () -> Void

    init(_ icon: String, size: CGFloat = 44, color: Color = BreachColors.accent, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .breachGlass(tint: color, opacity: 0.08)
                .overlay(
                    Rectangle()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .breachBevel(color: color, intensity: 0.6)
        }
    }
}

// MARK: - Panel Container

struct BreachPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(BreachSpacing.md)
            .breachGlass(tint: BreachColors.accent, opacity: 0.05)
            .overlay(
                Rectangle()
                    .stroke(BreachColors.borderSecondary, lineWidth: 1)
            )
            .breachBevel()
    }
}

// MARK: - Card Container

struct BreachCard<Content: View>: View {
    let isSelected: Bool
    let color: Color
    let content: Content

    init(isSelected: Bool = false, color: Color = BreachColors.accent, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.color = color
        self.content = content()
    }

    var body: some View {
        content
            .padding(BreachSpacing.lg)
            .background(isSelected ? color.opacity(0.15) : BreachColors.surfacePrimary)
            .overlay(
                Rectangle()
                    .stroke(isSelected ? color : BreachColors.borderSecondary, lineWidth: isSelected ? 2 : 1)
            )
            .breachBevel(color: isSelected ? color : BreachColors.accent)
    }
}

// MARK: - Section Header

struct BreachSectionHeader: View {
    let title: String
    let color: Color

    init(_ title: String, color: Color = BreachColors.accent) {
        self.title = title
        self.color = color
    }

    var body: some View {
        Text(title)
            .font(BreachTypography.caption())
            .foregroundColor(color.opacity(0.7))
    }
}

// MARK: - Screen Header

struct ScreenHeader: View {
    let title: String
    let tag: String
    let color: Color
    let dismissAction: () -> Void

    init(
        _ title: String,
        tag: String = "",
        color: Color = BreachColors.accent,
        dismissAction: @escaping () -> Void
    ) {
        self.title = title
        self.tag = tag
        self.color = color
        self.dismissAction = dismissAction
    }

    var body: some View {
        HStack(spacing: BreachSpacing.sm) {
            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Rectangle()
                .fill(color.opacity(0.3))
                .frame(height: 1)

            Text("//")
                .font(BreachTypography.caption(10))
                .foregroundColor(color.opacity(0.4))

            GlowingText(title, font: BreachTypography.title(22), color: color)
                .fixedSize()

            if !tag.isEmpty {
                Text(tag)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(color.opacity(0.4))
                    .fixedSize()
            }

            Rectangle()
                .fill(color.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, BreachSpacing.lg)
        .padding(.top, BreachSpacing.lg)
    }
}

// MARK: - Section Divider

struct SectionDivider: View {
    let title: String
    let color: Color

    init(_ title: String, color: Color = BreachColors.accent) {
        self.title = title
        self.color = color
    }

    var body: some View {
        HStack(spacing: BreachSpacing.sm) {
            Rectangle()
                .fill(color.opacity(0.25))
                .frame(height: 1)

            Text(title)
                .font(BreachTypography.caption(10))
                .foregroundColor(color.opacity(0.6))
                .fixedSize()

            Rectangle()
                .fill(color.opacity(0.25))
                .frame(height: 1)
        }
    }
}

// MARK: - Glowing Text

struct GlowingText: View {
    let text: String
    let font: Font
    let color: Color

    init(_ text: String, font: Font = BreachTypography.title(), color: Color = BreachColors.accent) {
        self.text = text
        self.font = font
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 10)
            .shadow(color: color.opacity(0.3), radius: 20)
    }
}

// MARK: - Scanline Overlay

struct ScanlineOverlay: View {
    var includeVignette = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Scanlines
                VStack(spacing: 2) {
                    ForEach(0..<Int(geo.size.height / 4), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.03))
                            .frame(height: 1)
                        Spacer()
                            .frame(height: 3)
                    }
                }

                // Optional vignette
                if includeVignette {
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.3)],
                        center: .center,
                        startRadius: min(geo.size.width, geo.size.height) * 0.3,
                        endRadius: max(geo.size.width, geo.size.height) * 0.7
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        BreachColors.background.ignoresSafeArea()

        VStack(spacing: 20) {
            GlowingText("GRIDCRACK")

            BreachPanel {
                VStack(alignment: .leading) {
                    BreachSectionHeader("SECTION")
                    Text("Content goes here")
                        .foregroundColor(BreachColors.textPrimary)
                }
            }

            BreachCard(isSelected: true) {
                Text("Selected Card")
                    .foregroundColor(BreachColors.textPrimary)
            }

            BreachButton("PRIMARY") {}
            BreachOutlineButton("SECONDARY") {}

            HStack {
                BreachIconButton("gearshape") {}
                BreachIconButton("chart.bar") {}
            }
        }
        .padding()
    }
}
