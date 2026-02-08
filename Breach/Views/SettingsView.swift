import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var transitionManager: TransitionManager
    @ObservedObject private var settings = GameSettings.shared

    @State private var showResetConfirmation = false
    @State private var showTutorial = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader("SETTINGS", tag: "SYS://CONFIG") {
                transitionManager.transition { dismiss() }
            }

            ScrollView {
                VStack(spacing: BreachSpacing.xl) {
                    appearanceSection
                    audioSection
                    gameSection
                    aboutSection
                }
                .padding(.horizontal, BreachSpacing.lg)
                .padding(.top, BreachSpacing.lg)
                .padding(.bottom, BreachSpacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .enableSwipeBack()
        .clearNavigationBackground()
        .navigationDestination(isPresented: $showTutorial) {
            TutorialView()
        }
        .alert("Reset Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settings.resetProgress()
            }
        } message: {
            Text("This will reset all unlocked difficulties and statistics. This action cannot be undone.")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(spacing: BreachSpacing.md) {
            SectionDivider("APPEARANCE")
            BackgroundStylePicker(selection: $settings.backgroundStyle)
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        VStack(spacing: 0) {
            SectionDivider("AUDIO")
                .padding(.bottom, BreachSpacing.md)

            SettingsToggle(
                title: "Sound Effects",
                icon: "speaker.wave.2",
                isOn: $settings.soundEnabled
            )

            SettingsRowDivider()

            SettingsToggle(
                title: "Haptic Feedback",
                icon: "iphone.radiowaves.left.and.right",
                isOn: $settings.hapticsEnabled
            )
        }
    }

    // MARK: - Game

    private var gameSection: some View {
        VStack(spacing: 0) {
            SectionDivider("GAME")
                .padding(.bottom, BreachSpacing.md)

            SettingsToggle(
                title: "Help Mode",
                icon: "lightbulb",
                isOn: $settings.helpModeEnabled
            )

            Text("Highlights optimal moves. Stats are not tracked.")
                .font(BreachTypography.caption(10))
                .foregroundColor(BreachColors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 36)
                .padding(.bottom, BreachSpacing.xs)

            SettingsRowDivider()

            SettingsButton(
                title: "How to Play",
                icon: "questionmark.circle",
                color: BreachColors.accent
            ) {
                transitionManager.transition { showTutorial = true }
            }

            SettingsRowDivider()

            SettingsButton(
                title: "Reset Progress",
                icon: "arrow.counterclockwise",
                color: BreachColors.danger
            ) {
                showResetConfirmation = true
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 0) {
            SectionDivider("ABOUT")
                .padding(.bottom, BreachSpacing.md)

            SettingsInfoRow(title: "Version", value: "1.0.0")

            SettingsRowDivider()

            SettingsButton(
                title: "Privacy Policy",
                icon: "lock.shield",
                color: BreachColors.accent
            ) {
                // Will open privacy policy URL
            }
        }
    }
}

// MARK: - Settings Row Divider

struct SettingsRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(BreachColors.accent.opacity(0.1))
            .frame(height: 1)
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
                .foregroundColor(BreachColors.accent)
                .frame(width: 24)

            Text(title)
                .font(BreachTypography.body())
                .foregroundColor(BreachColors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(BreachColors.accent)
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
        VStack(spacing: 0) {
            ForEach(Array(BackgroundStyle.allCases.enumerated()), id: \.element) { index, style in
                BackgroundStyleOption(
                    style: style,
                    isSelected: selection == style
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = style
                    }
                }

                if index < BackgroundStyle.allCases.count - 1 {
                    SettingsRowDivider()
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
                // Left accent bar for selected state
                Rectangle()
                    .fill(isSelected ? BreachColors.accent : .clear)
                    .frame(width: 3, height: 36)

                // Mini preview
                MiniBackgroundPreview(style: style)
                    .frame(width: 52, height: 32)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? BreachColors.accent : BreachColors.borderSecondary,
                                lineWidth: 1
                            )
                    )

                // Label and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.rawValue)
                        .font(BreachTypography.body())
                        .foregroundColor(
                            isSelected ? BreachColors.accent : BreachColors.textPrimary
                        )

                    Text(style.description)
                        .font(BreachTypography.caption(10))
                        .foregroundColor(BreachColors.textMuted)
                }

                Spacer()
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
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(hex: "080C16"))
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
        let cyan = Color(hex: "3B9EFF")
        let vanishingY = size.height * 0.3
        for i in 0..<5 {
            let progress = Double(i) / 4.0
            let y = vanishingY + (size.height - vanishingY) * pow(progress, 1.5)
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(cyan.opacity(0.3 + progress * 0.4)), lineWidth: 0.5)
        }
        let centerX = size.width / 2
        for i in 0..<5 {
            let bottomX = centerX + size.width * Double(i - 2) / 2.0 * 0.8
            var path = Path()
            path.move(to: CGPoint(x: centerX, y: vanishingY))
            path.addLine(to: CGPoint(x: bottomX, y: size.height))
            context.stroke(path, with: .color(cyan.opacity(0.3)), lineWidth: 0.5)
        }
    }

    private func drawMiniCircuit(context: GraphicsContext, size: CGSize) {
        let cyan = Color(hex: "3B9EFF")
        let traces: [[(CGFloat, CGFloat)]] = [
            [(0, 0.3), (0.3, 0.3), (0.3, 0.7), (0.6, 0.7)],
            [(1.0, 0.5), (0.7, 0.5), (0.7, 0.2), (0.4, 0.2)],
            [(0.5, 1.0), (0.5, 0.6), (0.9, 0.6)]
        ]
        for trace in traces {
            var path = Path()
            for (i, point) in trace.enumerated() {
                let pt = CGPoint(x: point.0 * size.width, y: point.1 * size.height)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            context.stroke(path, with: .color(cyan.opacity(0.5)), lineWidth: 1)
            for point in trace {
                let pt = CGPoint(x: point.0 * size.width, y: point.1 * size.height)
                let rect = CGRect(x: pt.x - 1.5, y: pt.y - 1.5, width: 3, height: 3)
                context.fill(Path(ellipseIn: rect), with: .color(cyan.opacity(0.6)))
            }
        }
    }
}

#Preview {
    ZStack {
        BackgroundView(state: .menu).ignoresSafeArea()
        NavigationStack {
            SettingsView()
        }
    }
    .environmentObject(BackgroundStateManager())
    .environmentObject(TransitionManager())
}
