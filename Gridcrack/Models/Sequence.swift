import Foundation

struct TargetSequence: Identifiable, Equatable {
    let id: UUID
    let codes: [String]
    var matchedCount: Int
    var isImpossible: Bool

    init(codes: [String], matchedCount: Int = 0, isImpossible: Bool = false) {
        id = UUID()
        self.codes = codes
        self.matchedCount = matchedCount
        self.isImpossible = isImpossible
    }

    var isComplete: Bool {
        matchedCount >= codes.count
    }

    var nextNeededCode: String? {
        guard !isComplete else { return nil }
        return codes[matchedCount]
    }

    var progress: Double {
        guard !codes.isEmpty else { return 0 }
        return Double(matchedCount) / Double(codes.count)
    }

    var displayString: String {
        codes.joined(separator: " → ")
    }
}
