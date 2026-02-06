import Foundation
import SwiftUI

/// Per-difficulty statistics
struct DifficultyStats: Codable, Equatable {
    var gamesPlayed = 0
    var gamesWon = 0 // At least 1 star
    var totalStars = 0
    var bestStreak = 0
    var currentStreak = 0

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
}

/// Grid Rush mode statistics
struct GridRushStats: Codable, Equatable {
    var totalRuns = 0
    var bestGridsCleared = 0
    var highScore = 0
    var totalGridsCleared = 0
    var bestPerfectStreak = 0
    var totalPerfectClears = 0
}

/// Centralized settings manager for the game
@MainActor
class GameSettings: ObservableObject {
    static let shared = GameSettings()

    // MARK: - Audio Settings

    @Published var soundEnabled = true {
        didSet { save() }
    }

    @Published var hapticsEnabled = true {
        didSet { save() }
    }

    // MARK: - Appearance Settings

    @Published var backgroundStyle: BackgroundStyle = .livingGrid {
        didSet { save() }
    }

    // MARK: - Progression

    @Published var unlockedDifficulties: Set<Difficulty> = [.easy] {
        didSet { save() }
    }

    // MARK: - Per-Difficulty Statistics

    @Published var difficultyStats: [Difficulty: DifficultyStats] = [:] {
        didSet { save() }
    }

    // MARK: - Grid Rush Statistics

    @Published var gridRushStats = GridRushStats() {
        didSet { save() }
    }

    // MARK: - Computed Statistics

    var totalGamesPlayed: Int {
        difficultyStats.values.reduce(0) { $0 + $1.gamesPlayed }
    }

    var totalStarsEarned: Int {
        difficultyStats.values.reduce(0) { $0 + $1.totalStars }
    }

    var overallWinRate: Double {
        let total = totalGamesPlayed
        guard total > 0 else { return 0 }
        let wins = difficultyStats.values.reduce(0) { $0 + $1.gamesWon }
        return Double(wins) / Double(total)
    }

    var bestOverallStreak: Int {
        difficultyStats.values.map(\.bestStreak).max() ?? 0
    }

    private var isLoading = false

    // MARK: - Persistence Keys

    private enum Keys {
        static let soundEnabled = "settings.soundEnabled"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let backgroundStyle = "settings.backgroundStyle"
        static let unlockedDifficulties = "settings.unlockedDifficulties"
        static let difficultyStats = "stats.difficultyStats"
        static let gridRushStats = "stats.gridRushStats"
    }

    // MARK: - Init

    private init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        isLoading = true
        defer { isLoading = false }
        let defaults = UserDefaults.standard

        if defaults.object(forKey: Keys.soundEnabled) != nil {
            soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        }

        if defaults.object(forKey: Keys.hapticsEnabled) != nil {
            hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        }

        // Load background style
        if let styleString = defaults.string(forKey: Keys.backgroundStyle),
           let style = BackgroundStyle(rawValue: styleString) {
            backgroundStyle = style
        }

        // Load unlocked difficulties
        if let data = defaults.data(forKey: Keys.unlockedDifficulties),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedDifficulties = Set(decoded.compactMap { Difficulty(rawValue: $0) })
        }

        // Load difficulty stats
        if let data = defaults.data(forKey: Keys.difficultyStats),
           let decoded = try? JSONDecoder().decode([String: DifficultyStats].self, from: data) {
            difficultyStats = Dictionary(uniqueKeysWithValues:
                decoded.compactMap { key, value -> (Difficulty, DifficultyStats)? in
                    guard let difficulty = Difficulty(rawValue: key) else { return nil }
                    return (difficulty, value)
                }
            )
        }

        // Load Grid Rush stats
        if let data = defaults.data(forKey: Keys.gridRushStats),
           let decoded = try? JSONDecoder().decode(GridRushStats.self, from: data) {
            gridRushStats = decoded
        }

        // Ensure easy is always unlocked
        unlockedDifficulties.insert(.easy)
    }

    private func save() {
        guard !isLoading else { return }
        let defaults = UserDefaults.standard
        defaults.set(soundEnabled, forKey: Keys.soundEnabled)
        defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
        defaults.set(backgroundStyle.rawValue, forKey: Keys.backgroundStyle)

        // Save unlocked difficulties
        let difficultyStrings = Set(unlockedDifficulties.map(\.rawValue))
        if let data = try? JSONEncoder().encode(difficultyStrings) {
            defaults.set(data, forKey: Keys.unlockedDifficulties)
        }

        // Save difficulty stats
        let statsDict = Dictionary(uniqueKeysWithValues:
            difficultyStats.map { ($0.key.rawValue, $0.value) }
        )
        if let data = try? JSONEncoder().encode(statsDict) {
            defaults.set(data, forKey: Keys.difficultyStats)
        }

        // Save Grid Rush stats
        if let data = try? JSONEncoder().encode(gridRushStats) {
            defaults.set(data, forKey: Keys.gridRushStats)
        }
    }

    // MARK: - Progression Methods

    func unlockNextDifficulty(after current: Difficulty) {
        let all = Difficulty.allCases
        guard let currentIndex = all.firstIndex(of: current),
              currentIndex + 1 < all.count else { return }

        let next = all[currentIndex + 1]
        unlockedDifficulties.insert(next)
        save()
    }

    func isDifficultyUnlocked(_ difficulty: Difficulty) -> Bool {
        unlockedDifficulties.contains(difficulty)
    }

    // MARK: - Statistics Methods

    func stats(for difficulty: Difficulty) -> DifficultyStats {
        difficultyStats[difficulty] ?? DifficultyStats()
    }

    func recordGameResult(difficulty: Difficulty, stars: Int) {
        var stats = difficultyStats[difficulty] ?? DifficultyStats()

        stats.gamesPlayed += 1
        stats.totalStars += stars

        if stars > 0 {
            stats.gamesWon += 1
            stats.currentStreak += 1
            stats.bestStreak = max(stats.bestStreak, stats.currentStreak)

            // Check if we should unlock the next difficulty
            // Unlock when player earns 3+ total stars on this difficulty
            if stats.totalStars >= 3 {
                unlockNextDifficulty(after: difficulty)
            }
        } else {
            stats.currentStreak = 0
        }

        difficultyStats[difficulty] = stats
        save()
    }

    // MARK: - Grid Rush Statistics Methods

    func recordGridRushResult(gridsCompleted: Int, score: Int, perfectClears: Int) {
        gridRushStats.totalRuns += 1
        gridRushStats.totalGridsCleared += gridsCompleted
        gridRushStats.totalPerfectClears += perfectClears

        // Update bests
        if gridsCompleted > gridRushStats.bestGridsCleared {
            gridRushStats.bestGridsCleared = gridsCompleted
        }

        if score > gridRushStats.highScore {
            gridRushStats.highScore = score
        }

        save()
    }

    func updateBestPerfectStreak(_ streak: Int) {
        if streak > gridRushStats.bestPerfectStreak {
            gridRushStats.bestPerfectStreak = streak
            save()
        }
    }

    // MARK: - Reset

    func resetProgress() {
        unlockedDifficulties = [.easy]
        difficultyStats = [:]
        gridRushStats = GridRushStats()
        save()
    }

    func resetAllSettings() {
        soundEnabled = true
        hapticsEnabled = true
        resetProgress()
    }
}
