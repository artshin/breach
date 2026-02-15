import AppLogService
import SwiftUI
import UIKit

/// Manages haptic feedback throughout the game
@MainActor
class HapticsManager: ObservableObject {
    static let shared = HapticsManager()

    private var settings: GameSettings {
        GameSettings.shared
    }

    // Haptic generators
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        prepareGenerators()
        Logger.shared.info("Haptics manager initialized", tags: ["haptics"])
    }

    // MARK: - Preparation

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Impact Haptics

    func lightImpact() {
        guard settings.hapticsEnabled else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func mediumImpact() {
        guard settings.hapticsEnabled else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func heavyImpact() {
        guard settings.hapticsEnabled else { return }
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    // MARK: - Selection Haptic

    func selection() {
        guard settings.hapticsEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Notification Haptics

    func success() {
        guard settings.hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func warning() {
        guard settings.hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    func error() {
        guard settings.hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Game-Specific Haptics

    /// Light tap for cell selection
    func cellSelected() {
        lightImpact()
    }

    /// Medium feedback for sequence progress
    func sequenceProgress() {
        mediumImpact()
    }

    /// Success notification for completing a sequence
    func sequenceComplete() {
        success()
    }

    /// Error notification when sequence becomes impossible
    func sequenceFailed() {
        error()
    }

    /// Heavy impact + success for winning the game
    func gameWin() {
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.success()
        }
    }

    /// Heavy impact + error for losing the game
    func gameLose() {
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.error()
        }
    }
}
