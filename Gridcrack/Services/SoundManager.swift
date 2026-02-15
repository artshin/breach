import AppLogService
import AVFoundation
import SwiftUI

/// Manages all game sound effects and ambient audio
@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private let log = Logger.shared

    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var ambientPlayers: [AmbientTrack: AVAudioPlayer] = [:]
    private var currentAmbientTrack: AmbientTrack?
    private let ambientVolume: Float = 0.3
    private let ambientFadeDuration: TimeInterval = 1.0
    private var settings: GameSettings {
        GameSettings.shared
    }

    enum AmbientTrack: String {
        case menu = "ambient_menu"
        case game = "ambient_game"
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
        prepareAmbientTracks()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            log.info("Audio session ready", tags: ["audio"])
        } catch {
            log.error("Audio session setup failed", metadata: ["error": "\(error)"], tags: ["audio"])
        }
    }

    private func preloadSounds() {
        var loaded = 0
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
                loaded += 1
            } catch {
                log.error(
                    "Failed to load sound",
                    metadata: ["effect": effect.rawValue, "error": "\(error)"],
                    tags: ["audio"]
                )
            }
        }
        log.info("Sounds preloaded \(loaded)/\(SoundEffect.allCases.count)", tags: ["audio"])
    }

    // MARK: - Ambient Tracks

    private func prepareAmbientTracks() {
        for track in [AmbientTrack.menu, .game] {
            guard let url = Bundle.main.url(
                forResource: track.rawValue,
                withExtension: "wav"
            ) else {
                log.warning("Ambient track \(track.rawValue) not found", tags: ["audio"])
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0
                player.prepareToPlay()
                ambientPlayers[track] = player
            } catch {
                log.error(
                    "Failed to load ambient track",
                    metadata: ["track": track.rawValue, "error": "\(error)"],
                    tags: ["audio"]
                )
            }
        }
        log.info("Ambient tracks prepared: \(ambientPlayers.count)/2", tags: ["audio"])
    }

    func switchAmbient(to track: AmbientTrack) {
        guard settings.soundEnabled else { return }
        guard track != currentAmbientTrack else { return }

        // Fade out current track
        if let current = currentAmbientTrack, let player = ambientPlayers[current] {
            player.setVolume(0, fadeDuration: ambientFadeDuration)
            let fadeDuration = ambientFadeDuration
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(fadeDuration))
                if currentAmbientTrack != current {
                    player.stop()
                }
            }
        }

        // Start and fade in new track
        if let player = ambientPlayers[track] {
            player.volume = 0
            player.play()
            player.setVolume(ambientVolume, fadeDuration: ambientFadeDuration)
        }

        currentAmbientTrack = track
        log.info("Ambient switched to \(track.rawValue)", tags: ["audio"])
    }

    func stopAmbient() {
        guard let current = currentAmbientTrack,
              let player = ambientPlayers[current]
        else { return }
        player.setVolume(0, fadeDuration: ambientFadeDuration)
        let fadeDuration = ambientFadeDuration
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(fadeDuration))
            player.stop()
        }
        currentAmbientTrack = nil
        log.info("Ambient stopped", tags: ["audio"])
    }

    func updateAmbientForSoundSetting() {
        if settings.soundEnabled {
            if let track = currentAmbientTrack, let player = ambientPlayers[track] {
                player.volume = ambientVolume
                player.play()
            }
        } else {
            for player in ambientPlayers.values {
                player.pause()
            }
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
