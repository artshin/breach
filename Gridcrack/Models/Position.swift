import Foundation

struct Position: Hashable, Equatable {
    let row: Int
    let col: Int

    func isInRow(_ targetRow: Int) -> Bool {
        row == targetRow
    }

    func isInColumn(_ targetCol: Int) -> Bool {
        col == targetCol
    }
}
