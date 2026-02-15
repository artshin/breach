@testable import Gridcrack
import Testing

@Suite("PuzzleGeneratorCore.bufferContainsSequence")
struct BufferContainsSequenceTests {
    @Test("Exact match returns true")
    func exactMatch() {
        let buffer = ["1C", "BD", "55"]
        let sequence = ["1C", "BD", "55"]
        #expect(PuzzleGeneratorCore.bufferContainsSequence(buffer: buffer, sequence: sequence))
    }

    @Test("Subsequence match returns true")
    func subsequenceMatch() {
        let buffer = ["FF", "1C", "7A", "BD", "55"]
        let sequence = ["1C", "BD"]
        #expect(PuzzleGeneratorCore.bufferContainsSequence(buffer: buffer, sequence: sequence))
    }

    @Test("Missing code returns false")
    func missingCode() {
        let buffer = ["1C", "BD", "55"]
        let sequence = ["1C", "E9"]
        #expect(!PuzzleGeneratorCore.bufferContainsSequence(buffer: buffer, sequence: sequence))
    }

    @Test("Empty buffer returns false")
    func emptyBuffer() {
        let buffer: [String] = []
        let sequence = ["1C"]
        #expect(!PuzzleGeneratorCore.bufferContainsSequence(buffer: buffer, sequence: sequence))
    }

    @Test("Partial match (wrong order) returns false")
    func partialMatchWrongOrder() {
        let buffer = ["BD", "1C", "55"]
        let sequence = ["1C", "BD"]
        #expect(!PuzzleGeneratorCore.bufferContainsSequence(buffer: buffer, sequence: sequence))
    }

    @Test("Single code match")
    func singleCodeMatch() {
        let buffer = ["FF", "1C", "BD"]
        let sequence = ["1C"]
        #expect(PuzzleGeneratorCore.bufferContainsSequence(buffer: buffer, sequence: sequence))
    }

    @Test("Repeated codes - first occurrence consumed")
    func repeatedCodes() {
        let buffer = ["1C", "BD", "1C"]
        let sequence = ["1C", "1C"]
        #expect(PuzzleGeneratorCore.bufferContainsSequence(buffer: buffer, sequence: sequence))
    }
}
