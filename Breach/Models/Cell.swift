import Foundation

struct Cell: Identifiable, Equatable {
    let id: UUID
    let code: String
    let row: Int
    let col: Int
    var isSelected: Bool

    init(code: String, row: Int, col: Int, isSelected: Bool = false) {
        self.id = UUID()
        self.code = code
        self.row = row
        self.col = col
        self.isSelected = isSelected
    }

    var position: Position {
        Position(row: row, col: col)
    }

    static let availableCodes = ["1C", "BD", "55", "E9", "7A", "FF"]

    static func randomCode() -> String {
        availableCodes.randomElement() ?? "1C"
    }
}
