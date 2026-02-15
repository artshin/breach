@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.randomLengths")
struct RandomLengthsTests {
    @Test("Sum equals mergedLength + overlap*(count-1) when feasible")
    func sumCorrect() {
        // Use inputs where total fits within count * maxLength (4)
        // count=2, overlap=1: total = merged + 1, need total <= 8 → merged <= 7
        //                     need total >= 6 → merged >= 5
        for _ in 0..<20 {
            let count = 2
            let merged = Int.random(in: 5...7)
            let overlap = 1

            let lengths = PuzzleGeneratorCore.randomLengths(
                mergedLength: merged, count: count, overlapSize: overlap
            )
            let expectedTotal = merged + overlap * (count - 1)
            #expect(lengths.reduce(0, +) == expectedTotal)
        }
    }

    @Test("Sum with 3 sequences")
    func sumThreeSequences() {
        // count=3, overlap=1: total = merged + 2, need total <= 12 and >= 9
        for _ in 0..<20 {
            let merged = Int.random(in: 7...10)
            let lengths = PuzzleGeneratorCore.randomLengths(
                mergedLength: merged, count: 3, overlapSize: 1
            )
            let expectedTotal = merged + 2
            #expect(lengths.reduce(0, +) == expectedTotal)
        }
    }

    @Test("All lengths >= 3 and <= maxLength")
    func lengthBounds() {
        for _ in 0..<20 {
            let lengths = PuzzleGeneratorCore.randomLengths(
                mergedLength: 6, count: 2, overlapSize: 1, maxLength: 4
            )
            for length in lengths {
                #expect(length >= 3)
                #expect(length <= 4)
            }
        }
    }

    @Test("Count matches requested count")
    func countMatches() {
        for count in 1...4 {
            let lengths = PuzzleGeneratorCore.randomLengths(
                mergedLength: 6, count: count, overlapSize: 1, maxLength: 6
            )
            #expect(lengths.count == count)
        }
    }

    @Test("Single sequence length equals total")
    func singleSequence() {
        // count=1: total = merged + 0 = 4. maxLength default is 4, so fits.
        let lengths = PuzzleGeneratorCore.randomLengths(
            mergedLength: 4, count: 1, overlapSize: 1
        )
        #expect(lengths.count == 1)
        #expect(lengths[0] == 4)
    }

    @Test("Capped at maxLength when total exceeds capacity")
    func cappedAtMaxLength() {
        // count=2, maxLength=4: max total = 8. merged=10 → total=11, capped at 8
        let lengths = PuzzleGeneratorCore.randomLengths(
            mergedLength: 10, count: 2, overlapSize: 1, maxLength: 4
        )
        #expect(lengths.count == 2)
        #expect(lengths.reduce(0, +) == 8) // 2 * 4
        for length in lengths {
            #expect(length == 4)
        }
    }
}
