import AVFoundation
import SwiftUI

/// Manages all game sound effects
@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var settings: GameSettings {
        GameSettings.shared
    }

    enum SoundEffect: String, CaseIterable {
        case cellSelect = "cell_select"
        case sequenceProgress = "sequence_progress"
        case sequenceComplete = "sequence_complete"
        case sequenceFailed = "sequence_failed"
        case gameWin = "game_win"
        case gameLose = "game_lose"
        case buttonTap = "button_tap"
    }

    private init() {
        setupAudioSession()
        preloadSounds()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func preloadSounds() {
        // Sounds will be loaded from bundle when assets are added
        // For now, we'll use system sounds as fallback
    }

    // MARK: - Playback

    func play(_ effect: SoundEffect) {
        guard settings.soundEnabled else { return }

        // Try to play from preloaded sounds first
        if let player = audioPlayers[effect] {
            player.currentTime = 0
            player.play()
            return
        }

        // Fallback to system sounds for now
        playSystemSound(for: effect)
    }

    private func playSystemSound(for effect: SoundEffect) {
        let soundID: SystemSoundID = switch effect {
        case .cellSelect:
            1104 // Tock
        case .sequenceProgress:
            1057 // Pop
        case .sequenceComplete:
            1025 // New mail
        case .sequenceFailed:
            1053 // Error
        case .gameWin:
            1025 // Fanfare
        case .gameLose:
            1053 // Sad
        case .buttonTap:
            1104 // Tock
        }

        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - Sound Loading

    func loadSound(_ effect: SoundEffect, from url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[effect] = player
        } catch {
            print("Failed to load sound \(effect.rawValue): \(error)")
        }
    }

    // MARK: - Convenience Methods

    func playCellSelect() {
        play(.cellSelect)
    }

    func playSequenceProgress() {
        play(.sequenceProgress)
    }

    func playSequenceComplete() {
        play(.sequenceComplete)
    }

    func playSequenceFailed() {
        play(.sequenceFailed)
    }

    func playGameWin() {
        play(.gameWin)
    }

    func playGameLose() {
        play(.gameLose)
    }

    func playButtonTap() {
        play(.buttonTap)
    }
}
