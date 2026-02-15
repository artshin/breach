@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.generateOverlappingSequences")
struct GenerateOverlappingSequencesTests {
    private let codes = ["1C", "BD", "55", "E9", "7A", "FF"]

    @Test("Single sequence: merged equals sequence")
    func singleSequence() {
        let config = OverlapConfig(
            overlapCount: 0, overlapDepth: 0,
            codePool: codes, sequenceLengths: [4]
        )
        let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
        #expect(chain.sequences.count == 1)
        #expect(chain.sequences[0] == chain.mergedPath)
        #expect(chain.mergedPath.count == 4)
    }

    @Test("Two sequences with overlap share suffix/prefix")
    func twoWithOverlap() {
        let config = OverlapConfig(
            overlapCount: 1, overlapDepth: 1,
            codePool: codes, sequenceLengths: [3, 3]
        )
        for _ in 0..<10 {
            let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
            #expect(chain.sequences.count == 2)
            #expect(chain.sequences[0].count == 3)
            #expect(chain.sequences[1].count == 3)
            // Overlap: last code of seq0 == first code of seq1
            #expect(chain.sequences[0].last == chain.sequences[1].first)
            // Merged = seq0 + seq1.dropFirst(1)
            #expect(chain.mergedPath.count == 5)
        }
    }

    @Test("Two sequences without overlap are independent")
    func twoWithoutOverlap() {
        let config = OverlapConfig(
            overlapCount: 0, overlapDepth: 1,
            codePool: codes, sequenceLengths: [3, 3]
        )
        let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
        #expect(chain.sequences.count == 2)
        // Merged = concatenation
        #expect(chain.mergedPath.count == 6)
    }

    @Test("Three sequences with overlap depth 2")
    func threeWithOverlap() {
        let config = OverlapConfig(
            overlapCount: 2, overlapDepth: 2,
            codePool: codes, sequenceLengths: [3, 3, 3]
        )
        for _ in 0..<10 {
            let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
            #expect(chain.sequences.count == 3)
            for seq in chain.sequences {
                #expect(seq.count == 3)
            }
            // With 2 junctions overlapping at depth 2: merged = 9 - 2*2 = 5
            #expect(chain.mergedPath.count == 5)
        }
    }

    @Test("Empty lengths returns empty")
    func emptyLengths() {
        let config = OverlapConfig(
            overlapCount: 0, overlapDepth: 0,
            codePool: codes, sequenceLengths: []
        )
        let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
        #expect(chain.sequences.isEmpty)
        #expect(chain.mergedPath.isEmpty)
    }

    @Test("All codes come from provided pool")
    func codesFromPool() {
        let pool = ["1C", "BD"]
        let config = OverlapConfig(
            overlapCount: 1, overlapDepth: 1,
            codePool: pool, sequenceLengths: [3, 3]
        )
        let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
        let poolSet = Set(pool)
        for code in chain.mergedPath {
            #expect(poolSet.contains(code))
        }
        for seq in chain.sequences {
            for code in seq {
                #expect(poolSet.contains(code))
            }
        }
    }

    @Test("Merged path completes all sequences")
    func mergedPathCompletesSequences() {
        let config = OverlapConfig(
            overlapCount: 1, overlapDepth: 1,
            codePool: codes, sequenceLengths: [3, 3, 3]
        )
        for _ in 0..<20 {
            let chain = PuzzleGeneratorCore.generateOverlappingSequences(config: config)
            #expect(
                PuzzleGeneratorCore.verifyPathCompletes(
                    path: chain.mergedPath, sequences: chain.sequences
                )
            )
        }
    }
}
