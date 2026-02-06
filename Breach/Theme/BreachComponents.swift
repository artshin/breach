import SwiftUI

// MARK: - Primary Button

struct BreachButton: View {
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
                .font(BreachTypography.body(14))
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.horizontal, BreachSpacing.xl)
                .padding(.vertical, BreachSpacing.md)
                .frame(minWidth: 140)
                .breachGlass(tint: color)
                .overlay(
                    Rectangle()
                        .stroke(color, lineWidth: 1)
                )
                .breachBevel(color: color)
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
                .font(BreachTypography.body(14))
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.horizontal, BreachSpacing.xl)
                .padding(.vertical, BreachSpacing.md)
                .frame(minWidth: 140)
                .breachGlass(tint: color, opacity: 0.08)
                .overlay(
                    Rectangle()
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
                .breachBevel(color: color, intensity: 0.6)
        }
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
            GlowingText("BREACH PROTOCOL")

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
