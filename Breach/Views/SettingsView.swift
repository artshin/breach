import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = GameSettings.shared

    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            // Animated background
            BackgroundView(state: .settings)
                .ignoresSafeArea()

            VStack(spacing: BreachSpacing.lg) {
                // Header
                headerSection

                // Settings List
                ScrollView {
                    VStack(spacing: BreachSpacing.md) {
                        // Appearance Section
                        SettingsSection(title: "APPEARANCE") {
                            BackgroundStylePicker(selection: $settings.backgroundStyle)
                        }

                        // Audio Section
                        SettingsSection(title: "AUDIO") {
                            SettingsToggle(
                                title: "Sound Effects",
                                icon: "speaker.wave.2",
                                isOn: $settings.soundEnabled
                            )

                            SettingsToggle(
                                title: "Haptic Feedback",
                                icon: "iphone.radiowaves.left.and.right",
                                isOn: $settings.hapticsEnabled
                            )
                        }

                        // Game Section
                        SettingsSection(title: "GAME") {
                            SettingsButton(
                                title: "Show Tutorial",
                                icon: "questionmark.circle",
                                color: BreachColors.cyan
                            ) {
                                TutorialManager.shared.resetTutorial()
                                dismiss()
                            }

                            SettingsButton(
                                title: "Reset Progress",
                                icon: "arrow.counterclockwise",
                                color: BreachColors.red
                            ) {
                                showResetConfirmation = true
                            }
                        }

                        // About Section
                        SettingsSection(title: "ABOUT") {
                            SettingsInfoRow(
                                title: "Version",
                                value: "1.0.0"
                            )

                            SettingsButton(
                                title: "Privacy Policy",
                                icon: "lock.shield",
                                color: BreachColors.cyan
                            ) {
                                // Will open privacy policy URL
                            }
                        }
                    }
                    .padding(.horizontal, BreachSpacing.lg)
                }

                Spacer()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("Reset Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.resetProgress()
            }
        } message: {
            Text("This will reset all unlocked difficulties and statistics. This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("SETTINGS")
                .font(BreachTypography.heading())
                .foregroundColor(BreachColors.cyan)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BreachColors.cyan)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, BreachSpacing.lg)
        .padding(.top, BreachSpacing.lg)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BreachSpacing.sm) {
            BreachSectionHeader(title)
                .padding(.leading, BreachSpacing.xs)

            BreachPanel {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: BreachSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(BreachColors.cyan)
                .frame(width: 24)

            Text(title)
                .font(BreachTypography.body())
                .foregroundColor(BreachColors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(BreachColors.cyan)
        }
        .padding(.vertical, BreachSpacing.sm)
    }
}

// MARK: - Settings Button

struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BreachSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(BreachTypography.body())
                    .foregroundColor(BreachColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(BreachColors.textMuted)
            }
            .padding(.vertical, BreachSpacing.sm)
        }
    }
}

// MARK: - Settings Info Row

struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(BreachTypography.body())
                .foregroundColor(BreachColors.textPrimary)

            Spacer()

            Text(value)
                .font(BreachTypography.body())
                .foregroundColor(BreachColors.textMuted)
        }
        .padding(.vertical, BreachSpacing.sm)
    }
}

// MARK: - Background Style Picker

struct BackgroundStylePicker: View {
    @Binding var selection: BackgroundStyle

    var body: some View {
        VStack(spacing: BreachSpacing.md) {
            ForEach(BackgroundStyle.allCases) { style in
                BackgroundStyleOption(
                    style: style,
                    isSelected: selection == style
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = style
                    }
                }
            }
        }
    }
}

// MARK: - Background Style Option

struct BackgroundStyleOption: View {
    let style: BackgroundStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BreachSpacing.md) {
                // Mini preview
                MiniBackgroundPreview(style: style)
                    .frame(width: 60, height: 40)
                    .cornerRadius(BreachRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: BreachRadius.sm)
                            .stroke(isSelected ? BreachColors.cyan : BreachColors.borderSecondary, lineWidth: isSelected ? 2 : 1)
                    )

                // Label and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.rawValue)
                        .font(BreachTypography.body())
                        .foregroundColor(isSelected ? BreachColors.cyan : BreachColors.textPrimary)

                    Text(style.description)
                        .font(BreachTypography.caption(10))
                        .foregroundColor(BreachColors.textMuted)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(BreachColors.cyan)
                }
            }
            .padding(.vertical, BreachSpacing.sm)
        }
    }
}

// MARK: - Mini Background Preview

struct MiniBackgroundPreview: View {
    let style: BackgroundStyle

    var body: some View {
        Canvas { context, size in
            // Dark background
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(hex: "0A0E1A"))
            )

            switch style {
            case .livingGrid:
                drawMiniGrid(context: context, size: size)
            case .circuitTraces:
                drawMiniCircuit(context: context, size: size)
            }
        }
    }

    private func drawMiniGrid(context: GraphicsContext, size: CGSize) {
        let cyan = Color(hex: "00F0FF")
        let vanishingY = size.height * 0.3

        // Horizontal lines
        for i in 0..<5 {
            let progress = Double(i) / 4.0
            let y = vanishingY + (size.height - vanishingY) * pow(progress, 1.5)
            let opacity = 0.3 + progress * 0.4

            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))

            context.stroke(path, with: .color(cyan.opacity(opacity)), lineWidth: 0.5)
        }

        // Vertical lines converging
        let centerX = size.width / 2
        for i in 0..<5 {
            let spread = Double(i - 2) / 2.0 * 0.8
            let bottomX = centerX + size.width * spread

            var path = Path()
            path.move(to: CGPoint(x: centerX, y: vanishingY))
            path.addLine(to: CGPoint(x: bottomX, y: size.height))

            context.stroke(path, with: .color(cyan.opacity(0.3)), lineWidth: 0.5)
        }
    }

    private func drawMiniCircuit(context: GraphicsContext, size: CGSize) {
        let cyan = Color(hex: "00F0FF")

        // Draw a few simple circuit traces
        let traces: [[(CGFloat, CGFloat)]] = [
            [(0, 0.3), (0.3, 0.3), (0.3, 0.7), (0.6, 0.7)],
            [(1.0, 0.5), (0.7, 0.5), (0.7, 0.2), (0.4, 0.2)],
            [(0.5, 1.0), (0.5, 0.6), (0.9, 0.6)]
        ]

        for trace in traces {
            var path = Path()
            for (i, point) in trace.enumerated() {
                let cgPoint = CGPoint(x: point.0 * size.width, y: point.1 * size.height)
                if i == 0 {
                    path.move(to: cgPoint)
                } else {
                    path.addLine(to: cgPoint)
                }
            }
            context.stroke(path, with: .color(cyan.opacity(0.5)), lineWidth: 1)

            // Draw nodes at corners
            for point in trace {
                let cgPoint = CGPoint(x: point.0 * size.width, y: point.1 * size.height)
                context.fill(
                    Path(ellipseIn: CGRect(x: cgPoint.x - 1.5, y: cgPoint.y - 1.5, width: 3, height: 3)),
                    with: .color(cyan.opacity(0.6))
                )
            }
        }
    }
}

#Preview {
    SettingsView()
}
