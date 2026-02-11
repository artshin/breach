import Foundation

/// Shared interface for game view models (Standard and Grid Rush)
@MainActor
protocol GamePlayable: ObservableObject {
    var grid: [[Cell]] { get }
    var buffer: [String] { get }
    var bufferSize: Int { get }
    var sequences: [TargetSequence] { get }
    var selectionMode: SelectionMode { get }

    func isValidSelection(cell: Cell) -> Bool
    func selectCell(_ cell: Cell)
    func getHighlightedRow() -> Int?
    func getHighlightedColumn() -> Int?
    func advancingPositions() -> Set<Position>
}
