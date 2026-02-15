@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.verifyPathCompletes")
struct VerifyPathCompletesTests {
    @Test("Single sequence completed")
    func singleSequence() {
        let path = ["1C", "BD", "55"]
        let sequences = [["1C", "BD", "55"]]
        #expect(PuzzleGeneratorCore.verifyPathCompletes(path: path, sequences: sequences))
    }

    @Test("Multiple interleaved sequences")
    func multipleInterleaved() {
        // Sequence A: 1C, BD  Sequence B: 1C, 55
        // Path: 1C advances both, BD advances A, 55 advances B
        let path = ["1C", "BD", "55"]
        let sequences = [["1C", "BD"], ["1C", "55"]]
        #expect(PuzzleGeneratorCore.verifyPathCompletes(path: path, sequences: sequences))
    }

    @Test("Missing one sequence returns false")
    func missingOneSequence() {
        let path = ["1C", "BD"]
        let sequences = [["1C", "BD"], ["E9", "55"]]
        #expect(!PuzzleGeneratorCore.verifyPathCompletes(path: path, sequences: sequences))
    }

    @Test("Shared codes advancing multiple sequences")
    func sharedCodesAdvanceMultiple() {
        // Both sequences start with "1C" — one path code advances both
        let path = ["1C", "FF", "E9"]
        let sequences = [["1C", "FF"], ["1C", "E9"]]
        #expect(PuzzleGeneratorCore.verifyPathCompletes(path: path, sequences: sequences))
    }

    @Test("Empty sequences trivially complete")
    func emptySequences() {
        let path = ["1C"]
        let sequences: [[String]] = []
        #expect(PuzzleGeneratorCore.verifyPathCompletes(path: path, sequences: sequences))
    }

    @Test("Path too short returns false")
    func pathTooShort() {
        let path = ["1C"]
        let sequences = [["1C", "BD", "55"]]
        #expect(!PuzzleGeneratorCore.verifyPathCompletes(path: path, sequences: sequences))
    }
}
