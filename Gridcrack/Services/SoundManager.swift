import AVFoundation
import SwiftUI

/// Manages all game sound effects and ambient audio
@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var ambientPlayer: AVAudioPlayer?
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
        case bonusAwarded = "bonus_awarded"
        case difficultySelect = "difficulty_select"
        case gridRushNewGrid = "grid_rush_new_grid"
        case timerTick = "timer_tick"
        case timerWarning = "timer_warning"
        case toggleSwitch = "toggle_switch"
        case transitionWhoosh = "transition_whoosh"
    }

    private init() {
        setupAudioSession()
        preloadSounds()
        prepareAmbientLoop()
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
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(
                forResource: effect.rawValue,
                withExtension: "wav"
            ) else {
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                audioPlayers[effect] = player
            } catch {
                print("Failed to load sound \(effect.rawValue): \(error)")
            }
        }
    }

    // MARK: - Ambient Loop

    private func prepareAmbientLoop() {
        guard let url = Bundle.main.url(
            forResource: "ambient_loop",
            withExtension: "wav"
        ) else { return }
        do {
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1
            ambientPlayer?.volume = 0.3
            ambientPlayer?.prepareToPlay()
        } catch {
            print("Failed to load ambient loop: \(error)")
        }
    }

    func startAmbientLoop() {
        guard settings.soundEnabled else { return }
        guard ambientPlayer?.isPlaying != true else { return }
        ambientPlayer?.play()
    }

    func stopAmbientLoop() {
        ambientPlayer?.stop()
        ambientPlayer?.currentTime = 0
    }

    func updateAmbientForSoundSetting() {
        if settings.soundEnabled {
            ambientPlayer?.play()
        } else {
            ambientPlayer?.pause()
        }
    }

    // MARK: - Playback

    func play(_ effect: SoundEffect) {
        guard settings.soundEnabled else { return }

        if let player = audioPlayers[effect] {
            player.currentTime = 0
            player.play()
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

    func playBonusAwarded() {
        play(.bonusAwarded)
    }

    func playDifficultySelect() {
        play(.difficultySelect)
    }

    func playGridRushNewGrid() {
        play(.gridRushNewGrid)
    }

    func playTimerTick() {
        play(.timerTick)
    }

    func playTimerWarning() {
        play(.timerWarning)
    }

    func playToggleSwitch() {
        play(.toggleSwitch)
    }

    func playTransitionWhoosh() {
        play(.transitionWhoosh)
    }
}
