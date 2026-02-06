import SwiftUI

// MARK: - Primary Button

struct BreachButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(_ title: String, color: Color = BreachColors.cyan, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BreachTypography.body(14))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.horizontal, BreachSpacing.xl)
                .padding(.vertical, BreachSpacing.md)
                .frame(minWidth: 140)
                .background(color)
                .cornerRadius(BreachRadius.sm)
        }
    }
}

// MARK: - Secondary Button (Outline)

struct BreachOutlineButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(_ title: String, color: Color = BreachColors.cyan, action: @escaping () -> Void) {
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
                .background(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: BreachRadius.sm)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
                .cornerRadius(BreachRadius.sm)
        }
    }
}

// MARK: - Icon Button

struct BreachIconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    init(_ icon: String, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(BreachColors.cyan)
                .frame(width: size, height: size)
                .background(BreachColors.cyan.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: BreachRadius.sm)
                        .stroke(BreachColors.borderSecondary, lineWidth: 1)
                )
                .cornerRadius(BreachRadius.sm)
        }
    }
}

// MARK: - Panel Container

struct BreachPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(BreachSpacing.md)
            .background(BreachColors.panelBackground)
            .overlay(
                RoundedRectangle(cornerRadius: BreachRadius.sm)
                    .stroke(BreachColors.borderSecondary, lineWidth: 1)
            )
            .cornerRadius(BreachRadius.sm)
    }
}

// MARK: - Card Container

struct BreachCard<Content: View>: View {
    let isSelected: Bool
    let color: Color
    let content: Content

    init(isSelected: Bool = false, color: Color = BreachColors.cyan, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.color = color
        self.content = content()
    }

    var body: some View {
        content
            .padding(BreachSpacing.lg)
            .background(isSelected ? color.opacity(0.15) : BreachColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: BreachRadius.md)
                    .stroke(isSelected ? color : BreachColors.borderSecondary, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(BreachRadius.md)
    }
}

// MARK: - Section Header

struct BreachSectionHeader: View {
    let title: String
    let color: Color

    init(_ title: String, color: Color = BreachColors.cyan) {
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

    init(_ text: String, font: Font = BreachTypography.title(), color: Color = BreachColors.cyan) {
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
                        .foregroundColor(.white)
                }
            }

            BreachCard(isSelected: true) {
                Text("Selected Card")
                    .foregroundColor(.white)
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
