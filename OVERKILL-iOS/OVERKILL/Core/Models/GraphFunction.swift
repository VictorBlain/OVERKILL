import SwiftUI

struct GraphFunction: Identifiable {
    let id: UUID
    var expression: String
    var color: Color
    var isVisible: Bool

    init(expression: String, color: Color, isVisible: Bool = true) {
        self.id         = UUID()
        self.expression = expression
        self.color      = color
        self.isVisible  = isVisible
    }
}
